import oracledb
import os

DB_USER = os.getenv("ORACLE_USER", "skillswap")
DB_PASSWORD = os.getenv("ORACLE_PASSWORD", "skillswap123")
DB_DSN = os.getenv("ORACLE_DSN", "localhost:1521/xepdb1")

def get_connection():
    """Returns an active Oracle DB connection."""
    return oracledb.connect(user=DB_USER, password=DB_PASSWORD, dsn=DB_DSN)

def rows_to_dicts(cursor):
    """Converts fetched cursor rows to list of dicts with lowercase keys."""
    columns = [col[0].lower() for col in cursor.description]
    return [dict(zip(columns, row)) for row in cursor.fetchall()]

def row_to_dict(cursor, row):
    """Converts a single cursor row to dict with lowercase keys."""
    if not row:
        return None
    columns = [col[0].lower() for col in cursor.description]
    return dict(zip(columns, row))

def query_all(sql, params=None):
    """Executes a SELECT query and returns all rows as dicts."""
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(sql, params or {})
            return rows_to_dicts(cur)
    finally:
        conn.close()

def query_one(sql, params=None):
    """Executes a SELECT query and returns a single row as dict."""
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(sql, params or {})
            row = cur.fetchone()
            return row_to_dict(cur, row)
    finally:
        conn.close()

def execute_dml(sql, params=None):
    """Executes an INSERT, UPDATE, or DELETE statement with commit."""
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(sql, params or {})
            conn.commit()
            return cur.rowcount
    finally:
        conn.close()

def call_complete_session(session_id):
    """Calls the PL/SQL stored procedure complete_session(session_id, out_msg)."""
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            out_msg = cur.var(oracledb.STRING)
            cur.callproc("complete_session", [session_id, out_msg])
            conn.commit()
            return True, out_msg.getvalue()
    except Exception as e:
        conn.rollback()
        return False, str(e)
    finally:
        conn.close()

def call_match_mentors(request_id):
    """Calls the PL/SQL stored procedure match_mentors_for_request(request_id, out_count)."""
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            out_count = cur.var(oracledb.NUMBER)
            cur.callproc("match_mentors_for_request", [request_id, out_count])
            conn.commit()
            return True, int(out_count.getvalue() or 0)
    except Exception as e:
        conn.rollback()
        return False, str(e)
    finally:
        conn.close()
