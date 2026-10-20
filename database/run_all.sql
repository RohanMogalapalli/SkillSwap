-- ============================================================================
-- SkillSwap - Master SQL*Plus Installation Script (run_all.sql)
-- DBMS Project by Mogalapalli Rohan (24BCE2622) & N. Sai Hemanth (24BCE2400)
-- Target: Oracle Database 21c XE
-- Run via: sqlplus skillswap/skillswap123@localhost:1521/xepdb1 @database/run_all.sql
-- ============================================================================

SET DEFINE OFF;
SET ECHO ON;
SET FEEDBACK ON;
SET SERVEROUTPUT ON;
WHENEVER SQLERROR CONTINUE;

PROMPT [1/6] Executing 01_schema.sql (Creating 15 Relational Tables)...
@c:/projects/SkillSwap/database/01_schema.sql

PROMPT [2/6] Executing 02_triggers.sql (Creating Triggers)...
@c:/projects/SkillSwap/database/02_triggers.sql

PROMPT [3/6] Executing 03_functions_procedures.sql (Creating Stored Procedures and Functions)...
@c:/projects/SkillSwap/database/03_functions_procedures.sql

PROMPT [4/6] Executing 04_views.sql (Creating Database Views)...
@c:/projects/SkillSwap/database/04_views.sql

PROMPT [5/6] Executing 05_seed_data.sql (Inserting Realistic Campus Seed Data)...
@c:/projects/SkillSwap/database/05_seed_data.sql

PROMPT [6/6] Executing 06_test_queries.sql (Running Analytical Verification Queries)...
@c:/projects/SkillSwap/database/06_test_queries.sql

PROMPT
PROMPT ============================================================================
PROMPT SkillSwap Database Installation and Seed Completed Successfully!
PROMPT ============================================================================
EXIT;
