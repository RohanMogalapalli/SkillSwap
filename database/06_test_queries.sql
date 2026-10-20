-- ============================================================================
-- SkillSwap - Campus Skill Exchange Platform
-- Verification & Academic Test Queries Script (06_test_queries.sql)
-- DBMS Project by Mogalapalli Rohan (24BCE2622) & N. Sai Hemanth (24BCE2400)
-- Target: Oracle Database 21c XE
-- ============================================================================

SET DEFINE OFF;
SET LINESIZE 160
SET PAGESIZE 50
COLUMN mentor_name FORMAT A20
COLUMN skill_name FORMAT A25
COLUMN category_name FORMAT A22
COLUMN student_name FORMAT A20
COLUMN email FORMAT A24
COLUMN average_rating FORMAT 99.99
COLUMN credit_balance FORMAT 999.99
COLUMN match_score FORMAT 999.99

PROMPT ============================================================================
PROMPT 1. TABLE ROW COUNTS ACROSS ALL 15 RELATIONAL TABLES
PROMPT ============================================================================
SELECT 'Users' AS Table_Name, COUNT(*) AS Total_Rows FROM Users
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
UNION ALL SELECT 'Reports', COUNT(*) FROM Reports;

PROMPT
PROMPT ============================================================================
PROMPT 2. TOP MENTORS VIEW (v_top_mentors)
PROMPT ============================================================================
SELECT * FROM v_top_mentors;

PROMPT
PROMPT ============================================================================
PROMPT 3. STUDENT DASHBOARD VIEW (v_student_dashboard)
PROMPT ============================================================================
SELECT user_id, name, department, credit_balance, hours_learned, hours_taught, certificates_earned, mentor_rating
FROM v_student_dashboard;

PROMPT
PROMPT ============================================================================
PROMPT 4. SKILL DEMAND & MARKET ANALYTICS VIEW (v_skill_demand_analytics)
PROMPT ============================================================================
SELECT * FROM v_skill_demand_analytics;

PROMPT
PROMPT ============================================================================
PROMPT 5. RECENT CREDIT AUDIT TRANSACTIONS VIEW (v_recent_transactions)
PROMPT ============================================================================
SELECT transaction_id, student_name, transaction_type, amount, skill_name, description
FROM v_recent_transactions
WHERE ROWNUM <= 10;

PROMPT
PROMPT ============================================================================
PROMPT 6. DEMONSTRATION OF PL/SQL MATCHING FUNCTION (calculate_match_score)
PROMPT ============================================================================
SELECT 
    m.match_id,
    sr.request_id,
    u_learn.name AS learner,
    u_ment.name AS mentor,
    k.skill_name,
    m.match_score,
    calculate_match_score(sr.request_id, u_ment.user_id) AS recalculate_test
FROM Matches m
JOIN Skill_Requests sr ON m.request_id = sr.request_id
JOIN Users u_learn ON sr.user_id = u_learn.user_id
JOIN Users u_ment ON m.mentor_id = u_ment.user_id
JOIN Skills k ON sr.skill_id = k.skill_id;

PROMPT
PROMPT ============================================================================
PROMPT 7. COMPLEX MULTI-TABLE JOIN (Demonstrates 3NF Normalization)
PROMPT ============================================================================
SELECT 
    s.session_id,
    u_m.name AS mentor,
    u_l.name AS learner,
    k.skill_name,
    c.category_name,
    s.duration || ' hrs' AS duration,
    s.credit_cost || ' pts' AS cost,
    s.status,
    NVL(TO_CHAR(r.rating, '9.9'), 'Not Rated') AS rating_given
FROM Sessions s
JOIN Users u_m ON s.mentor_id = u_m.user_id
JOIN Users u_l ON s.learner_id = u_l.user_id
JOIN Skills k ON s.skill_id = k.skill_id
JOIN Skill_Categories c ON k.category_id = c.category_id
LEFT JOIN Ratings r ON s.session_id = r.session_id
ORDER BY s.session_id;

PROMPT
PROMPT Verification completed successfully!
