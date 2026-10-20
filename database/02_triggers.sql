-- ============================================================================
-- SkillSwap - Campus Skill Exchange Platform
-- Triggers Script (02_triggers.sql)
-- DBMS Project by Mogalapalli Rohan (24BCE2622) & N. Sai Hemanth (24BCE2400)
-- Target: Oracle Database 21c XE
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Trigger 1: trg_user_after_insert
-- Automatically provisions a Skill Credit wallet with 50 welcome credits 
-- and sends a welcome notification when a new student registers.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_user_after_insert
AFTER INSERT ON Users
FOR EACH ROW
DECLARE
    v_acc_id NUMBER;
BEGIN
    -- 1. Create Credit Account with 50 welcome credits
    INSERT INTO Credit_Accounts (
        user_id, balance, total_earned, total_spent, last_updated
    ) VALUES (
        :NEW.user_id, 50.00, 50.00, 0.00, CURRENT_TIMESTAMP
    ) RETURNING account_id INTO v_acc_id;

    -- 2. Record initial bonus transaction in audit ledger
    INSERT INTO Credit_Transactions (
        account_id, session_id, transaction_type, amount, description
    ) VALUES (
        v_acc_id, NULL, 'BONUS', 50.00, 'Welcome bonus credits for campus registration'
    );

    -- 3. Push a welcome notification
    INSERT INTO Notifications (
        user_id, message, notification_type, is_read
    ) VALUES (
        :NEW.user_id, 
        'Welcome to SkillSwap, ' || :NEW.name || '! 50 Skill Credits have been deposited into your wallet.',
        'CREDIT_UPDATE',
        0
    );
END;
/

-- ----------------------------------------------------------------------------
-- Trigger 2: trg_credit_account_touch
-- Automatically timestamps last_updated when wallet balance changes.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_credit_account_touch
BEFORE UPDATE ON Credit_Accounts
FOR EACH ROW
BEGIN
    :NEW.last_updated := CURRENT_TIMESTAMP;
END;
/

-- ----------------------------------------------------------------------------
-- Trigger 3: trg_check_session_integrity
-- Validates that a user cannot book a session with themselves and that session 
-- duration and credit cost are positive.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_check_session_integrity
BEFORE INSERT OR UPDATE ON Sessions
FOR EACH ROW
BEGIN
    IF :NEW.mentor_id = :NEW.learner_id THEN
        RAISE_APPLICATION_ERROR(-20001, 'A student cannot mentor themselves in a session.');
    END IF;

    IF :NEW.credit_cost < 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Credit cost cannot be negative.');
    END IF;

    IF :NEW.duration <= 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Session duration must be greater than zero hours.');
    END IF;
END;
/

-- ----------------------------------------------------------------------------
-- Trigger 4: trg_prevent_self_match
-- Ensures a student cannot be matched to their own skill request.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_prevent_self_match
BEFORE INSERT OR UPDATE ON Matches
FOR EACH ROW
DECLARE
    v_requester_id NUMBER;
BEGIN
    SELECT user_id INTO v_requester_id
    FROM Skill_Requests
    WHERE request_id = :NEW.request_id;

    IF v_requester_id = :NEW.mentor_id THEN
        RAISE_APPLICATION_ERROR(-20004, 'A user cannot be matched to fulfill their own skill request.');
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        NULL; -- Handled by FK constraint
END;
/

-- ----------------------------------------------------------------------------
-- Trigger 5: trg_validate_rating
-- Ensures ratings can only be submitted for COMPLETED sessions by the learner.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_validate_rating
BEFORE INSERT ON Ratings
FOR EACH ROW
DECLARE
    v_status     VARCHAR2(20);
    v_learner_id NUMBER;
    v_mentor_id  NUMBER;
BEGIN
    SELECT status, learner_id, mentor_id 
    INTO v_status, v_learner_id, v_mentor_id
    FROM Sessions
    WHERE session_id = :NEW.session_id;

    IF v_status <> 'COMPLETED' THEN
        RAISE_APPLICATION_ERROR(-20005, 'Ratings can only be submitted for completed sessions.');
    END IF;

    IF :NEW.learner_id <> v_learner_id THEN
        RAISE_APPLICATION_ERROR(-20006, 'Only the learner who attended the session can submit feedback.');
    END IF;

    IF :NEW.mentor_id <> v_mentor_id THEN
        RAISE_APPLICATION_ERROR(-20007, 'Rating mentor does not match session mentor.');
    END IF;
END;
/

COMMIT;
