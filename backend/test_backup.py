"""
backend/test_backup.py
Test Suite for Point 19: Back up your data and test restoring it
"""

import unittest
import sqlite3
import os
import tempfile
import uuid

from backup import create_backup, restore_backup, verify_backup_integrity
from database import init_server_db, get_db

class TestDatabaseBackupRestore(unittest.TestCase):
    def setUp(self):
        init_server_db()
        self.conn = get_db()
        self.cursor = self.conn.cursor()

    def tearDown(self):
        self.conn.close()

    def test_backup_and_restore_cycle(self):
        # 1. Insert a distinctive marker record into disasters
        marker_id = f"test-marker-{uuid.uuid4().hex[:8]}"
        self.cursor.execute(
            """
            INSERT OR REPLACE INTO disasters (id, title, type, severity, status, location, reported_at, updated_at)
            VALUES (?, 'Pre-Backup Test Disaster', 'flood', 'HIGH', 'active', 'Zone 1', '2026-10-01T12:00:00Z', '2026-10-01T12:00:00Z')
            """,
            (marker_id,)
        )
        self.conn.commit()

        # 2. Create online backup
        with tempfile.TemporaryDirectory() as temp_dir:
            backup_file = create_backup(dest_dir=temp_dir)
            self.assertTrue(os.path.exists(backup_file), "Backup file should be created")

            # 3. Verify backup file integrity
            is_valid, msg = verify_backup_integrity(backup_file)
            self.assertTrue(is_valid, f"Backup file integrity failed: {msg}")

            # 4. Now simulate disaster/accidental deletion on the main database
            self.cursor.execute("DELETE FROM disasters WHERE id = ?", (marker_id,))
            self.conn.commit()

            # Confirm it's gone
            self.cursor.execute("SELECT id FROM disasters WHERE id = ?", (marker_id,))
            self.assertIsNone(self.cursor.fetchone(), "Marker record should be deleted")

            # 5. Restore from backup
            self.conn.close() # Close current connection before restore
            restore_success = restore_backup(backup_file)
            self.assertTrue(restore_success, "Restore operation should succeed")

            # 6. Verify data is fully recovered!
            new_conn = get_db()
            new_cursor = new_conn.cursor()
            new_cursor.execute("SELECT id, title FROM disasters WHERE id = ?", (marker_id,))
            restored_row = new_cursor.fetchone()
            self.assertIsNotNone(restored_row, "Marker record must be restored from backup")
            self.assertEqual(restored_row["title"], "Pre-Backup Test Disaster")

            # Clean up marker
            new_cursor.execute("DELETE FROM disasters WHERE id = ?", (marker_id,))
            new_conn.commit()
            new_conn.close()

            # Re-open conn for tearDown
            self.conn = get_db()

if __name__ == "__main__":
    unittest.main()
