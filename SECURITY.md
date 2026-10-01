# Security Architecture & 20-Point Compliance Guide

This document details the complete 20-point security standard implemented in **ResQLink / DisasterReady**.

---

## 20-Point Compliance Matrix

| # | Security Requirement | Status | Implementation Details |
|---|----------------------|:------:|------------------------|
| **1** | Keep secret API keys out of frontend | **Implemented** | All AI and payment keys remain exclusively on FastAPI backend. Frontend uses [`EnvConfig`](file:///d:/APP/Android/lib/core/config/env_config.dart) with `--dart-define` for public URLs only. |
| **2** | Keep `.env` files out of Git and public folders | **Implemented** | Added `.env`, `.env.*`, `*.pem`, `*.keystore`, `*.jks` to [`.gitignore`](file:///d:/APP/Android/.gitignore). Created safe [`.env.example`](file:///d:/APP/Android/.env.example). |
| **3** | Scan Git history for leaked secrets | **Implemented** | Created [`scripts/scan_secrets.py`](file:///d:/APP/Android/scripts/scan_secrets.py) with automated regex scans across full git history & working tree. Verified clean. |
| **4** | Rotate any keys you have accidentally exposed | **Implemented** | Zero active production keys were exposed in git history. Standard key rotation protocols established below. |
| **5** | Check permissions on server on every request | **Implemented** | [`get_current_user`](file:///d:/APP/Android/backend/security/auth.py) and [`require_role`](file:///d:/APP/Android/backend/security/auth.py) dependencies verify signed JWT bearer tokens on all protected endpoints. |
| **6** | Never trust client user IDs, roles, or prices | **Implemented** | Server overrides incoming `user_id` and `user_name` from verified token claims. Self-registration defaults strictly to `citizen`. Pricing ledger is server-authoritative. |
| **7** | Ensure users cannot access each other's data | **Implemented** | IDOR protection via [`check_ownership`](file:///d:/APP/Android/backend/security/auth.py). Citizens can only view/update their own emergency requests. |
| **8** | Lock down database and private file storage | **Implemented** | SQLite configured with `WAL` journal mode and `foreign_keys = ON`. File permissions restricted. Media storage paths protected from traversal. |
| **9** | Protect admin actions even when called directly | **Implemented** | Admin actions (`/disasters`, `/shelters`, `/admin/users/{id}/role`, `/admin/backup`) require `@require_role(["admin"])` on the server. |
| **10** | Test login, logout, and password resets | **Implemented** | PBKDF2-HMAC-SHA256 password hashing (100k rounds + salt). Logout token revocation blacklist. Time-limited single-use password reset tokens. |
| **11** | Rate-limit login, signup, and expensive API calls | **Implemented** | Sliding-window rate limiter ([`rate_limiter.py`](file:///d:/APP/Android/backend/security/rate_limiter.py)) enforcing per-IP quotas (e.g. 5/min login, 3/min register) returning HTTP 429. |
| **12** | Usage caps so users cannot drain AI budget | **Implemented** | Daily quota limiter ([`ai_quota.py`](file:///d:/APP/Android/backend/security/ai_quota.py)) caps citizen AI emergency triage calls at 10 requests / 10,000 tokens per day. |
| **13** | Validate inputs on the server | **Implemented** | Strict Pydantic v2 schemas in [`input_validation.py`](file:///d:/APP/Android/backend/security/input_validation.py) for coordinates, phone numbers, enums, and string length boundaries. |
| **14** | Safe database queries to prevent injection | **Implemented** | Strict table and column name whitelisting in [`database.py`](file:///d:/APP/Android/backend/database.py). 100% parameterized SQL execution with `?` placeholders. |
| **15** | User content cannot run scripts (XSS defense) | **Implemented** | [`sanitize_text()`](file:///d:/APP/Android/backend/security/input_validation.py) escapes HTML and strips script blocks/event handlers. HTTP Security Headers: CSP, HSTS, X-Content-Type-Options, Frame-Options. |
| **16** | Restrict file types and sizes for uploads | **Implemented** | Max 5 MB upload limit, strict extension/MIME whitelist (`.jpg`, `.jpeg`, `.png`, `.webp`, `.pdf`), magic-byte inspection, UUID filename generation. |
| **17** | Verify payments on server before unlocking features | **Implemented** | Server-side HMAC-SHA256 signature verification in [`payment_verifier.py`](file:///d:/APP/Android/backend/security/payment_verifier.py). Replay prevention ledger. |
| **18** | Turn off debug mode & keep secrets out of errors | **Implemented** | `APP_DEBUG=false` hides tracebacks and documentation. Global exception handler masks internal database errors and generates randomized tracking incident IDs. |
| **19** | Back up your data and test restoring it | **Implemented** | Zero-downtime online SQLite backup API in [`backup.py`](file:///d:/APP/Android/backend/backup.py) with automated `PRAGMA integrity_check` and tested restoration. |
| **20** | Test with two accounts, then test without logging in | **Implemented** | End-to-end automated multi-tenant test suite in [`test_multitenant_security.py`](file:///d:/APP/Android/backend/test_multitenant_security.py) verifying 401 unauthenticated, IDOR 403 blocks, and admin checks. |

---

## Running Automated Security Verification

### 1. Run Repository Secret Scanner (Points 1, 2, 3)
```powershell
python scripts/scan_secrets.py
```

### 2. Run Database Backup & Restore Integrity Test (Point 19)
```powershell
python -m unittest backend/test_backup.py
```

### 3. Run Multi-Tenant Cross-Account Security Test Suite (Points 5–18, 20)
```powershell
python -m unittest backend/test_multitenant_security.py
```

### 4. Run Full Backend Test Suite
```powershell
cd backend
python -m unittest discover -s . -p "test_*.py"
```

---

## Key Rotation Procedure (Point 4)

If a key, token, or secret is suspected of exposure:

1. **Generate New Secret**:
   ```bash
   python -c "import secrets; print(secrets.token_hex(32))"
   ```
2. **Update Environment**:
   - Update `.env` on production servers with new `JWT_SECRET_KEY` or `PAYMENT_GATEWAY_WEBHOOK_SECRET`.
3. **Restart API Service**:
   - Existing active JWTs signed with previous key become invalid immediately, requiring users to log in securely.
4. **Revoke Upstream Credentials**:
   - In third-party developer consoles (e.g. OpenAI, Payment Gateway, Google Maps), immediately revoke the old key and issue a new one.
