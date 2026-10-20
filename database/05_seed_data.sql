-- ============================================================================
-- SkillSwap - Campus Skill Exchange Platform
-- Seed Data Script (05_seed_data.sql)
-- Authentic Data for Project Submission
-- Project Members: Mogalapalli Rohan (24BCE2622) & N. Sai Hemanth (24BCE2400)
-- Target: Oracle Database 21c XE
-- ============================================================================

SET DEFINE OFF;

-- ----------------------------------------------------------------------------
-- 1. Insert Reference Skill Categories (Platform Reference Data)
-- ----------------------------------------------------------------------------
INSERT INTO Skill_Categories (category_id, category_name, description) VALUES 
(1, 'Programming & Software', 'Software engineering, algorithms, web development, and coding languages');

INSERT INTO Skill_Categories (category_id, category_name, description) VALUES 
(2, 'Design & Multimedia', 'UI/UX interface design, digital illustration, photography, and video editing');

INSERT INTO Skill_Categories (category_id, category_name, description) VALUES 
(3, 'Data Science & AI', 'Machine learning, deep learning, data visualization, and statistics');

INSERT INTO Skill_Categories (category_id, category_name, description) VALUES 
(4, 'Creative Arts & Music', 'Musical instruments, vocal training, music production, and sound design');

INSERT INTO Skill_Categories (category_id, category_name, description) VALUES 
(5, 'Academics & Mathematics', 'Engineering mathematics, calculus, physics, and core science concepts');

INSERT INTO Skill_Categories (category_id, category_name, description) VALUES 
(6, 'Communication & Soft Skills', 'Public speaking, interview prep, debate, and leadership communication');

-- ----------------------------------------------------------------------------
-- 2. Insert Reference Skills (Platform Catalog)
-- ----------------------------------------------------------------------------
INSERT INTO Skills (skill_id, skill_name, category_id, description) VALUES 
(1, 'Python Programming', 1, 'Core Python syntax, data structures, scripting, and OOP concepts');

INSERT INTO Skills (skill_id, skill_name, category_id, description) VALUES 
(2, 'Java & OOP', 1, 'Object-Oriented Programming, Java Collections, streams, and multithreading');

INSERT INTO Skills (skill_id, skill_name, category_id, description) VALUES 
(3, 'React & Web Dev', 1, 'Modern frontend web development with HTML, CSS, JavaScript, and React');

INSERT INTO Skills (skill_id, skill_name, category_id, description) VALUES 
(4, 'Photoshop & Digital Art', 2, 'Photo retouching, poster design, typography, and graphic assets');

INSERT INTO Skills (skill_id, skill_name, category_id, description) VALUES 
(5, 'UI/UX Design in Figma', 2, 'Wireframing, prototyping, design systems, and responsive web layouts');

INSERT INTO Skills (skill_id, skill_name, category_id, description) VALUES 
(6, 'Video Editing', 2, 'Video storytelling, color grading, and effects in Premiere Pro & DaVinci');

INSERT INTO Skills (skill_id, skill_name, category_id, description) VALUES 
(7, 'Machine Learning & PyTorch', 3, 'Supervised learning, neural networks, computer vision, and NLP models');

INSERT INTO Skills (skill_id, skill_name, category_id, description) VALUES 
(8, 'Acoustic Guitar', 4, 'Chords, fingerstyle technique, scales, and rhythm accompaniment');

INSERT INTO Skills (skill_id, skill_name, category_id, description) VALUES 
(9, 'Linear Algebra & Calculus', 5, 'Matrix operations, vector spaces, derivatives, integrals, and transforms');

INSERT INTO Skills (skill_id, skill_name, category_id, description) VALUES 
(10, 'Public Speaking & Debating', 6, 'Confidence building, speech structuring, rhetoric, and debate tactics');

-- ----------------------------------------------------------------------------
-- 3. Insert Authentic Project Members & Campus Accounts
-- (Note: trg_user_after_insert automatically creates Credit_Accounts with 50 credits each)
-- ----------------------------------------------------------------------------
-- User 1: Mogalapalli Rohan (24BCE2622)
INSERT INTO Users (user_id, name, email, password, department, year, phone, role, status) VALUES 
(1, 'Mogalapalli Rohan', 'rohan.m2024@vitstudent.ac.in', 'password123', 'CSE', 2, '9876543210', 'STUDENT', 'ACTIVE');

-- User 2: N. Sai Hemanth (24BCE2400)
INSERT INTO Users (user_id, name, email, password, department, year, phone, role, status) VALUES 
(2, 'N. Sai Hemanth', 'hemanth.ns2024@vitstudent.ac.in', 'password123', 'CSE', 2, '9876543211', 'STUDENT', 'ACTIVE');

-- User 3: Faculty / System Administrator Account for Evaluation
INSERT INTO Users (user_id, name, email, password, department, year, phone, role, status) VALUES 
(3, 'Prof. K. Swaminathan (Admin)', 'admin@vit.ac.in', 'admin123', 'CSE', 5, '9876543299', 'ADMIN', 'ACTIVE');

-- ----------------------------------------------------------------------------
-- 4. Skills Offered by Project Members (User_Skills)
-- ----------------------------------------------------------------------------
-- Rohan teaches Python (Skill 1) and Figma (Skill 5)
INSERT INTO User_Skills (user_skill_id, user_id, skill_id, proficiency_level, experience_years, available_hours, status) VALUES 
(1, 1, 1, 'EXPERT', 2.5, 6.0, 'AVAILABLE');
INSERT INTO User_Skills (user_skill_id, user_id, skill_id, proficiency_level, experience_years, available_hours, status) VALUES 
(2, 1, 5, 'ADVANCED', 2.0, 4.0, 'AVAILABLE');

-- Hemanth teaches Java (Skill 2) and React (Skill 3)
INSERT INTO User_Skills (user_skill_id, user_id, skill_id, proficiency_level, experience_years, available_hours, status) VALUES 
(3, 2, 2, 'EXPERT', 2.5, 6.0, 'AVAILABLE');
INSERT INTO User_Skills (user_skill_id, user_id, skill_id, proficiency_level, experience_years, available_hours, status) VALUES 
(4, 2, 3, 'ADVANCED', 2.0, 5.0, 'AVAILABLE');

-- ----------------------------------------------------------------------------
-- 5. Availability Schedules for Project Members
-- ----------------------------------------------------------------------------
-- Rohan's Schedule
INSERT INTO Availability (availability_id, user_id, day_of_week, start_time, end_time, status) VALUES 
(1, 1, 'Monday', '17:00', '19:00', 'ACTIVE');
INSERT INTO Availability (availability_id, user_id, day_of_week, start_time, end_time, status) VALUES 
(2, 1, 'Wednesday', '16:00', '18:00', 'ACTIVE');
INSERT INTO Availability (availability_id, user_id, day_of_week, start_time, end_time, status) VALUES 
(3, 1, 'Saturday', '10:00', '13:00', 'ACTIVE');

-- Hemanth's Schedule
INSERT INTO Availability (availability_id, user_id, day_of_week, start_time, end_time, status) VALUES 
(4, 2, 'Tuesday', '17:00', '19:00', 'ACTIVE');
INSERT INTO Availability (availability_id, user_id, day_of_week, start_time, end_time, status) VALUES 
(5, 2, 'Thursday', '16:00', '18:00', 'ACTIVE');
INSERT INTO Availability (availability_id, user_id, day_of_week, start_time, end_time, status) VALUES 
(6, 2, 'Sunday', '14:00', '17:00', 'ACTIVE');

-- ----------------------------------------------------------------------------
-- 6. Peer Skill Requests Between Members
-- ----------------------------------------------------------------------------
-- Rohan wants to learn Java & OOP from Hemanth
INSERT INTO Skill_Requests (request_id, user_id, skill_id, desired_level, priority, request_date, status) VALUES 
(1, 1, 2, 'ADVANCED', 'HIGH', SYSDATE - 5, 'MATCHED');

-- Hemanth wants to learn Python Programming from Rohan
INSERT INTO Skill_Requests (request_id, user_id, skill_id, desired_level, priority, request_date, status) VALUES 
(2, 2, 1, 'ADVANCED', 'HIGH', SYSDATE - 4, 'MATCHED');

-- ----------------------------------------------------------------------------
-- 7. Algorithmic Matches Generated Between Members
-- ----------------------------------------------------------------------------
-- Rohan matched with Hemanth for Java
INSERT INTO Matches (match_id, request_id, mentor_id, match_score, match_date, status) VALUES 
(1, 1, 2, 94.50, SYSDATE - 4, 'ACCEPTED');

-- Hemanth matched with Rohan for Python
INSERT INTO Matches (match_id, request_id, mentor_id, match_score, match_date, status) VALUES 
(2, 2, 1, 95.00, SYSDATE - 3, 'SCHEDULED');

-- ----------------------------------------------------------------------------
-- 8. Completed Peer Sessions Between Members
-- ----------------------------------------------------------------------------

-- Session 1: Hemanth teaches Rohan Java & OOP (COMPLETED 2.0 hrs, 20 credits)
INSERT INTO Sessions (
    session_id, match_id, mentor_id, learner_id, skill_id, scheduled_date, 
    start_time, end_time, duration, credit_cost, status, created_at, completed_at
) VALUES (
    1, 1, 2, 1, 2, SYSDATE - 3, '17:00', '19:00', 2.0, 20.00, 'COMPLETED', 
    SYSTIMESTAMP - INTERVAL '3' DAY, SYSTIMESTAMP - INTERVAL '3' DAY + INTERVAL '2' HOUR
);

-- Transfer 20 credits: Rohan debited, Hemanth credited
UPDATE Credit_Accounts SET balance = balance - 20.00, total_spent = total_spent + 20.00 WHERE user_id = 1;
UPDATE Credit_Accounts SET balance = balance + 20.00, total_earned = total_earned + 20.00 WHERE user_id = 2;

INSERT INTO Credit_Transactions (account_id, session_id, transaction_type, amount, transaction_date, description)
SELECT account_id, 1, 'SPEND', 20.00, SYSTIMESTAMP - INTERVAL '3' DAY, 'Debited for completed session #1 (Java & OOP)'
FROM Credit_Accounts WHERE user_id = 1;

INSERT INTO Credit_Transactions (account_id, session_id, transaction_type, amount, transaction_date, description)
SELECT account_id, 1, 'EARN', 20.00, SYSTIMESTAMP - INTERVAL '3' DAY, 'Earned from teaching session #1 (Java & OOP)'
FROM Credit_Accounts WHERE user_id = 2;

INSERT INTO Session_Attendance (session_id, user_id, attendance_status, joined_at, left_at) VALUES 
(1, 2, 'PRESENT', SYSTIMESTAMP - INTERVAL '3' DAY, SYSTIMESTAMP - INTERVAL '3' DAY + INTERVAL '2' HOUR);
INSERT INTO Session_Attendance (session_id, user_id, attendance_status, joined_at, left_at) VALUES 
(1, 1, 'PRESENT', SYSTIMESTAMP - INTERVAL '3' DAY, SYSTIMESTAMP - INTERVAL '3' DAY + INTERVAL '2' HOUR);

INSERT INTO Ratings (session_id, mentor_id, learner_id, rating, feedback, created_at) VALUES 
(1, 2, 1, 5.0, 'Hemanth explained Java OOP, abstraction, and memory architecture thoroughly. Great hands-on coding walkthrough!', SYSTIMESTAMP - INTERVAL '3' DAY + INTERVAL '2' HOUR);

-- Session 2: Hemanth teaches Rohan Java & OOP (COMPLETED 1.5 hrs, 15 credits -> Rohan reaches 3.5 total hours in Java!)
INSERT INTO Sessions (
    session_id, match_id, mentor_id, learner_id, skill_id, scheduled_date, 
    start_time, end_time, duration, credit_cost, status, created_at, completed_at
) VALUES (
    2, 1, 2, 1, 2, SYSDATE - 1, '16:00', '17:30', 1.5, 15.00, 'COMPLETED', 
    SYSTIMESTAMP - INTERVAL '1' DAY, SYSTIMESTAMP - INTERVAL '1' DAY + INTERVAL '90' MINUTE
);

UPDATE Credit_Accounts SET balance = balance - 15.00, total_spent = total_spent + 15.00 WHERE user_id = 1;
UPDATE Credit_Accounts SET balance = balance + 15.00, total_earned = total_earned + 15.00 WHERE user_id = 2;

INSERT INTO Credit_Transactions (account_id, session_id, transaction_type, amount, transaction_date, description)
SELECT account_id, 2, 'SPEND', 15.00, SYSTIMESTAMP - INTERVAL '1' DAY, 'Debited for completed session #2 (Java & OOP)'
FROM Credit_Accounts WHERE user_id = 1;

INSERT INTO Credit_Transactions (account_id, session_id, transaction_type, amount, transaction_date, description)
SELECT account_id, 2, 'EARN', 15.00, SYSTIMESTAMP - INTERVAL '1' DAY, 'Earned from teaching session #2 (Java & OOP)'
FROM Credit_Accounts WHERE user_id = 2;

INSERT INTO Session_Attendance (session_id, user_id, attendance_status, joined_at, left_at) VALUES 
(2, 2, 'PRESENT', SYSTIMESTAMP - INTERVAL '1' DAY, SYSTIMESTAMP - INTERVAL '1' DAY + INTERVAL '90' MINUTE);
INSERT INTO Session_Attendance (session_id, user_id, attendance_status, joined_at, left_at) VALUES 
(2, 1, 'PRESENT', SYSTIMESTAMP - INTERVAL '1' DAY, SYSTIMESTAMP - INTERVAL '1' DAY + INTERVAL '90' MINUTE);

INSERT INTO Ratings (session_id, mentor_id, learner_id, rating, feedback, created_at) VALUES 
(2, 2, 1, 4.9, 'Follow-up on Java Collections, streams, and exception handling. Clear examples.', SYSTIMESTAMP - INTERVAL '1' DAY + INTERVAL '1' HOUR);

-- Rohan receives verifiable Java Certificate for completing 3.5 cumulative learning hours
INSERT INTO Certificates (certificate_id, user_id, skill_id, certificate_code, issue_date, hours_completed, status) VALUES 
(1, 1, 2, 'CERT-JAVA-2026-0002', SYSDATE - 1, 3.5, 'VERIFIED');

-- Session 3: Scheduled Session: Rohan (Mentor) teaching Hemanth (Learner) Python
INSERT INTO Sessions (
    session_id, match_id, mentor_id, learner_id, skill_id, scheduled_date, 
    start_time, end_time, duration, credit_cost, status, created_at
) VALUES (
    3, 2, 1, 2, 1, TRUNC(SYSDATE) + 1, '17:00', '18:00', 1.0, 10.00, 'SCHEDULED', SYSTIMESTAMP
);

-- ----------------------------------------------------------------------------
-- 9. Resync Identity Sequences for Seamless Auto-Increment
-- ----------------------------------------------------------------------------
ALTER TABLE Users MODIFY (user_id GENERATED BY DEFAULT AS IDENTITY (START WITH 10));
ALTER TABLE Skill_Categories MODIFY (category_id GENERATED BY DEFAULT AS IDENTITY (START WITH 10));
ALTER TABLE Skills MODIFY (skill_id GENERATED BY DEFAULT AS IDENTITY (START WITH 20));
ALTER TABLE User_Skills MODIFY (user_skill_id GENERATED BY DEFAULT AS IDENTITY (START WITH 10));
ALTER TABLE Skill_Requests MODIFY (request_id GENERATED BY DEFAULT AS IDENTITY (START WITH 10));
ALTER TABLE Availability MODIFY (availability_id GENERATED BY DEFAULT AS IDENTITY (START WITH 10));
ALTER TABLE Matches MODIFY (match_id GENERATED BY DEFAULT AS IDENTITY (START WITH 10));
ALTER TABLE Credit_Accounts MODIFY (account_id GENERATED BY DEFAULT AS IDENTITY (START WITH 10));
ALTER TABLE Sessions MODIFY (session_id GENERATED BY DEFAULT AS IDENTITY (START WITH 10));
ALTER TABLE Credit_Transactions MODIFY (transaction_id GENERATED BY DEFAULT AS IDENTITY (START WITH 30));
ALTER TABLE Session_Attendance MODIFY (attendance_id GENERATED BY DEFAULT AS IDENTITY (START WITH 10));
ALTER TABLE Ratings MODIFY (rating_id GENERATED BY DEFAULT AS IDENTITY (START WITH 10));
ALTER TABLE Certificates MODIFY (certificate_id GENERATED BY DEFAULT AS IDENTITY (START WITH 10));

COMMIT;
