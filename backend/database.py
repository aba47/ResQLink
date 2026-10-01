import sqlite3
import os
from typing import Dict, Any, List, Optional

DB_FILE = os.path.join(os.path.dirname(__file__), "disaster_server.db")

def get_db():
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    return conn

def init_server_db():
    conn = get_db()
    cursor = conn.cursor()

    cursor.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        role TEXT NOT NULL DEFAULT 'citizen',
        email TEXT,
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

    conn.commit()
    conn.close()
