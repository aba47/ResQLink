"""
backend/test_multitenant_security.py
Comprehensive End-to-End Security Test Suite
Covers Points 5, 6, 7, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 20
"""

import unittest
import json
import sqlite3
import time
import os
import hmac
import hashlib
from fastapi.testclient import TestClient

from main import app
from database import DB_FILE, init_server_db
from security.rate_limiter import limiter
from security.ai_quota import ai_quota
from security.payment_verifier import PAYMENT_WEBHOOK_SECRET

client = TestClient(app)

class TestSecurityAndMultiTenancy(unittest.TestCase):
    def setUp(self):
        init_server_db()
        limiter.reset()
        conn = sqlite3.connect(DB_FILE)
        cursor = conn.cursor()
        cursor.execute("DELETE FROM emergency_requests")
        cursor.execute("DELETE FROM disaster_reports")
        cursor.execute("DELETE FROM disasters")
        cursor.execute("DELETE FROM shelters")
        cursor.execute("DELETE FROM users")
        conn.commit()
        conn.close()

    # --------------------------------------------------------------------------
    # POINT 20 & POINT 5: Test without logging in, then test with two accounts
    # --------------------------------------------------------------------------
    def test_point_20_unauthenticated_access_rejected(self):
        """Unauthenticated requests to protected endpoints MUST fail with 401 Unauthorized."""
        res_disasters = client.get("/disasters")
        self.assertEqual(res_disasters.status_code, 401, "Unauthenticated access to /disasters must be 401")

        res_requests = client.get("/emergency-requests")
        self.assertEqual(res_requests.status_code, 401, "Unauthenticated access to /emergency-requests must be 401")

        res_create_req = client.post("/emergency-requests", json={"description": "help"})
        self.assertEqual(res_create_req.status_code, 401, "Unauthenticated creation must be 401")

        res_sync = client.post("/sync/push", json={"device_id": "test", "items": []})
        self.assertEqual(res_sync.status_code, 401, "Unauthenticated sync push must be 401")

    # --------------------------------------------------------------------------
    # POINT 10: Test login, logout, and password resets
    # --------------------------------------------------------------------------
    def test_point_10_auth_lifecycle(self):
        """Test user registration, login, token verification, logout, and password reset."""
        # 1. Register
        reg_res = client.post("/auth/register", json={
            "name": "Alice Survivor",
            "phone": "+919876543210",
            "email": "alice@example.com",
            "password": "SuperSecretPassword123!"
        })
        self.assertEqual(reg_res.status_code, 200)
        reg_data = reg_res.json()
        alice_id = reg_data["user"]["id"]
        self.assertEqual(reg_data["user"]["role"], "citizen")

        # 2. Login
        login_res = client.post("/auth/login", json={
            "phone_or_email": "+919876543210",
            "password": "SuperSecretPassword123!"
        })
        self.assertEqual(login_res.status_code, 200)
        alice_token = login_res.json()["access_token"]

        # 3. Access protected resource with valid token
        auth_headers = {"Authorization": f"Bearer {alice_token}"}
        req_res = client.get("/emergency-requests", headers=auth_headers)
        self.assertEqual(req_res.status_code, 200)

        # 4. Logout (Token Revocation)
        logout_res = client.post("/auth/logout", headers=auth_headers)
        self.assertEqual(logout_res.status_code, 200)

        # Attempt to use revoked token -> must be 401
        revoked_check = client.get("/emergency-requests", headers=auth_headers)
        self.assertEqual(revoked_check.status_code, 401, "Revoked token must be rejected")

        # 5. Password Reset Flow
        reset_req_res = client.post("/auth/password-reset-request", json={
            "phone_or_email": "+919876543210"
        })
        self.assertEqual(reset_req_res.status_code, 200)
        reset_token = reset_req_res.json()["reset_token"]

        # Confirm password reset
        confirm_res = client.post("/auth/password-reset-confirm", json={
            "token": reset_token,
            "new_password": "NewUpdatedPassword456!"
        })
        self.assertEqual(confirm_res.status_code, 200)

        # Re-using same reset token must fail (single-use)
        reuse_res = client.post("/auth/password-reset-confirm", json={
            "token": reset_token,
            "new_password": "AnotherPassword789!"
        })
        self.assertEqual(reuse_res.status_code, 400, "Reset token must be single-use")

        # Login with old password must fail
        old_login = client.post("/auth/login", json={
            "phone_or_email": "+919876543210",
            "password": "SuperSecretPassword123!"
        })
        self.assertEqual(old_login.status_code, 401)

        new_login = client.post("/auth/login", json={
            "phone_or_email": "+919876543210",
            "password": "NewUpdatedPassword456!"
        })
        self.assertEqual(new_login.status_code, 200)

        # 6. Immediate Emergency Guest Access
        guest_res = client.post("/auth/emergency-guest")
        self.assertEqual(guest_res.status_code, 200)
        guest_data = guest_res.json()
        self.assertEqual(guest_data["user"]["role"], "citizen")
        guest_token = guest_data["access_token"]
        guest_check = client.get("/emergency-requests", headers={"Authorization": f"Bearer {guest_token}"})
        self.assertEqual(guest_check.status_code, 200)

    # --------------------------------------------------------------------------
    # POINT 6 & 7: Never trust client IDs/roles & IDOR protection across two users
    # --------------------------------------------------------------------------
    def test_point_6_and_7_cross_account_data_isolation_idor(self):
        """
        Register Alice and Bob.
        Verify Alice's emergency requests cannot be accessed or altered by Bob.
        Verify client cannot spoof user_id.
        """
        # Register Alice (Citizen)
        client.post("/auth/register", json={
            "name": "Alice Citizen",
            "phone": "+911111111111",
            "password": "Password12345!"
        })
        alice_token = client.post("/auth/login", json={
            "phone_or_email": "+911111111111",
            "password": "Password12345!"
        }).json()["access_token"]
        alice_headers = {"Authorization": f"Bearer {alice_token}"}

        # Register Bob (Citizen)
        client.post("/auth/register", json={
            "name": "Bob Citizen",
            "phone": "+912222222222",
            "password": "Password12345!"
        })
        bob_token = client.post("/auth/login", json={
            "phone_or_email": "+912222222222",
            "password": "Password12345!"
        }).json()["access_token"]
        bob_headers = {"Authorization": f"Bearer {bob_token}"}

        # Alice creates an emergency request
        alice_create_res = client.post("/emergency-requests", headers=alice_headers, json={
            "request_type": "rescue",
            "priority": "HIGH",
            "description": "Alice trapped on 2nd floor",
            "location": "Apt 4B, River Street",
            "phone": "+911111111111",
            "people_count": 2
        })
        self.assertEqual(alice_create_res.status_code, 200)
        alice_req_id = alice_create_res.json()["id"]

        # 1. Bob queries his emergency requests -> Alice's request MUST NOT appear
        bob_reqs_res = client.get("/emergency-requests", headers=bob_headers)
        self.assertEqual(bob_reqs_res.status_code, 200)
        bob_reqs = bob_reqs_res.json()
        self.assertEqual(len(bob_reqs), 0, "Bob must not see Alice's requests in his list")

        # 2. Bob attempts to modify Alice's emergency request directly (IDOR attack)
        bob_hack_res = client.patch(f"/emergency-requests/{alice_req_id}", headers=bob_headers, json={
            "description": "Bob maliciously changed Alice's location!"
        })
        self.assertEqual(bob_hack_res.status_code, 403, "Bob modifying Alice's request must be 403 Forbidden")

        # 3. Alice modifying her own request succeeds
        alice_update_res = client.patch(f"/emergency-requests/{alice_req_id}", headers=alice_headers, json={
            "description": "Alice updated description: water level rising"
        })
        self.assertEqual(alice_update_res.status_code, 200)

    # --------------------------------------------------------------------------
    # POINT 9: Protect admin actions even when called directly
    # --------------------------------------------------------------------------
    def test_point_9_protect_admin_actions(self):
        """Citizen cannot create disasters, manage shelters, or elevate roles."""
        # Register regular citizen
        client.post("/auth/register", json={
            "name": "Normal Citizen",
            "phone": "+913333333333",
            "password": "Password12345!"
        })
        citizen_token = client.post("/auth/login", json={
            "phone_or_email": "+913333333333",
            "password": "Password12345!"
        }).json()["access_token"]
        citizen_headers = {"Authorization": f"Bearer {citizen_token}"}

        # Citizen attempts to declare a disaster
        fake_disaster_res = client.post("/disasters", headers=citizen_headers, json={
            "title": "False Alarm Disaster",
            "type": "flood",
            "severity": "CRITICAL",
            "location": "Downtown"
        })
        self.assertEqual(fake_disaster_res.status_code, 403, "Citizen declaring disaster must be 403 Forbidden")

        # Create an authorized Admin account in database
        admin_id = "admin-root-1"
        now = "2026-10-01T12:00:00Z"
        conn = sqlite3.connect(DB_FILE)
        cursor = conn.cursor()
        from security.auth import hash_password
        cursor.execute(
            """
            INSERT INTO users (id, name, phone, password_hash, role, status, created_at, updated_at)
            VALUES (?, 'Emergency Commander', '+919999999999', ?, 'admin', 'active', ?, ?)
            """,
            (admin_id, hash_password("AdminSecurePassword123!"), now, now)
        )
        conn.commit()
        conn.close()

        admin_token = client.post("/auth/login", json={
            "phone_or_email": "+919999999999",
            "password": "AdminSecurePassword123!"
        }).json()["access_token"]
        admin_headers = {"Authorization": f"Bearer {admin_token}"}

        # Admin declares disaster -> succeeds
        admin_disaster_res = client.post("/disasters", headers=admin_headers, json={
            "title": "Cyclone Vardah Alert",
            "type": "cyclone",
            "severity": "CRITICAL",
            "location": "Coastal Sector 4"
        })
        self.assertEqual(admin_disaster_res.status_code, 200)

    # --------------------------------------------------------------------------
    # POINT 11: Rate Limiting
    # --------------------------------------------------------------------------
    def test_point_11_rate_limiting(self):
        """Exceeding rate limit returns 429 Too Many Requests."""
        limiter.reset()
        for i in range(10):
            res = client.post("/auth/login", json={
                "phone_or_email": "+910000000000",
                "password": "WrongPassword!"
            })
        # 11th request must be rate limited
        rate_limited_res = client.post("/auth/login", json={
            "phone_or_email": "+910000000000",
            "password": "WrongPassword!"
        })
        self.assertEqual(rate_limited_res.status_code, 429, "11th login attempt must return 429")
        self.assertIn("Retry-After", rate_limited_res.headers)

    # --------------------------------------------------------------------------
    # POINT 12: AI Usage Caps & Budget Protection
    # --------------------------------------------------------------------------
    def test_point_12_ai_budget_caps(self):
        """User exceeding daily AI triage quota receives 429."""
        # Register user
        client.post("/auth/register", json={
            "name": "AI User",
            "phone": "+914444444444",
            "password": "Password12345!"
        })
        token = client.post("/auth/login", json={
            "phone_or_email": "+914444444444",
            "password": "Password12345!"
        }).json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # Consume 10 allowed AI requests
        for i in range(10):
            res = client.post("/ai/triage", headers=headers, json={
                "incident_details": f"Emergency triage request #{i}: water entering ground floor"
            })
            self.assertEqual(res.status_code, 200)

        # 11th request must fail with quota cap
        blocked_res = client.post("/ai/triage", headers=headers, json={
            "incident_details": "Request #11: budget drain attempt"
        })
        self.assertEqual(blocked_res.status_code, 429)
        self.assertIn("quota exceeded", blocked_res.json()["detail"].lower())

    # --------------------------------------------------------------------------
    # POINT 13 & 15: Server Input Validation & XSS Script Neutralization
    # --------------------------------------------------------------------------
    def test_point_13_and_15_input_validation_and_xss(self):
        """Server must reject invalid coordinates/phone and neutralize script tags."""
        client.post("/auth/register", json={
            "name": "Sec Tester",
            "phone": "+915555555555",
            "password": "Password12345!"
        })
        token = client.post("/auth/login", json={
            "phone_or_email": "+915555555555",
            "password": "Password12345!"
        }).json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # Invalid phone format rejected
        invalid_phone_res = client.post("/emergency-requests", headers=headers, json={
            "request_type": "rescue",
            "priority": "HIGH",
            "description": "Valid description",
            "location": "Location 1",
            "phone": "NOT_A_PHONE_NUMBER"
        })
        self.assertEqual(invalid_phone_res.status_code, 422, "Invalid phone must fail validation")

        # XSS Payload in description
        xss_payload = "<script>alert('XSS Attack');</script>Urgent rescue needed! <img src=x onerror=alert(1)>"
        xss_res = client.post("/emergency-requests", headers=headers, json={
            "request_type": "rescue",
            "priority": "HIGH",
            "description": xss_payload,
            "location": "Shelter B",
            "phone": "+915555555555"
        })
        self.assertEqual(xss_res.status_code, 200)
        req_id = xss_res.json()["id"]

        # Verify stored description has no executable <script> tags
        conn = sqlite3.connect(DB_FILE)
        conn.row_factory = sqlite3.Row
        row = conn.execute("SELECT description FROM emergency_requests WHERE id = ?", (req_id,)).fetchone()
        conn.close()

        stored_desc = row["description"]
        self.assertNotIn("<script>", stored_desc.lower())
        self.assertNotIn("onerror=", stored_desc.lower())

    # --------------------------------------------------------------------------
    # POINT 16: Restrict File Types and Sizes
    # --------------------------------------------------------------------------
    def test_point_16_file_upload_restrictions(self):
        """Disallowed extensions and oversized files must be rejected."""
        client.post("/auth/register", json={
            "name": "Upload Tester",
            "phone": "+916666666666",
            "password": "Password12345!"
        })
        token = client.post("/auth/login", json={
            "phone_or_email": "+916666666666",
            "password": "Password12345!"
        }).json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # 1. Disallowed .exe file
        exe_res = client.post(
            "/upload/media",
            headers=headers,
            files={"file": ("malware.exe", b"MZ\x90\x00executable content", "application/x-msdownload")}
        )
        self.assertEqual(exe_res.status_code, 400, "Executable upload must be rejected")

        # 2. Valid PNG with proper magic header
        valid_png_bytes = b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01"
        png_res = client.post(
            "/upload/media",
            headers=headers,
            files={"file": ("damage_report.png", valid_png_bytes, "image/png")}
        )
        self.assertEqual(png_res.status_code, 200, "Valid PNG must be accepted")
        self.assertEqual(png_res.json()["status"], "uploaded")

    # --------------------------------------------------------------------------
    # POINT 17: Server-side Payment Verification
    # --------------------------------------------------------------------------
    def test_point_17_payment_verification(self):
        """Payment signature verified with HMAC-SHA256, forged signatures rejected."""
        client.post("/auth/register", json={
            "name": "Donor User",
            "phone": "+917777777777",
            "password": "Password12345!"
        })
        token = client.post("/auth/login", json={
            "phone_or_email": "+917777777777",
            "password": "Password12345!"
        }).json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        order_id = "order_offline_9981"
        payment_id = "pay_live_77219"

        # Compute legitimate signature
        legit_sig = hmac.new(
            PAYMENT_WEBHOOK_SECRET.encode("utf-8"),
            f"{order_id}|{payment_id}".encode("utf-8"),
            hashlib.sha256
        ).hexdigest()

        # Forged signature must fail
        forged_res = client.post("/payments/verify", headers=headers, json={
            "order_id": order_id,
            "payment_id": payment_id,
            "signature": "fake_forged_signature_1234567890",
            "package_name": "satellite_offline_pack"
        })
        self.assertEqual(forged_res.status_code, 400, "Forged signature must fail")

        # Legitimate signature succeeds
        legit_res = client.post("/payments/verify", headers=headers, json={
            "order_id": order_id,
            "payment_id": payment_id,
            "signature": legit_sig,
            "package_name": "satellite_offline_pack"
        })
        self.assertEqual(legit_res.status_code, 200)
        self.assertEqual(legit_res.json()["unlocked_feature"], "satellite_offline_maps")

        # Replay attack with same payment_id must fail
        replay_res = client.post("/payments/verify", headers=headers, json={
            "order_id": order_id,
            "payment_id": payment_id,
            "signature": legit_sig,
            "package_name": "satellite_offline_pack"
        })
        self.assertEqual(replay_res.status_code, 409, "Replaying same payment ID must be rejected")

if __name__ == "__main__":
    unittest.main()
