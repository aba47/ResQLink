import unittest
from fastapi.testclient import TestClient
import json
import os
import sqlite3

from main import app
from database import DB_FILE, init_server_db

from security.auth import create_access_token

client = TestClient(app)

class TestDisasterReadyBackend(unittest.TestCase):
    def setUp(self):
        init_server_db()
        conn = sqlite3.connect(DB_FILE)
        cursor = conn.cursor()
        cursor.execute("DELETE FROM emergency_requests")
        cursor.execute("DELETE FROM disaster_reports")
        cursor.execute("DELETE FROM disasters")
        conn.commit()
        conn.close()
        self.token = create_access_token("test-user-1", "citizen", "Test User")
        self.headers = {"Authorization": f"Bearer {self.token}"}

    def test_health_check(self):
        response = client.get("/health")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["status"], "healthy")

    def test_push_sync_emergency_request(self):
        payload = {
            "id": "req-sync-1",
            "user_name": "Test User",
            "phone": "9998887776",
            "request_type": "rescue",
            "priority": "HIGH",
            "status": "Requested",
            "description": "Family stranded on rooftop",
            "location": "Sector 9",
            "people_count": 3,
            "created_at": "2026-10-01T10:00:00Z",
            "updated_at": "2026-10-01T10:00:00Z"
        }

        push_body = {
            "device_id": "phone-alpha",
            "items": [
                {
                    "id": "q-sync-1",
                    "entity_type": "emergency_request",
                    "entity_id": "req-sync-1",
                    "operation": "CREATE",
                    "payload": json.dumps(payload),
                    "version": 1,
                    "created_at": "2026-10-01T10:00:00Z"
                }
            ]
        }

        response = client.post("/sync/push", json=push_body, headers=self.headers)
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["synced_count"], 1)
        self.assertEqual(data["acknowledgements"][0]["status"], "SYNCED")
        self.assertEqual(data["acknowledgements"][0]["entity_id"], "req-sync-1")

    def test_pull_sync_retrieves_records(self):
        payload = {
            "id": "req-pull-1",
            "user_name": "Pull Requester",
            "phone": "1234567890",
            "request_type": "medical",
            "priority": "CRITICAL",
            "status": "Requested",
            "description": "Medical kit needed",
            "location": "Ward 2",
            "created_at": "2026-10-01T10:00:00Z",
            "updated_at": "2026-10-01T10:05:00Z"
        }
        client.post("/sync/push", json={
            "device_id": "phone-1",
            "items": [{
                "id": "q-1",
                "entity_type": "emergency_request",
                "entity_id": "req-pull-1",
                "operation": "CREATE",
                "payload": json.dumps(payload),
                "version": 1,
                "created_at": "2026-10-01T10:00:00Z"
            }]
        }, headers=self.headers)

        pull_response = client.post("/sync/pull", json={
            "device_id": "phone-2",
            "since_timestamp": "2026-10-01T09:00:00Z"
        }, headers=self.headers)
        self.assertEqual(pull_response.status_code, 200)
        pull_data = pull_response.json()
        requests = pull_data["emergency_requests"]
        self.assertEqual(len(requests), 1)
        self.assertEqual(requests[0]["id"], "req-pull-1")

    def test_duplicate_prevention_on_push(self):
        payload = {
            "id": "req-dup-1",
            "user_name": "Same Requester",
            "phone": "1111111111",
            "request_type": "food_water",
            "priority": "LOW",
            "status": "Requested",
            "description": "Need dry rations",
            "location": "Shelter A",
            "created_at": "2026-10-01T10:00:00Z",
            "updated_at": "2026-10-01T10:00:00Z"
        }
        push_body = {
            "device_id": "phone-1",
            "items": [{
                "id": "q-dup",
                "entity_type": "emergency_request",
                "entity_id": "req-dup-1",
                "operation": "CREATE",
                "payload": json.dumps(payload),
                "version": 1,
                "created_at": "2026-10-01T10:00:00Z"
            }]
        }

        # First push
        res1 = client.post("/sync/push", json=push_body, headers=self.headers)
        self.assertEqual(res1.json()["acknowledgements"][0]["status"], "SYNCED")

        # Repeat push (retry or network hiccup)
        res2 = client.post("/sync/push", json=push_body, headers=self.headers)
        self.assertEqual(res2.json()["acknowledgements"][0]["status"], "SYNCED")

        # Verify no duplicate in database
        conn = sqlite3.connect(DB_FILE)
        cursor = conn.cursor()
        cursor.execute("SELECT count(*) FROM emergency_requests WHERE id = 'req-dup-1'")
        count = cursor.fetchone()[0]
        conn.close()
        self.assertEqual(count, 1)

if __name__ == "__main__":
    unittest.main()
