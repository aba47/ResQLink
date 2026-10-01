"""
backend/backup.py
Automated Database Backup and Restore Engine

Implements:
- Point 19: Back up your data and test restoring it
- Uses SQLite online backup API for zero-downtime, transactionally consistent snapshots
- Automated backup integrity verification via PRAGMA integrity_check
"""

import sqlite3
import os
import shutil
from datetime import datetime, timezone
from typing import Optional, Tuple

BACKUP_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "backups"))
DEFAULT_DB_FILE = os.path.abspath(os.path.join(os.path.dirname(__file__), "disaster_server.db"))

def init_backup_dir():
    os.makedirs(BACKUP_DIR, exist_ok=True)

def create_backup(source_db_path: Optional[str] = None, dest_dir: Optional[str] = None) -> str:
    """
    Perform an atomic online backup of the SQLite database.
    Does not lock writers or disrupt active sync operations.
    """
    init_backup_dir()
    src_path = source_db_path or DEFAULT_DB_FILE
    target_dir = dest_dir or BACKUP_DIR

    timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    backup_filename = f"disaster_server_backup_{timestamp}.db"
    dest_path = os.path.join(target_dir, backup_filename)

    src_conn = sqlite3.connect(src_path)
    dest_conn = sqlite3.connect(dest_path)

    try:
        # Atomic backup using native SQLite backup API
        src_conn.backup(dest_conn, pages=100, sleep=0.01)
    finally:
        dest_conn.close()
        src_conn.close()

    # Validate integrity of the newly created backup
    is_valid, msg = verify_backup_integrity(dest_path)
    if not is_valid:
        if os.path.exists(dest_path):
            os.remove(dest_path)
        raise RuntimeError(f"Backup created but failed integrity check: {msg}")

    return dest_path

def verify_backup_integrity(backup_path: str) -> Tuple[bool, str]:
    """Verify SQLite database integrity with PRAGMA integrity_check."""
    if not os.path.exists(backup_path):
        return False, "Backup file does not exist"

    try:
        conn = sqlite3.connect(backup_path)
        cursor = conn.cursor()
        cursor.execute("PRAGMA integrity_check;")
        row = cursor.fetchone()
        conn.close()
        if row and row[0] == "ok":
            return True, "Integrity OK"
        return False, f"Integrity check failed: {row}"
    except Exception as e:
        return False, str(e)

def restore_backup(backup_path: str, target_db_path: Optional[str] = None) -> bool:
    """
    Safely restore database from a verified backup.
    Creates a pre-restore safety copy of the current database before overwriting.
    """
    target = target_db_path or DEFAULT_DB_FILE

    # 1. Verify backup integrity first
    is_valid, msg = verify_backup_integrity(backup_path)
    if not is_valid:
        raise ValueError(f"Cannot restore: Backup is corrupt or invalid ({msg})")

    # 2. Safety copy of current DB if exists
    if os.path.exists(target):
        safety_copy = f"{target}.prerestore_safety"
        shutil.copy2(target, safety_copy)

    # 3. Restore using atomic SQLite backup API to the target file
    src_conn = sqlite3.connect(backup_path)
    dest_conn = sqlite3.connect(target)
    try:
        src_conn.backup(dest_conn)
    finally:
        dest_conn.close()
        src_conn.close()

    return True
