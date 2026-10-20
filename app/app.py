from flask import Flask, render_template, request, redirect, url_for, session, flash, jsonify
from datetime import datetime, date
from app import db
import os

app = Flask(__name__)
app.secret_key = os.getenv("SECRET_KEY", "skillswap-vit-dbs-2026-key")

@app.context_processor
def inject_user_context():
    """Injects current user and unread notification count into all templates."""
    user = None
    unread_notifs = 0
    if "user_id" in session:
        user = db.query_one("SELECT * FROM Users WHERE user_id = :p_user_id", {"p_user_id": session["user_id"]})
        notif_row = db.query_one(
            "SELECT COUNT(*) AS cnt FROM Notifications WHERE user_id = :p_user_id AND is_read = 0", 
            {"p_user_id": session["user_id"]}
        )
        if notif_row:
            unread_notifs = notif_row["cnt"]
    return dict(current_user=user, unread_notifications_count=unread_notifs)

# ----------------------------------------------------------------------------
# Authentication Routes
# ----------------------------------------------------------------------------
@app.route("/")
def index():
    if "user_id" in session:
        return redirect(url_for("dashboard"))
    
    # Showcase stats on landing page
    stats = {
        "users": db.query_one("SELECT COUNT(*) AS cnt FROM Users")["cnt"],
        "skills": db.query_one("SELECT COUNT(*) AS cnt FROM Skills")["cnt"],
        "sessions": db.query_one("SELECT COUNT(*) AS cnt FROM Sessions WHERE status = 'COMPLETED'")["cnt"],
        "credits": db.query_one("SELECT NVL(SUM(balance), 0) AS cnt FROM Credit_Accounts")["cnt"]
    }
    top_mentors = db.query_all("SELECT * FROM v_top_mentors WHERE ROWNUM <= 4")
    return render_template("index.html", stats=stats, top_mentors=top_mentors)

@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        email = request.form.get("email", "").strip()
        password = request.form.get("password", "").strip()
        
        user = db.query_one("SELECT * FROM Users WHERE LOWER(email) = LOWER(:email)", {"email": email})
        if user and user["password"] == password:
            session["user_id"] = user["user_id"]
            session["user_name"] = user["name"]
            session["role"] = user["role"]
            flash(f"Welcome back, {user['name']}!", "success")
            return redirect(url_for("dashboard"))
        else:
            flash("Invalid email or password. Please try again.", "danger")
            
    # Provide quick demo switchers for easy evaluation
    demo_users = db.query_all("SELECT user_id, name, email, department, role FROM Users ORDER BY user_id")
    return render_template("login.html", demo_users=demo_users)

@app.route("/quick-login/<int:user_id>")
def quick_login(user_id):
    """Convenient 1-click persona switcher for project evaluation."""
    user = db.query_one("SELECT * FROM Users WHERE user_id = :p_user_id", {"p_user_id": user_id})
    if user:
        session["user_id"] = user["user_id"]
        session["user_name"] = user["name"]
        session["role"] = user["role"]
        flash(f"Switched persona to {user['name']} ({user['department']}, {user['role']})", "info")
    return redirect(url_for("dashboard"))

@app.route("/register", methods=["GET", "POST"])
def register():
    if request.method == "POST":
        name = request.form.get("name", "").strip()
        email = request.form.get("email", "").strip()
        password = request.form.get("password", "").strip()
        department = request.form.get("department", "CSE")
        year = int(request.form.get("year", 2))
        phone = request.form.get("phone", "").strip()
        
        email_clean = email.lower()
        if not (email_clean.endswith("@vitstudent.ac.in") or email_clean.endswith("@vit.ac.in")):
            flash("Registration restricted: Only official college emails (@vitstudent.ac.in or @vit.ac.in) are permitted.", "danger")
            return render_template("register.html")
            
        try:
            db.execute_dml("""
                INSERT INTO Users (name, email, password, department, year, phone, role, status)
                VALUES (:name, :email, :password, :dept, :year, :phone, 'STUDENT', 'ACTIVE')
            """, {
                "name": name, "email": email, "password": password, 
                "dept": department, "year": year, "phone": phone
            })
            
            # Fetch created user to set session
            user = db.query_one("SELECT * FROM Users WHERE email = :email", {"email": email})
            session["user_id"] = user["user_id"]
            session["user_name"] = user["name"]
            session["role"] = user["role"]
            
            flash(f"Welcome {name}! Your account is active with 50 welcome Skill Credits.", "success")
            return redirect(url_for("dashboard"))
        except Exception as e:
            flash(f"Registration failed: {str(e)}", "danger")
            
    return render_template("register.html")

@app.route("/logout")
def logout():
    session.clear()
    flash("You have logged out.", "info")
    return redirect(url_for("login"))

# ----------------------------------------------------------------------------
# Dashboard & Profile
# ----------------------------------------------------------------------------
@app.route("/dashboard")
def dashboard():
    if "user_id" not in session:
        return redirect(url_for("login"))
    
    uid = session["user_id"]
    dash_stats = db.query_one("SELECT * FROM v_student_dashboard WHERE user_id = :p_user_id", {"p_user_id": uid})
    
    # Upcoming sessions (learner or mentor)
    upcoming_sessions = db.query_all("""
        SELECT s.*, k.skill_name, 
               u_m.name AS mentor_name, u_l.name AS learner_name
        FROM Sessions s
        JOIN Skills k ON s.skill_id = k.skill_id
        JOIN Users u_m ON s.mentor_id = u_m.user_id
        JOIN Users u_l ON s.learner_id = u_l.user_id
        WHERE (s.mentor_id = :p_user_id OR s.learner_id = :p_user_id)
          AND s.status IN ('REQUESTED', 'ACCEPTED', 'SCHEDULED')
        ORDER BY s.scheduled_date ASC
    """, {"p_user_id": uid})
    
    # Skills currently offered by this student
    my_offered_skills = db.query_all("""
        SELECT us.*, k.skill_name, c.category_name
        FROM User_Skills us
        JOIN Skills k ON us.skill_id = k.skill_id
        JOIN Skill_Categories c ON k.category_id = c.category_id
        WHERE us.user_id = :p_user_id
    """, {"p_user_id": uid})
    
    # Skills requested by this student
    my_requests = db.query_all("""
        SELECT sr.*, k.skill_name, c.category_name,
               (SELECT COUNT(*) FROM Matches WHERE request_id = sr.request_id) AS match_count
        FROM Skill_Requests sr
        JOIN Skills k ON sr.skill_id = k.skill_id
        JOIN Skill_Categories c ON k.category_id = c.category_id
        WHERE sr.user_id = :p_user_id
        ORDER BY sr.request_date DESC
    """, {"p_user_id": uid})
    
    # Recent notifications
    notifications = db.query_all("""
        SELECT * FROM Notifications 
        WHERE user_id = :p_user_id 
        ORDER BY created_at DESC FETCH FIRST 5 ROWS ONLY
    """, {"p_user_id": uid})
    
    return render_template("dashboard.html", 
                           stats=dash_stats, 
                           upcoming_sessions=upcoming_sessions,
                           offered_skills=my_offered_skills,
                           my_requests=my_requests,
                           notifications=notifications)

# ----------------------------------------------------------------------------
# Skills & Mentors Catalog
# ----------------------------------------------------------------------------
@app.route("/skills")
def skills_catalog():
    category_id = request.args.get("category_id")
    search = request.args.get("q", "").strip()
    
    categories = db.query_all("SELECT * FROM Skill_Categories ORDER BY category_name")
    
    query = """
        SELECT k.*, c.category_name,
               (SELECT COUNT(*) FROM User_Skills WHERE skill_id = k.skill_id AND status = 'AVAILABLE') AS mentor_count
        FROM Skills k
        JOIN Skill_Categories c ON k.category_id = c.category_id
        WHERE 1=1
    """
    params = {}
    if category_id:
        query += " AND k.category_id = :cid"
        params["cid"] = int(category_id)
    if search:
        query += " AND LOWER(k.skill_name) LIKE LOWER(:search)"
        params["search"] = f"%{search}%"
        
    query += " ORDER BY c.category_name, k.skill_name"
    skills = db.query_all(query, params)
    
    # Available Mentors from view
    available_mentors = db.query_all("SELECT * FROM v_available_mentors ORDER BY average_rating DESC")
    
    return render_template("skills.html", skills=skills, categories=categories, available_mentors=available_mentors)

@app.route("/offer-skill", methods=["GET", "POST"])
def offer_skill():
    if "user_id" not in session:
        return redirect(url_for("login"))
    
    uid = session["user_id"]
    if request.method == "POST":
        skill_id = int(request.form.get("skill_id"))
        prof_level = request.form.get("proficiency_level")
        experience = float(request.form.get("experience_years", 1.0))
        avail_hours = float(request.form.get("available_hours", 5.0))
        
        try:
            db.execute_dml("""
                MERGE INTO User_Skills tgt
                USING (SELECT :p_user_id AS u_id, :sid AS s_id FROM dual) src
                ON (tgt.user_id = src.u_id AND tgt.skill_id = src.s_id)
                WHEN MATCHED THEN
                    UPDATE SET proficiency_level = :prof, experience_years = :exp, 
                               available_hours = :hrs, status = 'AVAILABLE'
                WHEN NOT MATCHED THEN
                    INSERT (user_id, skill_id, proficiency_level, experience_years, available_hours, status)
                    VALUES (:p_user_id, :sid, :prof, :exp, :hrs, 'AVAILABLE')
            """, {
                "p_user_id": uid, "sid": skill_id, "prof": prof_level, 
                "exp": experience, "hrs": avail_hours
            })
            flash("Your skill offering has been published! Students can now match with you.", "success")
            return redirect(url_for("dashboard"))
        except Exception as e:
            flash(f"Error offering skill: {str(e)}", "danger")
            
    skills = db.query_all("SELECT * FROM Skills ORDER BY skill_name")
    return render_template("offer_skill.html", skills=skills)

@app.route("/request-skill", methods=["GET", "POST"])
def request_skill():
    if "user_id" not in session:
        return redirect(url_for("login"))
    
    uid = session["user_id"]
    if request.method == "POST":
        skill_id = int(request.form.get("skill_id"))
        desired_level = request.form.get("desired_level", "BEGINNER")
        priority = request.form.get("priority", "MEDIUM")
        
        try:
            conn = db.get_connection()
            with conn.cursor() as cur:
                req_id_var = cur.var(db.oracledb.NUMBER)
                cur.execute("""
                    INSERT INTO Skill_Requests (user_id, skill_id, desired_level, priority, status)
                    VALUES (:p_user_id, :sid, :lvl, :pri, 'PENDING')
                    RETURNING request_id INTO :req_id
                """, {"p_user_id": uid, "sid": skill_id, "lvl": desired_level, "pri": priority, "req_id": req_id_var})
                new_req_id = int(req_id_var.getvalue()[0])
                conn.commit()
            
            # Immediately run PL/SQL matching procedure for this request!
            ok, count = db.call_match_mentors(new_req_id)
            if ok and count > 0:
                flash(f"Skill requested successfully! Found {count} matching mentors based on proficiency and rating.", "success")
                return redirect(url_for("view_matches", request_id=new_req_id))
            else:
                flash("Skill requested successfully! We will notify you when a mentor becomes available.", "info")
                return redirect(url_for("dashboard"))
        except Exception as e:
            flash(f"Error requesting skill: {str(e)}", "danger")
            
    skills = db.query_all("SELECT * FROM Skills ORDER BY skill_name")
    return render_template("request_skill.html", skills=skills)

# ----------------------------------------------------------------------------
# Matches & Booking
# ----------------------------------------------------------------------------
@app.route("/matches/<int:request_id>")
def view_matches(request_id):
    if "user_id" not in session:
        return redirect(url_for("login"))
    
    req_info = db.query_one("""
        SELECT sr.*, k.skill_name, u.name AS learner_name
        FROM Skill_Requests sr
        JOIN Skills k ON sr.skill_id = k.skill_id
        JOIN Users u ON sr.user_id = u.user_id
        WHERE sr.request_id = :rid
    """, {"rid": request_id})
    
    matches = db.query_all("""
        SELECT m.*, u.name AS mentor_name, u.department, u.year, u.email,
               us.proficiency_level, us.experience_years,
               NVL(get_average_rating(u.user_id), 0) AS mentor_rating
        FROM Matches m
        JOIN Users u ON m.mentor_id = u.user_id
        JOIN Skill_Requests sr ON m.request_id = sr.request_id
        LEFT JOIN User_Skills us ON u.user_id = us.user_id AND us.skill_id = sr.skill_id
        WHERE m.request_id = :rid
        ORDER BY m.match_score DESC
    """, {"rid": request_id})
    
    return render_template("matches.html", req=req_info, matches=matches)

@app.route("/book-session/<int:match_id>", methods=["GET", "POST"])
def book_session_route(match_id):
    if "user_id" not in session:
        return redirect(url_for("login"))
    
    uid = session["user_id"]
    match = db.query_one("""
        SELECT m.*, sr.skill_id, sr.user_id AS learner_id, k.skill_name,
               u_ment.name AS mentor_name, u_learn.name AS learner_name
        FROM Matches m
        JOIN Skill_Requests sr ON m.request_id = sr.request_id
        JOIN Skills k ON sr.skill_id = k.skill_id
        JOIN Users u_ment ON m.mentor_id = u_ment.user_id
        JOIN Users u_learn ON sr.user_id = u_learn.user_id
        WHERE m.match_id = :mid
    """, {"mid": match_id})
    
    if not match:
        flash("Match record not found.", "danger")
        return redirect(url_for("dashboard"))
    
    learner_bal = db.query_one("SELECT balance FROM Credit_Accounts WHERE user_id = :p_user_id", {"p_user_id": uid})["balance"]
    
    # Mentor availability slots
    slots = db.query_all("SELECT * FROM Availability WHERE user_id = :mid AND status = 'ACTIVE'", {"mid": match["mentor_id"]})
    
    if request.method == "POST":
        sched_date = request.form.get("scheduled_date")
        start_time = request.form.get("start_time")
        end_time = request.form.get("end_time")
        duration = float(request.form.get("duration", 1.0))
        cost = duration * 10.0 # 10 credits per hour
        
        if learner_bal < cost:
            flash(f"Insufficient Skill Credits! You have {learner_bal} credits, but this session costs {cost} credits.", "danger")
            return redirect(url_for("credits"))
            
        try:
            conn = db.get_connection()
            with conn.cursor() as cur:
                sess_id_var = cur.var(db.oracledb.NUMBER)
                cur.callproc("book_session", [
                    match_id, match["mentor_id"], uid, match["skill_id"],
                    datetime.strptime(sched_date, "%Y-%m-%d").date(),
                    start_time, end_time, duration, cost, sess_id_var
                ])
                new_session_id = int(sess_id_var.getvalue() or 0)
                conn.commit()
                
            flash(f"Session #{new_session_id} successfully booked! Mentor notified.", "success")
            return redirect(url_for("sessions_list"))
        except Exception as e:
            flash(f"Booking failed: {str(e)}", "danger")
            
    return render_template("book_session.html", match=match, slots=slots, balance=learner_bal)

# ----------------------------------------------------------------------------
# Sessions Lifecycle & Credit Transfer
# ----------------------------------------------------------------------------
@app.route("/sessions")
def sessions_list():
    if "user_id" not in session:
        return redirect(url_for("login"))
    
    uid = session["user_id"]
    as_learner = db.query_all("""
        SELECT s.*, k.skill_name, u.name AS mentor_name, u.email AS mentor_email,
               (SELECT rating FROM Ratings WHERE session_id = s.session_id) AS user_rating
        FROM Sessions s
        JOIN Skills k ON s.skill_id = k.skill_id
        JOIN Users u ON s.mentor_id = u.user_id
        WHERE s.learner_id = :p_user_id
        ORDER BY s.scheduled_date DESC, s.session_id DESC
    """, {"p_user_id": uid})
    
    as_mentor = db.query_all("""
        SELECT s.*, k.skill_name, u.name AS learner_name, u.email AS learner_email,
               (SELECT rating FROM Ratings WHERE session_id = s.session_id) AS received_rating
        FROM Sessions s
        JOIN Skills k ON s.skill_id = k.skill_id
        JOIN Users u ON s.learner_id = u.user_id
        WHERE s.mentor_id = :p_user_id
        ORDER BY s.scheduled_date DESC, s.session_id DESC
    """, {"p_user_id": uid})
    
    return render_template("sessions.html", as_learner=as_learner, as_mentor=as_mentor)

@app.route("/sessions/<int:session_id>/accept", methods=["POST"])
def accept_session(session_id):
    if "user_id" not in session:
        return redirect(url_for("login"))
    
    uid = session["user_id"]
    sess_obj = db.query_one("SELECT * FROM Sessions WHERE session_id = :sid AND mentor_id = :p_user_id", {"sid": session_id, "p_user_id": uid})
    if sess_obj:
        db.execute_dml("UPDATE Sessions SET status = 'ACCEPTED' WHERE session_id = :sid", {"sid": session_id})
        db.execute_dml("""
            INSERT INTO Notifications (user_id, message, notification_type)
            VALUES (:lid, 'Your session request has been ACCEPTED by your mentor!', 'SESSION_ACCEPTED')
        """, {"lid": sess_obj["learner_id"]})
        flash("Session accepted successfully!", "success")
    return redirect(url_for("sessions_list"))

@app.route("/sessions/<int:session_id>/complete", methods=["POST"])
def complete_session_route(session_id):
    """Executes the atomic complete_session PL/SQL stored procedure."""
    if "user_id" not in session:
        return redirect(url_for("login"))
    
    success, msg = db.call_complete_session(session_id)
    if success:
        flash(f"Session #{session_id} successfully marked COMPLETED. Credits atomically transferred!", "success")
    else:
        flash(f"Failed to complete session: {msg}", "danger")
        
    return redirect(url_for("sessions_list"))

@app.route("/sessions/<int:session_id>/cancel", methods=["POST"])
def cancel_session(session_id):
    if "user_id" not in session:
        return redirect(url_for("login"))
    
    uid = session["user_id"]
    db.execute_dml("""
        UPDATE Sessions SET status = 'CANCELLED' 
        WHERE session_id = :sid AND (mentor_id = :p_user_id OR learner_id = :p_user_id)
    """, {"sid": session_id, "p_user_id": uid})
    flash("Session marked as CANCELLED.", "info")
    return redirect(url_for("sessions_list"))

# ----------------------------------------------------------------------------
# Ratings & Feedback
# ----------------------------------------------------------------------------
@app.route("/rate/<int:session_id>", methods=["GET", "POST"])
def rate_mentor(session_id):
    if "user_id" not in session:
        return redirect(url_for("login"))
    
    uid = session["user_id"]
    sess_obj = db.query_one("""
        SELECT s.*, k.skill_name, u.name AS mentor_name
        FROM Sessions s
        JOIN Skills k ON s.skill_id = k.skill_id
        JOIN Users u ON s.mentor_id = u.user_id
        WHERE s.session_id = :sid AND s.learner_id = :p_user_id AND s.status = 'COMPLETED'
    """, {"sid": session_id, "p_user_id": uid})
    
    if not sess_obj:
        flash("You can only rate completed sessions you attended as a learner.", "warning")
        return redirect(url_for("sessions_list"))
        
    if request.method == "POST":
        rating = float(request.form.get("rating", 5.0))
        feedback = request.form.get("feedback", "").strip()
        
        try:
            db.execute_dml("""
                INSERT INTO Ratings (session_id, mentor_id, learner_id, rating, feedback)
                VALUES (:sid, :mid, :lid, :rating, :fb)
            """, {
                "sid": session_id, "mid": sess_obj["mentor_id"], 
                "lid": uid, "rating": rating, "fb": feedback
            })
            flash("Rating submitted! Thank you for supporting peer learning.", "success")
            return redirect(url_for("sessions_list"))
        except Exception as e:
            flash(f"Error submitting rating: {str(e)}", "danger")
            
    return render_template("rate_mentor.html", session_info=sess_obj)

# ----------------------------------------------------------------------------
# Credits Wallet & Ledger
# ----------------------------------------------------------------------------
@app.route("/credits")
def credits():
    if "user_id" not in session:
        return redirect(url_for("login"))
    
    uid = session["user_id"]
    account = db.query_one("SELECT * FROM Credit_Accounts WHERE user_id = :p_user_id", {"p_user_id": uid})
    
    transactions = db.query_all("""
        SELECT t.*, s.skill_id, k.skill_name
        FROM Credit_Transactions t
        LEFT JOIN Sessions s ON t.session_id = s.session_id
        LEFT JOIN Skills k ON s.skill_id = k.skill_id
        WHERE t.account_id = :aid
        ORDER BY t.transaction_date DESC
    """, {"aid": account["account_id"]})
    
    return render_template("credits.html", account=account, transactions=transactions)

# ----------------------------------------------------------------------------
# Certificates
# ----------------------------------------------------------------------------
@app.route("/certificates")
def certificates():
    if "user_id" not in session:
        return redirect(url_for("login"))
    
    uid = session["user_id"]
    certs = db.query_all("""
        SELECT c.*, k.skill_name, u.name AS student_name, u.department
        FROM Certificates c
        JOIN Skills k ON c.skill_id = k.skill_id
        JOIN Users u ON c.user_id = u.user_id
        WHERE c.user_id = :p_user_id
        ORDER BY c.issue_date DESC
    """, {"p_user_id": uid})
    
    return render_template("certificates.html", certificates=certs)

@app.route("/verify-certificate", methods=["GET", "POST"])
def verify_certificate():
    cert = None
    code = request.args.get("code") or request.form.get("code")
    if code:
        cert = db.query_one("""
            SELECT c.*, k.skill_name, cat.category_name, u.name AS student_name, u.department, u.year
            FROM Certificates c
            JOIN Skills k ON c.skill_id = k.skill_id
            JOIN Skill_Categories cat ON k.category_id = cat.category_id
            JOIN Users u ON c.user_id = u.user_id
            WHERE UPPER(c.certificate_code) = UPPER(:code)
        """, {"code": code.strip()})
        if not cert:
            flash(f"No certificate found matching code: {code}", "warning")
            
    return render_template("verify_certificate.html", certificate=cert, search_code=code)

# ----------------------------------------------------------------------------
# Incident Reports & Complaints
# ----------------------------------------------------------------------------
@app.route("/reports", methods=["GET", "POST"])
def user_reports():
    if "user_id" not in session:
        return redirect(url_for("login"))
    
    uid = session["user_id"]
    if request.method == "POST":
        reported_user_id = int(request.form.get("reported_user_id"))
        session_id = request.form.get("session_id")
        reason = request.form.get("reason", "").strip()
        desc = request.form.get("description", "").strip()
        
        try:
            db.execute_dml("""
                INSERT INTO Reports (reported_by, reported_user, session_id, reason, description, status)
                VALUES (:by, :p_target_user, :sid, :reason, :desc, 'OPEN')
            """, {
                "by": uid, "p_target_user": reported_user_id, 
                "sid": int(session_id) if session_id else None,
                "reason": reason, "desc": desc
            })
            flash("Your report has been logged and sent to system administration.", "info")
            return redirect(url_for("user_reports"))
        except Exception as e:
            flash(f"Failed to submit report: {str(e)}", "danger")
            
    my_reports = db.query_all("""
        SELECT r.*, u.name AS reported_person_name
        FROM Reports r
        JOIN Users u ON r.reported_user = u.user_id
        WHERE r.reported_by = :p_user_id
        ORDER BY r.created_at DESC
    """, {"p_user_id": uid})
    
    other_users = db.query_all("SELECT user_id, name, department FROM Users WHERE user_id <> :p_user_id ORDER BY name", {"p_user_id": uid})
    return render_template("reports.html", reports=my_reports, users=other_users)

# ----------------------------------------------------------------------------
# Notifications
# ----------------------------------------------------------------------------
@app.route("/notifications")
def notifications_view():
    if "user_id" not in session:
        return redirect(url_for("login"))
    
    uid = session["user_id"]
    # Mark all read
    db.execute_dml("UPDATE Notifications SET is_read = 1 WHERE user_id = :p_user_id", {"p_user_id": uid})
    
    notifs = db.query_all("SELECT * FROM Notifications WHERE user_id = :p_user_id ORDER BY created_at DESC", {"p_user_id": uid})
    return render_template("notifications.html", notifications=notifs)

# ----------------------------------------------------------------------------
# Admin Management Portal
# ----------------------------------------------------------------------------
@app.route("/admin")
def admin_portal():
    if session.get("role") != "ADMIN":
        flash("Admin credentials required to view administration console.", "warning")
        return redirect(url_for("dashboard"))
        
    users = db.query_all("SELECT u.*, ca.balance FROM Users u LEFT JOIN Credit_Accounts ca ON u.user_id = ca.user_id ORDER BY u.user_id")
    reports = db.query_all("""
        SELECT r.*, u_by.name AS reporter_name, u_user.name AS reported_name
        FROM Reports r
        JOIN Users u_by ON r.reported_by = u_by.user_id
        JOIN Users u_user ON r.reported_user = u_user.user_id
        ORDER BY r.created_at DESC
    """)
    market = db.query_all("SELECT * FROM v_skill_demand_analytics")
    
    return render_template("admin.html", users=users, reports=reports, market=market)

@app.route("/admin/resolve-report/<int:report_id>", methods=["POST"])
def resolve_report(report_id):
    if session.get("role") != "ADMIN":
        return redirect(url_for("dashboard"))
    db.execute_dml("UPDATE Reports SET status = 'RESOLVED', resolved_at = CURRENT_TIMESTAMP WHERE report_id = :rid", {"rid": report_id})
    flash(f"Report #{report_id} has been marked RESOLVED.", "success")
    return redirect(url_for("admin_portal"))

# ----------------------------------------------------------------------------
# Dedicated DBMS Concept Showcase for Evaluators / Faculty
# ----------------------------------------------------------------------------
@app.route("/dbms-showcase")
def dbms_showcase():
    """Live interactive showcase of 3NF Normalization, Views, Procedures, and Triggers."""
    counts = db.query_all("""
        SELECT 'Users' AS tbl, COUNT(*) AS cnt FROM Users
        UNION ALL SELECT 'Skill_Categories', COUNT(*) FROM Skill_Categories
        UNION ALL SELECT 'Skills', COUNT(*) FROM Skills
        UNION ALL SELECT 'User_Skills', COUNT(*) FROM User_Skills
        UNION ALL SELECT 'Skill_Requests', COUNT(*) FROM Skill_Requests
        UNION ALL SELECT 'Availability', COUNT(*) FROM Availability
        UNION ALL SELECT 'Matches', COUNT(*) FROM Matches
        UNION ALL SELECT 'Credit_Accounts', COUNT(*) FROM Credit_Accounts
        UNION ALL SELECT 'Sessions', COUNT(*) FROM Sessions
        UNION ALL SELECT 'Credit_Transactions', COUNT(*) FROM Credit_Transactions
        UNION ALL SELECT 'Session_Attendance', COUNT(*) FROM Session_Attendance
        UNION ALL SELECT 'Ratings', COUNT(*) FROM Ratings
        UNION ALL SELECT 'Certificates', COUNT(*) FROM Certificates
        UNION ALL SELECT 'Notifications', COUNT(*) FROM Notifications
        UNION ALL SELECT 'Reports', COUNT(*) FROM Reports
    """)
    top_mentors = db.query_all("SELECT * FROM v_top_mentors")
    market = db.query_all("SELECT * FROM v_skill_demand_analytics")
    transactions = db.query_all("SELECT * FROM v_recent_transactions WHERE ROWNUM <= 8")
    
    return render_template("dbms_showcase.html", 
                           counts=counts, 
                           top_mentors=top_mentors, 
                           market=market, 
                           transactions=transactions)

if __name__ == "__main__":
    app.run(debug=True, host="127.0.0.1", port=5000)
