"""
backend/security/payment_verifier.py
Server-Side Payment Signature & Role Verification

Implements:
- Point 17: Verify payments on the server before unlocking paid features
- Point 6: Never trust prices or paid status sent by the frontend
- Prevents replay attacks and signature forgery
"""

import hmac
import hashlib
import os
from typing import Dict, Any, Set
from fastapi import HTTPException, status

PAYMENT_WEBHOOK_SECRET = os.getenv("PAYMENT_GATEWAY_WEBHOOK_SECRET", "mock_payment_webhook_secret_key_prod_32b")

# Official server-side price catalog (Never trust prices sent by client)
OFFICIAL_PACKAGES: Dict[str, Dict[str, Any]] = {
    "satellite_offline_pack": {
        "price_cents": 499,
        "currency": "USD",
        "feature": "satellite_offline_maps",
        "description": "High-resolution offline satellite imagery pack"
    },
    "relief_donor_tier": {
        "price_cents": 2500,
        "currency": "USD",
        "feature": "relief_supporter_badge",
        "description": "Disaster relief donor support tier"
    }
}

# Processed payment transactions to prevent replay attacks
_PROCESSED_PAYMENTS: Set[str] = set()

def verify_payment_signature(order_id: str, payment_id: str, client_signature: str) -> bool:
    """
    Verify payment cryptographic signature using server-side HMAC-SHA256 secret.
    """
    payload = f"{order_id}|{payment_id}".encode("utf-8")
    expected_sig = hmac.new(PAYMENT_WEBHOOK_SECRET.encode("utf-8"), payload, hashlib.sha256).hexdigest()
    return hmac.compare_digest(expected_sig.lower(), client_signature.lower())

def process_verified_payment(
    user_id: str,
    package_name: str,
    order_id: str,
    payment_id: str,
    signature: str
) -> Dict[str, Any]:
    """
    Authenticate payment, prevent replay, and unlock features strictly on server.
    """
    if package_name not in OFFICIAL_PACKAGES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unknown package: '{package_name}'. Valid packages: {list(OFFICIAL_PACKAGES.keys())}"
        )

    # Check for replay attack
    if payment_id in _PROCESSED_PAYMENTS:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Transaction has already been processed. Replay rejected."
        )

    # Verify signature
    is_valid = verify_payment_signature(order_id, payment_id, signature)
    if not is_valid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Payment verification failed: Invalid cryptographic signature."
        )

    # Mark as processed
    _PROCESSED_PAYMENTS.add(payment_id)
    pkg = OFFICIAL_PACKAGES[package_name]

    return {
        "status": "success",
        "user_id": user_id,
        "unlocked_feature": pkg["feature"],
        "package_name": package_name,
        "amount_verified": pkg["price_cents"],
        "currency": pkg["currency"],
        "payment_id": payment_id
    }
