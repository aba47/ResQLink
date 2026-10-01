"""
backend/database.py
Hardened Database Engine & Safe Parameterized Query Execution

Implements:
- Point 8: Lock down database (WAL mode, foreign keys, restricted permissions)
- Point 14: Use safe database queries to prevent SQL injection (whitelists + 100% parameterization)
"""

import sqlite3
import os
import re
from typing import Dict, Any, List, Optional, Set

DB_FILE = os.path.join(os.path.dirname(__file__), "disaster_server.db")

# Whitelist of permissible database tables to prevent SQL injection
ALLOWED_TABLES: Set[str] = {
    "users",
    "disasters",
    "emergency_requests",
    "disaster_reports",
    "shelters",
    "hospitals",
    "emergency_services",
    "resources",
    "emergency_contacts",
    "safe_zones",
}

COLUMN_NAME_REGEX = re.compile(r"^[a-zA-Z0-9_]{1,64}$")

def get_db() -> sqlite3.Connection:
    """
    Connect to database with hardened security pragmas:
    - foreign_keys = ON
    - journal_mode = WAL
    - synchronous = NORMAL
    """
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON;")
    conn.execute("PRAGMA journal_mode = WAL;")
    conn.execute("PRAGMA synchronous = NORMAL;")
    return conn

def secure_file_permissions(filepath: str):
    """Point 8: Restrict database file permissions (read/write only by owner)."""
    try:
        if os.path.exists(filepath):
            # Set 0o600 on UNIX systems; on Windows set read/write
            os.chmod(filepath, 0o600)
    except Exception:
        pass

def _ensure_column(cursor: sqlite3.Cursor, table: str, column: str, col_type: str):
    cursor.execute(f"PRAGMA table_info({table})")
    cols = {row["name"] for row in cursor.fetchall()}
    if column not in cols:
        cursor.execute(f"ALTER TABLE {table} ADD COLUMN {column} {col_type};")

def init_server_db():
    """Initialize database tables with security and auth columns."""
    conn = get_db()
    cursor = conn.cursor()

    cursor.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT UNIQUE,
        email TEXT UNIQUE,
        password_hash TEXT,
        role TEXT NOT NULL DEFAULT 'citizen',
        status TEXT DEFAULT 'active',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        version INTEGER DEFAULT 1,
        is_deleted INTEGER DEFAULT 0
      )
    ''')

    cursor.execute('''
      CREATE TABLE IF NOT EXISTS disasters (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        description TEXT,
        severity TEXT NOT NULL,
        status TEXT NOT NULL,
        location TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        radius_km REAL DEFAULT 0.0,
        affected_population INTEGER DEFAULT 0,
        reported_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        version INTEGER DEFAULT 1,
        source TEXT DEFAULT 'server',
        is_deleted INTEGER DEFAULT 0
      )
    ''')

    cursor.execute('''
      CREATE TABLE IF NOT EXISTS emergency_requests (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        user_name TEXT NOT NULL,
        phone TEXT NOT NULL,
        disaster_id TEXT,
        request_type TEXT NOT NULL,
        priority TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'Requested',
        description TEXT NOT NULL,
        people_count INTEGER DEFAULT 1,
        location TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        assigned_team TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        version INTEGER DEFAULT 1,
        source_device_id TEXT,
        is_deleted INTEGER DEFAULT 0
      )
    ''')

    cursor.execute('''
      CREATE TABLE IF NOT EXISTS disaster_reports (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        title TEXT NOT NULL,
        disaster_type TEXT NOT NULL,
        description TEXT NOT NULL,
        severity TEXT NOT NULL,
        location TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        casualties_count INTEGER DEFAULT 0,
        injured_count INTEGER DEFAULT 0,
        media_path TEXT,
        status TEXT DEFAULT 'submitted',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        version INTEGER DEFAULT 1,
        source_device_id TEXT,
        is_deleted INTEGER DEFAULT 0
      )
    ''')

    cursor.execute('''
      CREATE TABLE IF NOT EXISTS shelters (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        capacity INTEGER NOT NULL DEFAULT 0,
        current_occupancy INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'open',
        contact_person TEXT,
        contact_phone TEXT,
        facilities TEXT,
        supplies_status TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        version INTEGER DEFAULT 1,
        is_deleted INTEGER DEFAULT 0
      )
    ''')

    cursor.execute('''
      CREATE TABLE IF NOT EXISTS hospitals (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        emergency_contact TEXT NOT NULL,
        total_beds INTEGER DEFAULT 0,
        available_beds INTEGER DEFAULT 0,
        icu_beds_available INTEGER DEFAULT 0,
        blood_units_available INTEGER DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'operational',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        version INTEGER DEFAULT 1,
        is_deleted INTEGER DEFAULT 0
      )
    ''')

    cursor.execute('''
      CREATE TABLE IF NOT EXISTS emergency_services (
        id TEXT PRIMARY KEY,
        service_type TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        alternate_phone TEXT,
        coverage_area TEXT,
        status TEXT NOT NULL DEFAULT 'active',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        version INTEGER DEFAULT 1,
        is_deleted INTEGER DEFAULT 0
      )
    ''')

    cursor.execute('''
      CREATE TABLE IF NOT EXISTS resources (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 0,
        unit TEXT NOT NULL,
        location TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'available',
        shelter_id TEXT,
        updated_at TEXT NOT NULL,
        version INTEGER DEFAULT 1,
        is_deleted INTEGER DEFAULT 0
      )
    ''')

    cursor.execute('''
      CREATE TABLE IF NOT EXISTS emergency_contacts (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        name TEXT NOT NULL,
        relationship TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT,
        is_primary INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        version INTEGER DEFAULT 1,
        is_deleted INTEGER DEFAULT 0
      )
    ''')

    cursor.execute('''
      CREATE TABLE IF NOT EXISTS safe_zones (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        radius_meters REAL DEFAULT 100.0,
        safety_level TEXT NOT NULL,
        guidelines TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        version INTEGER DEFAULT 1,
        is_deleted INTEGER DEFAULT 0
      )
    ''')

    # Ensure schema migrations for existing tables
    _ensure_column(cursor, "users", "password_hash", "TEXT")
    _ensure_column(cursor, "users", "email", "TEXT")
    _ensure_column(cursor, "emergency_contacts", "user_id", "TEXT")

    # Create indexes for fast lookup and IDOR defense
    cursor.execute('CREATE INDEX IF NOT EXISTS idx_requests_user ON emergency_requests(user_id);')
    cursor.execute('CREATE INDEX IF NOT EXISTS idx_reports_user ON disaster_reports(user_id);')
    cursor.execute('CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);')
    cursor.execute('CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);')

    conn.commit()
    conn.close()
    secure_file_permissions(DB_FILE)


# --- Point 14: SQL Injection Proof Query Helpers ---

def assert_allowed_table(table: str) -> str:
    """Validate table name against strict whitelist."""
    clean_table = table.strip().lower()
    if clean_table not in ALLOWED_TABLES:
        raise ValueError(f"Security exception: Table '{table}' is not in allowed tables whitelist.")
    return clean_table

def assert_allowed_columns(columns: List[str]) -> List[str]:
    """Validate column names against identifier regex."""
    for col in columns:
        if not COLUMN_NAME_REGEX.match(col):
            raise ValueError(f"Security exception: Column name '{col}' contains illegal characters.")
    return columns

def safe_upsert(
    cursor: sqlite3.Cursor,
    table: str,
    data: Dict[str, Any],
    version: int,
    device_id: str
):
    """
    Injection-safe parameterized UPSERT helper:
    1. Validates table name against immutable whitelist.
    2. Validates column names against table metadata.
    3. Guarantees 100% parameterization of query values.
    """
    safe_table = assert_allowed_table(table)

    record = dict(data)
    record["version"] = version
    if "source_device_id" not in record or not record["source_device_id"]:
        record["source_device_id"] = device_id
    if "sync_status" in record:
        del record["sync_status"]

    # Retrieve valid columns from schema
    cursor.execute(f"PRAGMA table_info({safe_table})")
    valid_columns = {row["name"] for row in cursor.fetchall()}

    filtered_record = {k: v for k, v in record.items() if k in valid_columns}
    assert_allowed_columns(list(filtered_record.keys()))

    col_names = ", ".join(filtered_record.keys())
    placeholders = ", ".join(["?" for _ in filtered_record])
    updates = ", ".join([f"{k} = excluded.{k}" for k in filtered_record if k != "id"])

    sql = f"""
      INSERT INTO {safe_table} ({col_names})
      VALUES ({placeholders})
      ON CONFLICT(id) DO UPDATE SET {updates}
    """
    cursor.execute(sql, list(filtered_record.values()))
