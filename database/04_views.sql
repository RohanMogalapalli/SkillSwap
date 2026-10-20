-- ============================================================================
-- SkillSwap - Campus Skill Exchange Platform
-- Analytical and Reporting Views Script (04_views.sql)
-- DBMS Project by Mogalapalli Rohan (24BCE2622) & N. Sai Hemanth (24BCE2400)
-- Target: Oracle Database 21c XE
-- ============================================================================

-- ----------------------------------------------------------------------------
-- View 1: v_top_mentors
-- Ranks mentors based on completed sessions, average star rating, and review count.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_top_mentors AS
SELECT 
    u.user_id,
    u.name AS mentor_name,
    u.department,
    u.year,
    COUNT(DISTINCT s.session_id) AS total_sessions_conducted,
    NVL(ROUND(AVG(r.rating), 2), 0) AS average_rating,
    COUNT(r.rating_id) AS total_reviews,
    NVL(SUM(s.duration), 0) AS total_hours_taught
FROM Users u
LEFT JOIN Sessions s ON u.user_id = s.mentor_id AND s.status = 'COMPLETED'
LEFT JOIN Ratings r ON s.session_id = r.session_id
WHERE u.role = 'STUDENT' AND u.status = 'ACTIVE'
GROUP BY u.user_id, u.name, u.department, u.year
HAVING COUNT(DISTINCT s.session_id) > 0 OR COUNT(r.rating_id) > 0
ORDER BY average_rating DESC, total_sessions_conducted DESC;

-- ----------------------------------------------------------------------------
-- View 2: v_available_mentors
-- Lists active mentors with the skills they teach, proficiency, and experience.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_available_mentors AS
SELECT 
    u.user_id AS mentor_id,
    u.name AS mentor_name,
    u.email AS mentor_email,
    u.department,
    u.year,
    k.skill_id,
    k.skill_name,
    c.category_name,
    us.proficiency_level,
    us.experience_years,
    us.available_hours,
    NVL(get_average_rating(u.user_id), 0) AS average_rating,
    us.status AS offering_status
FROM Users u
JOIN User_Skills us ON u.user_id = us.user_id
JOIN Skills k ON us.skill_id = k.skill_id
JOIN Skill_Categories c ON k.category_id = c.category_id
WHERE u.status = 'ACTIVE' AND us.status = 'AVAILABLE';

-- ----------------------------------------------------------------------------
-- View 3: v_student_dashboard
-- Aggregates personalized peer-to-peer stats for each student.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_student_dashboard AS
SELECT 
    u.user_id,
    u.name,
    u.email,
    u.department,
    u.year,
    ca.balance AS credit_balance,
    ca.total_earned,
    ca.total_spent,
    (SELECT COUNT(*) FROM User_Skills WHERE user_id = u.user_id AND status = 'AVAILABLE') AS skills_offered_count,
    (SELECT COUNT(*) FROM Skill_Requests WHERE user_id = u.user_id AND status IN ('PENDING', 'MATCHED')) AS active_requests_count,
    (SELECT NVL(SUM(duration), 0) FROM Sessions WHERE learner_id = u.user_id AND status = 'COMPLETED') AS hours_learned,
    (SELECT NVL(SUM(duration), 0) FROM Sessions WHERE mentor_id = u.user_id AND status = 'COMPLETED') AS hours_taught,
    (SELECT COUNT(*) FROM Sessions WHERE (learner_id = u.user_id OR mentor_id = u.user_id) AND status = 'COMPLETED') AS total_completed_sessions,
    (SELECT COUNT(*) FROM Certificates WHERE user_id = u.user_id) AS certificates_earned,
    NVL(get_average_rating(u.user_id), 0) AS mentor_rating
FROM Users u
LEFT JOIN Credit_Accounts ca ON u.user_id = ca.user_id
WHERE u.role = 'STUDENT';

-- ----------------------------------------------------------------------------
-- View 4: v_skill_demand_analytics
-- Real-time analytics comparing student demand vs mentor supply per skill.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_skill_demand_analytics AS
SELECT 
    k.skill_id,
    k.skill_name,
    c.category_name,
    COUNT(DISTINCT sr.request_id) AS total_requests,
    COUNT(DISTINCT us.user_id) AS available_mentors_count,
    COUNT(DISTINCT s.session_id) AS sessions_completed,
    CASE 
        WHEN COUNT(DISTINCT us.user_id) = 0 THEN 'Critical Shortage'
        WHEN COUNT(DISTINCT sr.request_id) > COUNT(DISTINCT us.user_id) * 2 THEN 'High Demand'
        ELSE 'Balanced'
    END AS market_status
FROM Skills k
JOIN Skill_Categories c ON k.category_id = c.category_id
LEFT JOIN Skill_Requests sr ON k.skill_id = sr.skill_id AND sr.status IN ('PENDING', 'MATCHED')
LEFT JOIN User_Skills us ON k.skill_id = us.skill_id AND us.status = 'AVAILABLE'
LEFT JOIN Sessions s ON k.skill_id = s.skill_id AND s.status = 'COMPLETED'
GROUP BY k.skill_id, k.skill_name, c.category_name
ORDER BY total_requests DESC, sessions_completed DESC;

-- ----------------------------------------------------------------------------
-- View 5: v_recent_transactions
-- Audit view of recent credit transfers with linked user names and session info.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_recent_transactions AS
SELECT 
    t.transaction_id,
    u.user_id,
    u.name AS student_name,
    t.transaction_type,
    t.amount,
    t.transaction_date,
    t.description,
    s.session_id,
    k.skill_name
FROM Credit_Transactions t
JOIN Credit_Accounts ca ON t.account_id = ca.account_id
JOIN Users u ON ca.user_id = u.user_id
LEFT JOIN Sessions s ON t.session_id = s.session_id
LEFT JOIN Skills k ON s.skill_id = k.skill_id
ORDER BY t.transaction_date DESC;

COMMIT;
