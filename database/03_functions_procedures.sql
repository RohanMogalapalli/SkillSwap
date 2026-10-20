-- ============================================================================
-- SkillSwap - Campus Skill Exchange Platform
-- PL/SQL Functions and Stored Procedures Script (03_functions_procedures.sql)
-- DBMS Project by Mogalapalli Rohan (24BCE2622) & N. Sai Hemanth (24BCE2400)
-- Target: Oracle Database 21c XE
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Function 1: get_credit_balance
-- Returns current credit balance for a given user.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_credit_balance(p_user_id IN NUMBER)
RETURN NUMBER
IS
    v_balance NUMBER(10,2) := 0;
BEGIN
    SELECT NVL(balance, 0) INTO v_balance
    FROM Credit_Accounts
    WHERE user_id = p_user_id;

    RETURN v_balance;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
END;
/

-- ----------------------------------------------------------------------------
-- Function 2: get_average_rating
-- Calculates average star rating for a mentor across all completed sessions.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_average_rating(p_mentor_id IN NUMBER)
RETURN NUMBER
IS
    v_avg NUMBER(3,2) := 0;
BEGIN
    SELECT NVL(ROUND(AVG(rating), 2), 0) INTO v_avg
    FROM Ratings
    WHERE mentor_id = p_mentor_id;

    RETURN v_avg;
END;
/

-- ----------------------------------------------------------------------------
-- Function 3: get_total_learning_hours
-- Computes cumulative learning hours completed by a student for a skill.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_total_learning_hours(
    p_user_id  IN NUMBER,
    p_skill_id IN NUMBER
)
RETURN NUMBER
IS
    v_hours NUMBER(5,1) := 0;
BEGIN
    SELECT NVL(SUM(duration), 0) INTO v_hours
    FROM Sessions
    WHERE learner_id = p_user_id
      AND skill_id = p_skill_id
      AND status = 'COMPLETED';

    RETURN v_hours;
END;
/

-- ----------------------------------------------------------------------------
-- Function 4: calculate_match_score
-- Implements the multi-factor scoring formula agreed upon:
-- 40% Proficiency Match + 30% Mentor Rating + 20% Teaching Experience + 10% Availability Overlap
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION calculate_match_score(
    p_request_id IN NUMBER,
    p_mentor_id  IN NUMBER
)
RETURN NUMBER
IS
    v_req_skill_id    NUMBER;
    v_req_user_id     NUMBER;
    v_desired_level   VARCHAR2(20);
    
    v_mentor_level    VARCHAR2(20);
    v_exp_years       NUMBER(4,1) := 0;
    v_avail_slots     NUMBER := 0;
    v_avg_rating      NUMBER(3,2) := 0;
    v_completed_count NUMBER := 0;
    
    v_score_prof      NUMBER := 0;
    v_score_rating    NUMBER := 0;
    v_score_exp       NUMBER := 0;
    v_score_avail     NUMBER := 0;
    v_total_score     NUMBER := 0;
BEGIN
    -- 1. Fetch request details
    SELECT skill_id, user_id, desired_level 
    INTO v_req_skill_id, v_req_user_id, v_desired_level
    FROM Skill_Requests
    WHERE request_id = p_request_id;

    -- Mentors cannot match their own requests
    IF v_req_user_id = p_mentor_id THEN
        RETURN 0;
    END IF;

    -- 2. Fetch mentor's offering for this skill
    BEGIN
        SELECT proficiency_level, experience_years
        INTO v_mentor_level, v_exp_years
        FROM User_Skills
        WHERE user_id = p_mentor_id 
          AND skill_id = v_req_skill_id
          AND status = 'AVAILABLE';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 0; -- Not offering this skill or currently unavailable
    END;

    -- 3. Calculate 40% Proficiency component
    -- Mapping: EXPERT=4, ADVANCED=3, INTERMEDIATE=2, BEGINNER=1
    DECLARE
        v_d_val NUMBER;
        v_m_val NUMBER;
    BEGIN
        v_d_val := CASE v_desired_level 
                     WHEN 'EXPERT' THEN 4 
                     WHEN 'ADVANCED' THEN 3 
                     WHEN 'INTERMEDIATE' THEN 2 
                     ELSE 1 END;
        v_m_val := CASE v_mentor_level 
                     WHEN 'EXPERT' THEN 4 
                     WHEN 'ADVANCED' THEN 3 
                     WHEN 'INTERMEDIATE' THEN 2 
                     ELSE 1 END;

        IF v_m_val >= v_d_val THEN
            v_score_prof := 40.0;
        ELSE
            v_score_prof := ROUND((v_m_val / v_d_val) * 40.0, 2);
        END IF;
    END;

    -- 4. Calculate 30% Rating component (Rating scaled from 5.0 -> 30 max points)
    v_avg_rating := get_average_rating(p_mentor_id);
    IF v_avg_rating > 0 THEN
        v_score_rating := ROUND((v_avg_rating / 5.0) * 30.0, 2);
    ELSE
        -- Default neutral baseline score for newer mentors (4.0 out of 5 equivalent)
        v_score_rating := 24.0;
    END IF;

    -- 5. Calculate 20% Teaching Experience component (Years + Sessions conducted)
    SELECT COUNT(*) INTO v_completed_count
    FROM Sessions
    WHERE mentor_id = p_mentor_id AND status = 'COMPLETED';

    v_score_exp := LEAST(20.0, (v_exp_years * 5.0) + (v_completed_count * 1.5));

    -- 6. Calculate 10% Availability component
    SELECT COUNT(*) INTO v_avail_slots
    FROM Availability
    WHERE user_id = p_mentor_id AND status = 'ACTIVE';

    IF v_avail_slots >= 2 THEN
        v_score_avail := 10.0;
    ELSIF v_avail_slots = 1 THEN
        v_score_avail := 5.0;
    ELSE
        v_score_avail := 2.0;
    END IF;

    v_total_score := v_score_prof + v_score_rating + v_score_exp + v_score_avail;
    IF v_total_score > 100 THEN
        v_total_score := 100.0;
    END IF;

    RETURN ROUND(v_total_score, 2);
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END;
/

-- ----------------------------------------------------------------------------
-- Procedure 1: match_mentors_for_request
-- Evaluates all active mentors for a requested skill and logs matches with scores.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE match_mentors_for_request(
    p_request_id IN NUMBER,
    p_matches_created OUT NUMBER
)
IS
    v_skill_id       NUMBER;
    v_requester_id   NUMBER;
    v_match_count    NUMBER := 0;
    v_score          NUMBER(5,2);
BEGIN
    SELECT skill_id, user_id INTO v_skill_id, v_requester_id
    FROM Skill_Requests
    WHERE request_id = p_request_id;

    -- Scan prospective mentors offering this skill
    FOR m IN (
        SELECT user_id 
        FROM User_Skills
        WHERE skill_id = v_skill_id 
          AND user_id <> v_requester_id 
          AND status = 'AVAILABLE'
    ) LOOP
        v_score := calculate_match_score(p_request_id, m.user_id);
        
        IF v_score >= 40 THEN
            -- Check if match record already exists
            MERGE INTO Matches tgt
            USING (SELECT p_request_id AS req_id, m.user_id AS ment_id FROM dual) src
            ON (tgt.request_id = src.req_id AND tgt.mentor_id = src.ment_id)
            WHEN MATCHED THEN
                UPDATE SET tgt.match_score = v_score, tgt.match_date = SYSDATE
            WHEN NOT MATCHED THEN
                INSERT (request_id, mentor_id, match_score, match_date, status)
                VALUES (p_request_id, m.user_id, v_score, SYSDATE, 'PROPOSED');

            v_match_count := v_match_count + 1;
        END IF;
    END LOOP;

    -- Update request status if matches were identified
    IF v_match_count > 0 THEN
        UPDATE Skill_Requests 
        SET status = 'MATCHED' 
        WHERE request_id = p_request_id;

        -- Send notification to learner
        INSERT INTO Notifications (user_id, message, notification_type)
        VALUES (
            v_requester_id, 
            'Great news! We found ' || v_match_count || ' mentor match(es) for your skill request.',
            'MATCH_FOUND'
        );
    END IF;

    p_matches_created := v_match_count;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

-- ----------------------------------------------------------------------------
-- Procedure 2: complete_session
-- Atomic transaction executing:
-- 1. Balance verification
-- 2. Credit debit from learner & credit to mentor
-- 3. Double-entry transaction logging
-- 4. Session completion & Attendance logging
-- 5. Automated Certificate issuance when learning hours reach 3.0+
-- 6. Notifications for both parties
-- ----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE complete_session(
    p_session_id IN NUMBER,
    p_status_msg OUT VARCHAR2
)
IS
    v_mentor_id       NUMBER;
    v_learner_id      NUMBER;
    v_skill_id        NUMBER;
    v_skill_name      VARCHAR2(100);
    v_duration        NUMBER(4,1);
    v_cost            NUMBER(10,2);
    v_curr_status     VARCHAR2(20);
    
    v_learner_acc_id  NUMBER;
    v_mentor_acc_id   NUMBER;
    v_learner_bal     NUMBER(10,2);
    
    v_total_hours     NUMBER(5,1);
    v_cert_count      NUMBER;
    v_cert_code       VARCHAR2(50);
BEGIN
    -- 1. Lock and verify session
    SELECT s.mentor_id, s.learner_id, s.skill_id, k.skill_name, s.duration, s.credit_cost, s.status
    INTO v_mentor_id, v_learner_id, v_skill_id, v_skill_name, v_duration, v_cost, v_curr_status
    FROM Sessions s
    JOIN Skills k ON s.skill_id = k.skill_id
    WHERE s.session_id = p_session_id
    FOR UPDATE;

    IF v_curr_status = 'COMPLETED' THEN
        p_status_msg := 'Session is already marked as completed.';
        RETURN;
    END IF;

    IF v_curr_status NOT IN ('ACCEPTED', 'SCHEDULED', 'REQUESTED') THEN
        RAISE_APPLICATION_ERROR(-20010, 'Cannot complete session with status: ' || v_curr_status);
    END IF;

    -- 2. Verify Learner's Credit Account and Balance
    SELECT account_id, balance INTO v_learner_acc_id, v_learner_bal
    FROM Credit_Accounts
    WHERE user_id = v_learner_id
    FOR UPDATE;

    IF v_learner_bal < v_cost THEN
        RAISE_APPLICATION_ERROR(-20011, 'Insufficient credits! Learner balance is ' || v_learner_bal || ', required: ' || v_cost);
    END IF;

    -- 3. Fetch Mentor's Credit Account
    SELECT account_id INTO v_mentor_acc_id
    FROM Credit_Accounts
    WHERE user_id = v_mentor_id
    FOR UPDATE;

    -- 4. Transfer Credits Atomically
    -- Deduct from Learner
    UPDATE Credit_Accounts
    SET balance = balance - v_cost,
        total_spent = total_spent + v_cost,
        last_updated = CURRENT_TIMESTAMP
    WHERE account_id = v_learner_acc_id;

    -- Add to Mentor
    UPDATE Credit_Accounts
    SET balance = balance + v_cost,
        total_earned = total_earned + v_cost,
        last_updated = CURRENT_TIMESTAMP
    WHERE account_id = v_mentor_acc_id;

    -- 5. Record Double-Entry Credit Transactions
    INSERT INTO Credit_Transactions (
        account_id, session_id, transaction_type, amount, description
    ) VALUES (
        v_learner_acc_id, p_session_id, 'SPEND', v_cost,
        'Debited for completed session #' || p_session_id || ' (' || v_skill_name || ')'
    );

    INSERT INTO Credit_Transactions (
        account_id, session_id, transaction_type, amount, description
    ) VALUES (
        v_mentor_acc_id, p_session_id, 'EARN', v_cost,
        'Earned from teaching session #' || p_session_id || ' (' || v_skill_name || ')'
    );

    -- 6. Mark Session Completed
    UPDATE Sessions
    SET status = 'COMPLETED',
        completed_at = CURRENT_TIMESTAMP
    WHERE session_id = p_session_id;

    -- 7. Record Attendance for both users
    INSERT INTO Session_Attendance (session_id, user_id, attendance_status, joined_at, left_at)
    VALUES (p_session_id, v_learner_id, 'PRESENT', CURRENT_TIMESTAMP - NUMTODSINTERVAL(v_duration, 'HOUR'), CURRENT_TIMESTAMP);

    INSERT INTO Session_Attendance (session_id, user_id, attendance_status, joined_at, left_at)
    VALUES (p_session_id, v_mentor_id, 'PRESENT', CURRENT_TIMESTAMP - NUMTODSINTERVAL(v_duration, 'HOUR'), CURRENT_TIMESTAMP);

    -- 8. Check for Automated Certificate Issuance (>= 3 completed learning hours)
    v_total_hours := get_total_learning_hours(v_learner_id, v_skill_id);

    SELECT COUNT(*) INTO v_cert_count
    FROM Certificates
    WHERE user_id = v_learner_id AND skill_id = v_skill_id;

    IF v_total_hours >= 3.0 AND v_cert_count = 0 THEN
        v_cert_code := 'CERT-' || UPPER(SUBSTR(REGEXP_REPLACE(v_skill_name, '[^a-zA-Z]', ''), 1, 4)) || 
                       '-' || TO_CHAR(SYSDATE, 'YYYY') || '-' || LPAD(p_session_id, 4, '0');

        INSERT INTO Certificates (
            user_id, skill_id, certificate_code, issue_date, hours_completed, status
        ) VALUES (
            v_learner_id, v_skill_id, v_cert_code, SYSDATE, v_total_hours, 'ISSUED'
        );

        INSERT INTO Notifications (user_id, message, notification_type)
        VALUES (
            v_learner_id,
            'Congratulations! You have completed ' || v_total_hours || ' hours in ' || v_skill_name || 
            ' and been awarded Certificate: ' || v_cert_code,
            'CERTIFICATE_ISSUED'
        );
    END IF;

    -- 9. P2P Notifications
    INSERT INTO Notifications (user_id, message, notification_type)
    VALUES (
        v_learner_id,
        'Your session in ' || v_skill_name || ' has ended. ' || v_cost || ' credits transferred. Please rate your mentor!',
        'SESSION_COMPLETED'
    );

    INSERT INTO Notifications (user_id, message, notification_type)
    VALUES (
        v_mentor_id,
        'Session #' || p_session_id || ' completed! You received ' || v_cost || ' Skill Credits.',
        'SESSION_COMPLETED'
    );

    p_status_msg := 'Session completed successfully. ' || v_cost || ' credits transferred.';
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

-- ----------------------------------------------------------------------------
-- Procedure 3: book_session
-- Validates learner balance before booking and creates a session record.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE book_session(
    p_match_id       IN NUMBER,
    p_mentor_id      IN NUMBER,
    p_learner_id     IN NUMBER,
    p_skill_id       IN NUMBER,
    p_scheduled_date IN DATE,
    p_start_time     IN VARCHAR2,
    p_end_time       IN VARCHAR2,
    p_duration       IN NUMBER,
    p_credit_cost    IN NUMBER,
    p_session_id     OUT NUMBER
)
IS
    v_balance NUMBER(10,2);
    v_mentor_name VARCHAR2(100);
BEGIN
    -- Check for self booking
    IF p_mentor_id = p_learner_id THEN
        RAISE_APPLICATION_ERROR(-20020, 'You cannot book a session with yourself.');
    END IF;

    -- Verify learner balance
    v_balance := get_credit_balance(p_learner_id);
    IF v_balance < p_credit_cost THEN
        RAISE_APPLICATION_ERROR(-20021, 'Insufficient credits. Balance: ' || v_balance || ', Required: ' || p_credit_cost);
    END IF;

    -- Insert session
    INSERT INTO Sessions (
        match_id, mentor_id, learner_id, skill_id, 
        scheduled_date, start_time, end_time, duration, credit_cost, status
    ) VALUES (
        p_match_id, p_mentor_id, p_learner_id, p_skill_id,
        p_scheduled_date, p_start_time, p_end_time, p_duration, p_credit_cost, 'REQUESTED'
    ) RETURNING session_id INTO p_session_id;

    -- Update Match status if booked from a match
    IF p_match_id IS NOT NULL THEN
        UPDATE Matches SET status = 'SCHEDULED' WHERE match_id = p_match_id;
    END IF;

    -- Notify mentor
    SELECT name INTO v_mentor_name FROM Users WHERE user_id = p_mentor_id;

    INSERT INTO Notifications (user_id, message, notification_type)
    VALUES (
        p_mentor_id,
        'New session requested by student #' || p_learner_id || ' for ' || TO_CHAR(p_scheduled_date, 'YYYY-MM-DD') || ' at ' || p_start_time,
        'SESSION_REQUEST'
    );

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

COMMIT;
