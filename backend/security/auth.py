"""
backend/security/auth.py
Secure Authentication & Authorization Framework

Implements:
- Point 1: Secure server-side secrets (JWT & Admin secrets never exposed to frontend)
- Point 5: Request permission verification on every call
- Point 6: Untrusted client IDs/roles replaced with server-verified identities
- Point 7: IDOR defense & user data isolation
- Point 9: Strict RBAC for admin endpoints
- Point 10: Secure login, token-blacklisted logout, and time-limited password resets
"""

import base64
import hashlib
import hmac
import json
import os
import secrets
import time
from datetime import datetime, timezone
from typing import Dict, Any, Optional, List, Callable
from fastapi import HTTPException, Security, Depends, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

# Configuration
JWT_SECRET = os.getenv("JWT_SECRET_KEY", "resqlink_default_secure_secret_key_change_in_production_32b")
JWT_ALGORITHM = "HS256"
TOKEN_EXPIRY_SECONDS = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "1440")) * 60 # Default 24 hours
PASSWORD_SALT_BYTES = 16
PASSWORD_HASH_ROUNDS = 100_000

# Security scheme
security_scheme = HTTPBearer(auto_error=False)

# In-memory revocation cache for logged out tokens: set of jti -> expiry timestamp
_REVOKED_TOKENS: Dict[str, float] = {}

# Active password reset tokens: token -> { "user_id": str, "expires_at": float, "used": bool }
_PASSWORD_RESET_TOKENS: Dict[str, Dict[str, Any]] = {}


# --- Password Hashing (PBKDF2-HMAC-SHA256) ---

def hash_password(password: str) -> str:
    """Hash password using PBKDF2-HMAC-SHA256 with cryptographically random salt."""
    if len(password) < 8:
        raise ValueError("Password must be at least 8 characters long")
    salt = secrets.token_bytes(PASSWORD_SALT_BYTES)
    key = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, PASSWORD_HASH_ROUNDS)
    # Stored as salt$hash in base64
    salt_b64 = base64.b64encode(salt).decode("ascii")
    key_b64 = base64.b64encode(key).decode("ascii")
    return f"{salt_b64}${key_b64}"

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Constant-time verification of password hash."""
    try:
        salt_b64, key_b64 = hashed_password.split("$")
        salt = base64.b64decode(salt_b64.encode("ascii"))
        expected_key = base64.b64decode(key_b64.encode("ascii"))
        computed_key = hashlib.pbkdf2_hmac("sha256", plain_password.encode("utf-8"), salt, PASSWORD_HASH_ROUNDS)
        return hmac.compare_digest(computed_key, expected_key)
    except Exception:
        return False


# --- Pure-Python RFC 7519 Compliant JWT ---

def _b64_url_encode(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode("ascii").rstrip("=")

def _b64_url_decode(data_str: str) -> bytes:
    padding = "=" * (4 - len(data_str) % 4)
    return base64.urlsafe_b64decode(data_str + padding)

def create_access_token(user_id: str, role: str, name: str, expires_in: Optional[int] = None) -> str:
    """Generate signed JWT token containing subject, role, and unique jti."""
    now = time.time()
    exp = now + (expires_in or TOKEN_EXPIRY_SECONDS)
    jti = secrets.token_hex(16)

    header = {"alg": JWT_ALGORITHM, "typ": "JWT"}
    payload = {
        "sub": user_id,
        "role": role,
        "name": name,
        "iat": int(now),
        "exp": int(exp),
        "jti": jti,
        "iss": "resqlink-backend"
    }

    header_b64 = _b64_url_encode(json.dumps(header, separators=(",", ":")).encode("utf-8"))
    payload_b64 = _b64_url_encode(json.dumps(payload, separators=(",", ":")).encode("utf-8"))
    signing_input = f"{header_b64}.{payload_b64}".encode("ascii")

    signature = hmac.new(JWT_SECRET.encode("utf-8"), signing_input, hashlib.sha256).digest()
    sig_b64 = _b64_url_encode(signature)

    return f"{header_b64}.{payload_b64}.{sig_b64}"

def decode_access_token(token: str) -> Dict[str, Any]:
    """Verify and decode JWT token; checks expiration and revocation status."""
    parts = token.split(".")
    if len(parts) != 3:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token structure",
            headers={"WWW-Authenticate": "Bearer"}
        )

    header_b64, payload_b64, sig_b64 = parts
    signing_input = f"{header_b64}.{payload_b64}".encode("ascii")
    expected_sig = hmac.new(JWT_SECRET.encode("utf-8"), signing_input, hashlib.sha256).digest()

    try:
        received_sig = _b64_url_decode(sig_b64)
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token signature encoding",
            headers={"WWW-Authenticate": "Bearer"}
        )

    if not hmac.compare_digest(received_sig, expected_sig):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token signature",
            headers={"WWW-Authenticate": "Bearer"}
        )

    try:
        payload_bytes = _b64_url_decode(payload_b64)
        payload = json.loads(payload_bytes.decode("utf-8"))
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload",
            headers={"WWW-Authenticate": "Bearer"}
        )

    # Check expiration
    if payload.get("exp", 0) < time.time():
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired. Please log in again.",
            headers={"WWW-Authenticate": "Bearer"}
        )

    # Check revocation (logout)
    jti = payload.get("jti")
    if jti and jti in _REVOKED_TOKENS:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has been revoked. Please log in again.",
            headers={"WWW-Authenticate": "Bearer"}
        )

    return payload

def revoke_token(token: str) -> None:
    """Revoke a token upon user logout."""
    try:
        payload = decode_access_token(token)
        jti = payload.get("jti")
        exp = payload.get("exp", time.time() + 3600)
        if jti:
            _REVOKED_TOKENS[jti] = exp
        _cleanup_revoked_tokens()
    except HTTPException:
        pass

def _cleanup_revoked_tokens():
    """Prune expired revoked tokens from memory cache."""
    now = time.time()
    expired = [jti for jti, exp in _REVOKED_TOKENS.items() if exp < now]
    for jti in expired:
        del _REVOKED_TOKENS[jti]


# --- Password Reset Tokens ---

def generate_password_reset_token(user_id: str, validity_minutes: int = 15) -> str:
    """Generate cryptographically secure single-use password reset token."""
    token = secrets.token_urlsafe(32)
    _PASSWORD_RESET_TOKENS[token] = {
        "user_id": user_id,
        "expires_at": time.time() + (validity_minutes * 60),
        "used": False
    }
    return token

def verify_and_consume_reset_token(token: str) -> str:
    """Validate reset token, verify not expired or used, and mark as consumed."""
    now = time.time()
    record = _PASSWORD_RESET_TOKENS.get(token)
    if not record:
        raise HTTPException(status_code=400, detail="Invalid or expired reset token")

    if record["used"]:
        raise HTTPException(status_code=400, detail="Reset token has already been used")

    if record["expires_at"] < now:
        del _PASSWORD_RESET_TOKENS[token]
        raise HTTPException(status_code=400, detail="Reset token has expired. Please request a new one.")

    record["used"] = True
    return record["user_id"]


# --- FastAPI Authorization Dependencies ---

def get_current_user(auth: Optional[HTTPAuthorizationCredentials] = Security(security_scheme)) -> Dict[str, Any]:
    """
    Point 5: Authenticate every request.
    Extracts Bearer token and returns verified current user claims.
    """
    if not auth or not auth.credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required. Provide a valid Bearer token.",
            headers={"WWW-Authenticate": "Bearer"}
        )

    claims = decode_access_token(auth.credentials)
    return {
        "id": claims["sub"],
        "role": claims.get("role", "citizen"),
        "name": claims.get("name", "User"),
        "token": auth.credentials
    }

def get_optional_current_user(auth: Optional[HTTPAuthorizationCredentials] = Security(security_scheme)) -> Optional[Dict[str, Any]]:
    """Optional auth for public endpoints that can enrich with user data if authenticated."""
    if not auth or not auth.credentials:
        return None
    try:
        claims = decode_access_token(auth.credentials)
        return {
            "id": claims["sub"],
            "role": claims.get("role", "citizen"),
            "name": claims.get("name", "User"),
            "token": auth.credentials
        }
    except Exception:
        return None

def require_role(allowed_roles: List[str]) -> Callable:
    """
    Point 9: Protect actions by strictly checking user roles on the server.
    Ensures frontend cannot elevate privileges.
    """
    def role_checker(current_user: Dict[str, Any] = Depends(get_current_user)) -> Dict[str, Any]:
        user_role = current_user.get("role", "citizen")
        if user_role not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Forbidden: Insufficient privileges. Required role: {allowed_roles}. Current role: '{user_role}'"
            )
        return current_user
    return role_checker

def check_ownership(resource_owner_id: Optional[str], current_user: Dict[str, Any]) -> None:
    """
    Point 7: IDOR Protection.
    Ensure regular users can ONLY access/modify their OWN records.
    Responders and Admins are permitted to access shared records.
    """
    user_role = current_user.get("role", "citizen")
    if user_role in ["admin", "responder"]:
        return # Authorized to manage any record

    if not resource_owner_id or resource_owner_id != current_user["id"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: You do not have permission to access or modify this record."
        )
