# SkillSwap — Campus Skill Exchange Platform

**Database Management Systems (DBS) Course Project**  
*Course:* CSE - Database Management Systems  
*Institution:* Vellore Institute of Technology (VIT)  

### 👥 Project Team
* **Mogalapalli Rohan** (Reg. No: `24BCE2622`)
* **N. Sai Hemanth** (Reg. No: `24BCE2400`)

---

## 📖 1. Project Overview

**SkillSwap** is a peer-to-peer campus knowledge exchange platform where college students teach skills they know and learn skills they need. Instead of direct monetary payments, SkillSwap implements an internal **Skill Credit System** ("*Learn a skill by teaching a skill*").

- A student who mentors a peer in Python earns Skill Credits.
- Those credits can then be spent to learn Photoshop, Web Development, or Guitar from other students.
- Built on **Oracle Database 21c Express Edition (XE)** with **Python Flask**, providing a full 3NF normalized relational schema, PL/SQL triggers, stored procedures, functions, database views, and a responsive web application.

---

## 🗄️ 2. Database Architecture (15 Relational Tables)

All tables are strictly normalized to **Third Normal Form (3NF)** with primary keys, foreign keys, `CHECK`, `NOT NULL`, and `UNIQUE` constraints:

| Table Name | Description | Key Constraints |
| :--- | :--- | :--- |
| `Users` | Student & Admin accounts (Rohan, Hemanth, etc.) | PK: `user_id`, UNIQUE: `email`, CHECK on `role`, `year` |
| `Skill_Categories` | Academic & creative skill categories | PK: `category_id`, UNIQUE: `category_name` |
| `Skills` | Individual catalog skills | PK: `skill_id`, FK: `category_id`, UNIQUE: `skill_name` |
| `User_Skills` | Junction table for skills offered by mentors | PK: `user_skill_id`, FK: `user_id`, FK: `skill_id`, UNIQUE: `(user_id, skill_id)` |
| `Skill_Requests` | Skills students wish to learn | PK: `request_id`, FK: `user_id`, FK: `skill_id` |
| `Availability` | Mentor weekly schedule slots | PK: `availability_id`, FK: `user_id`, CHECK: `day_of_week` |
| `Matches` | Algorithmic match scores between requests & mentors | PK: `match_id`, FK: `request_id`, FK: `mentor_id`, CHECK: `match_score` (0-100) |
| `Credit_Accounts` | 1:1 wallet account per user | PK: `account_id`, FK: `user_id` (UNIQUE), CHECK: `balance >= 0` |
| `Sessions` | Peer-to-peer learning sessions | PK: `session_id`, FK: `mentor_id`, FK: `learner_id`, FK: `skill_id`, CHECK: `mentor_id != learner_id` |
| `Credit_Transactions` | Double-entry financial audit trail | PK: `transaction_id`, FK: `account_id`, FK: `session_id`, CHECK: `transaction_type` |
| `Session_Attendance` | Session check-in/checkout tracking | PK: `attendance_id`, FK: `session_id`, FK: `user_id` |
| `Ratings` | 1:1 feedback & star rating for completed sessions | PK: `rating_id`, FK: `session_id` (UNIQUE), CHECK: `1.0 <= rating <= 5.0` |
| `Certificates` | Verifiable credentials issued upon completing 3+ hrs | PK: `certificate_id`, FK: `user_id`, FK: `skill_id`, UNIQUE: `certificate_code` |
| `Notifications` | Real-time system and P2P alerts | PK: `notification_id`, FK: `user_id`, CHECK: `is_read IN (0,1)` |
| `Reports` | Dispute resolution and issue reporting | PK: `report_id`, FK: `reported_by`, FK: `reported_user` |

---

## ⚡ 3. Advanced DBMS Features

### A. PL/SQL Triggers
1. **`trg_user_after_insert`**: Automatically provisions a `Credit_Accounts` wallet with **50 welcome credits** upon student registration, logs a `BONUS` transaction, and triggers a welcome notification.
2. **`trg_credit_account_touch`**: Automatically timestamps `last_updated` whenever wallet balance changes.
3. **`trg_check_session_integrity`**: Enforces business rules: `mentor_id != learner_id`, positive duration, and non-negative credit cost.
4. **`trg_prevent_self_match`**: Prevents a student from matching to fulfill their own skill request.
5. **`trg_validate_rating`**: Enforces that only learners can rate COMPLETED sessions, preventing fraudulent reviews.

### B. PL/SQL Stored Procedures & ACID Transactions
1. **`complete_session(p_session_id, out_msg)`**:
   - Locks session and accounts using `FOR UPDATE`.
   - Validates learner's credit balance.
   - Atomically debits learner and credits mentor.
   - Inserts double-entry audit records in `Credit_Transactions`.
   - Records attendance as `PRESENT`.
   - **Automated Certificate Issuance**: If cumulative learning hours in the skill reach 3.0+, auto-generates a cryptographic certificate (e.g. `CERT-PYTH-2026-0002`).
   - Dispatches notifications to both students.
   - Enforces full transaction `COMMIT` or `ROLLBACK` on any error.
2. **`match_mentors_for_request(p_request_id, out_count)`**: Scans mentors offering the skill, invokes `calculate_match_score()`, inserts match records, and alerts the learner.
3. **`book_session(...)`**: Validates wallet balance, checks time conflicts, and creates session request.

### C. PL/SQL Functions
1. **`calculate_match_score(p_request_id, p_mentor_id) RETURN NUMBER`**:
   - Multi-factor weighted compatibility formula (0–100):
     - **40%** Proficiency Match (Expert, Advanced, Intermediate)
     - **30%** Mentor Star Rating (scaled from 5-star peer reviews)
     - **20%** Teaching Experience (years + past conducted sessions)
     - **10%** Active Weekly Availability Overlap
2. **`get_credit_balance(p_user_id) RETURN NUMBER`**
3. **`get_average_rating(p_mentor_id) RETURN NUMBER`**
4. **`get_total_learning_hours(p_user_id, p_skill_id) RETURN NUMBER`**

### D. Analytical Views
- **`v_top_mentors`**: Mentors ranked by peer ratings and conducted sessions.
- **`v_available_mentors`**: Real-time directory of available peer tutors and their skills.
- **`v_student_dashboard`**: Aggregated student profile statistics.
- **`v_skill_demand_analytics`**: Market intelligence comparing requests vs active mentors.
- **`v_recent_transactions`**: Financial audit ledger linking users and session details.

---

## 🚀 4. How to Run the Project

### Prerequisites
- **Oracle Database 21c XE** (running on `localhost:1521/xepdb1`)
- **Python 3.10+** (tested on Python 3.14)
- **SQL\*Plus 21c**

---

### Step 1: Run SQL Scripts via SQL*Plus
To create all 15 tables, triggers, procedures, views, and seed data, open Command Prompt or PowerShell and execute:

```cmd
sqlplus skillswap/skillswap123@localhost:1521/xepdb1 @database/run_all.sql
```

*Note: If the `skillswap` user does not exist yet, create it as `sysdba`:*
```sql
ALTER SESSION SET CONTAINER = XEPDB1;
CREATE USER skillswap IDENTIFIED BY skillswap123;
GRANT CONNECT, RESOURCE, DBA TO skillswap;
ALTER USER skillswap QUOTA UNLIMITED ON USERS;
```

---

### Step 2: Install Python Dependencies
```cmd
pip install -r requirements.txt
```

---

### Step 3: Run the Automated Test Suite
Verify that all database connections, PL/SQL procedures, and web routes are functioning:
```cmd
python test_app_routes.py
```
*(All 9 integration tests should pass with `OK`)*

---

### Step 4: Launch the Web Application
```cmd
python -m app.app
```
Open your web browser and navigate to:
👉 **`http://127.0.0.1:5000`**

---

## 🧑‍💻 5. Demo Accounts for Evaluation

You can use the 1-click persona switchers on the login page or in the navbar:

| Persona Name | Email | Role | Notes |
| :--- | :--- | :--- | :--- |
| **Rohan Mogalapalli** | `rohan@campus.edu` | STUDENT (Mentor) | CSE Year 3 &bull; Teaches Python &amp; Figma (Reg: 24BCE2622) |
| **N. Sai Hemanth** | `hemanth@campus.edu` | STUDENT (Mentor) | CSE Year 3 &bull; Teaches Java &amp; React (Reg: 24BCE2400) |
| **Sneha Reddy** | `sneha@campus.edu` | STUDENT (Mentor) | Design Year 3 &bull; Top-rated Photoshop mentor (5.0 ★) |
| **Aarav Patel** | `aarav@campus.edu` | STUDENT (Learner) | Mechanical Year 2 &bull; Holds Certificate `CERT-PYTH-2026-0002` |
| **Prof. K. Swaminathan** | `admin@campus.edu` | ADMIN | Faculty / System Administrator |

---

## 📊 6. Faculty Review Highlights

1. **Live DBMS Showcase Page**: Visit `/dbms-showcase` in the app to inspect live 15-table row counts, view outputs, and procedure executions.
2. **Transaction Safety**: Try completing a session with a student whose balance is 0 to observe the PL/SQL exception `ORA-20011` enforcing credit balance integrity.
3. **Public Certificate Verification**: Go to `/verify-certificate` and search for code `CERT-PYTH-2026-0002` to see verified credential proof.
