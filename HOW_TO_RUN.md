# SkillSwap — Project Startup & Execution Guide

**Campus Skill Exchange Platform (DBS Course Project)**  
*Authors:* Mogalapalli Rohan (`24BCE2622`) & N. Sai Hemanth (`24BCE2400`)  
*Database:* Oracle Database 21c Express Edition (`XEPDB1`)  
*Web Framework:* Python 3.14 + Flask  

---

## 📋 Table of Contents
1. [Prerequisites Checklist](#1-prerequisites-checklist)
2. [Step 1: Oracle Database Setup (SQL*Plus)](#2-step-1-oracle-database-setup-sqlplus)
3. [Step 2: Python Environment & Dependencies](#3-step-2-python-environment--dependencies)
4. [Step 3: Automated Test Verification](#4-step-3-automated-test-verification)
5. [Step 4: Launching the Web Application](#5-step-4-launching-the-web-application)
6. [Step 5: Review & Evaluation Demo Script](#6-step-5-review--evaluation-demo-script)
7. [Troubleshooting & Common Questions](#7-troubleshooting--common-questions)

---

## 1. Prerequisites Checklist

Ensure that the following services and software are running on your machine:
- **Oracle Database 21c XE** (Services `OracleServiceXE` and `OracleOraDB21Home1TNSListener` must be running).
- **SQL\*Plus 21c** (`sqlplus` command accessible in terminal).
- **Python 3.10+** (Python 3.14 installed).

You can verify Oracle services in PowerShell:
```powershell
Get-Service *Oracle*
```
Both `OracleServiceXE` and `OracleOraDB21Home1TNSListener` should show **Running**.

---

## 2. Step 1: Oracle Database Setup (SQL*Plus)

### Option A: If the `SKILLSWAP` user is already created (Default)
Open Command Prompt or PowerShell in the project directory (`C:\projects\SkillSwap`) and run:

```cmd
sqlplus skillswap/skillswap123@localhost:1521/xepdb1 @database/run_all.sql
```

This single command automatically runs:
1. `01_schema.sql` — Drops old tables and builds all 15 relational tables with constraints and indexes.
2. `02_triggers.sql` — Compiles all 5 PL/SQL triggers.
3. `03_functions_procedures.sql` — Compiles matching algorithm, credit transfer procedure, and helper functions.
4. `04_views.sql` — Creates analytical views (`v_top_mentors`, `v_student_dashboard`, etc.).
5. `05_seed_data.sql` — Populates campus student data, skills, sessions, ratings, and certificates.
6. `06_test_queries.sql` — Runs verification queries and displays output.

---

### Option B: If creating the `SKILLSWAP` user from scratch
If you ever reset Oracle or need to re-grant permissions, connect as `sysdba`:

```cmd
sqlplus / as sysdba
```
Then paste the following commands:
```sql
ALTER SESSION SET CONTAINER = XEPDB1;
CREATE USER skillswap IDENTIFIED BY skillswap123;
GRANT CONNECT, RESOURCE, DBA TO skillswap;
ALTER USER skillswap QUOTA UNLIMITED ON USERS;
EXIT;
```
After creating the user, run Step 1 Option A above.

---

## 3. Step 2: Python Environment & Dependencies

Open terminal in `C:\projects\SkillSwap` and install the required Python packages:

```cmd
pip install -r requirements.txt
```

*Required packages:*
- `flask` (Web framework)
- `oracledb` (Official Oracle database client for Python)
- `cryptography` (Secure connection support)

---

## 4. Step 3: Automated Test Verification

Before starting the web server, run the automated integration test suite to verify database connectivity, PL/SQL procedure execution, and template rendering:

```cmd
python test_app_routes.py
```

**Expected Result:**
```
.........
----------------------------------------------------------------------
Ran 9 tests in ~3.3s

OK
```
If you see `OK`, your database, triggers, procedures, and web endpoints are 100% operational!

---

## 5. Step 4: Launching the Web Application

Start the Flask development server:

```cmd
python -m app.app
```

You should see output similar to:
```
 * Serving Flask app 'app.app'
 * Debug mode: on
 * Running on http://127.0.0.1:5000
Press CTRL+C to quit
```

Now, open your web browser (Chrome, Edge, Firefox) and go to:
👉 **[http://127.0.0.1:5000](http://127.0.0.1:5000)**

---

## 6. Step 5: Review & Evaluation Demo Script

Here is a recommended 5-minute walkthrough to demonstrate the project to your faculty or evaluator:

### Step 5.1: Landing Page & Top Mentors View
- Go to `http://127.0.0.1:5000`.
- Point out the **Live Campus Counters** (Students, Skills, Sessions Completed, Credits).
- Highlight the **Featured Mentors** section — explain that this is dynamically queried from the Oracle View **`v_top_mentors`**.

### Step 5.2: One-Click Evaluation Persona Login
- Click **"Start Learning • Quick Login"** (or click **"Log In"** in navbar).
- On the login page, you will see the **⚡ Reviewer Quick Access** panel.
- Click on **Rohan Mogalapalli (24BCE2622)** to log in instantly without typing passwords.

### Step 5.3: Student Dashboard & 3NF Schema
- Point out the **Skill Wallet** (credit balance, total earned, total spent).
- Explain the **dual role**: Rohan can act as a **Mentor** (teaches Python & Figma) and as a **Learner** (wants to learn Photoshop). Show that both roles are unified in the `Users` table (Section 6.4 of review doc).

### Step 5.4: Algorithmic Mentor Matching (PL/SQL Function)
- Click **"View Matches"** on Rohan's request for *Photoshop & Digital Art*.
- Show the compatibility score (**94.5 / 100**) calculated by the PL/SQL function **`calculate_match_score()`**.
- Explain the formula: 40% proficiency tier + 30% star rating + 20% experience + 10% availability overlap.

### Step 5.5: Session Completion & Atomic Credit Transfer (ACID Transaction)
- Switch persona to **Sneha Reddy** (from the top-right user menu).
- Go to **Sessions** (`/sessions`).
- Find an accepted session and click **"Complete • Claim Credits"**.
- Explain to the professor that this calls the PL/SQL stored procedure **`complete_session()`**:
  1. Verifies the learner has sufficient credits.
  2. Atomically debits the learner and credits the mentor.
  3. Writes double-entry ledger rows into `Credit_Transactions`.
  4. Automatically issues a **Certificate** if the learner reaches 3.0+ hours!
  5. Automatically rolls back on any error (`ROLLBACK;`).

### Step 5.6: Verifiable Certificate Portal
- Switch persona to **Aarav Patel** and click **Certificates** in navbar.
- Show the cryptographic certificate card with code **`CERT-PYTH-2026-0002`**.
- Click **"Verify a Certificate Code"**, paste the code, and show the real-time Oracle database validation.

### Step 5.7: Live DBMS Concept Showcase Page
- In the navbar, click the green button: **"DBMS Showcase"** (`/dbms-showcase`).
- This page displays:
  - **Live Table Row Counts** across all **15 relational tables**.
  - Live query results of **`v_top_mentors`** and **`v_skill_demand_analytics`**.
  - Code summaries for triggers, procedures, and functions.

### Step 5.8: Admin Moderation Console
- Switch persona to **Prof. K. Swaminathan (Admin)**.
- Click **"Admin"** in the navbar (`/admin`).
- Show the student wallet directory and the **Dispute & Incident Reports Queue**, then click **"Mark Resolved"** on an open complaint.

---

## 7. Troubleshooting & Common Questions

### Q: `sqlplus` gives `ORA-12541: TNS:no listener` or connection refused?
**Solution:** Check that the Oracle Listener service is running:
```powershell
Start-Service OracleOraDB21Home1TNSListener
Start-Service OracleServiceXE
```

### Q: How do I change the database password or port?
**Solution:** By default, the application connects to `localhost:1521/xepdb1` with user `skillswap` and password `skillswap123`. You can override these using environment variables in your terminal:
```cmd
set ORACLE_USER=skillswap
set ORACLE_PASSWORD=your_password
set ORACLE_DSN=localhost:1521/xepdb1
python -m app.app
```

### Q: Port 5000 is already in use?
**Solution:** In `app/app.py`, change the port on the last line:
```python
app.run(debug=True, host="127.0.0.1", port=5001)
```
Then visit `http://127.0.0.1:5001`.

---

### 📞 Contact & Support
- **Mogalapalli Rohan** — Reg. No: `24BCE2622` (`rohan@campus.edu`)
- **N. Sai Hemanth** — Reg. No: `24BCE2400` (`hemanth@campus.edu`)
