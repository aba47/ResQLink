"""
backend/security/input_validation.py
Strict Server-Side Input Validation & XSS Sanitization

Implements:
- Point 13: Validate inputs on the server
- Point 15: Make sure user content cannot run scripts (XSS defense)
- Point 6: Validate roles, prices, and IDs
"""

import html
import re
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field, field_validator, model_validator

# Phone regex supporting international formats
PHONE_REGEX = re.compile(r"^\+?[0-9\s\-\(\)]{7,20}$")

# Dangerous XSS patterns (script tags, event handlers, javascript pseudo-protocol)
DANGEROUS_PATTERNS = [
    re.compile(r"<\s*script[^>]*>.*?<\s*/\s*script\s*>", re.IGNORECASE | re.DOTALL),
    re.compile(r"javascript\s*:", re.IGNORECASE),
    re.compile(r"vbscript\s*:", re.IGNORECASE),
    re.compile(r"data\s*:\s*text\/html", re.IGNORECASE),
    re.compile(r"on\w+\s*=", re.IGNORECASE), # e.g. onerror=, onload=, onclick=
]

def sanitize_text(value: Optional[str]) -> Optional[str]:
    """
    Point 15: Sanitize user-submitted text to prevent stored and reflected XSS.
    Strips script blocks and encodes HTML special characters.
    """
    if value is None:
        return None

    cleaned = value
    for pattern in DANGEROUS_PATTERNS:
        cleaned = pattern.sub("", cleaned)

    # HTML escape remaining characters
    cleaned = html.escape(cleaned.strip(), quote=True)
    return cleaned


# --- Authentication & User Schemas ---

class UserRegisterRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    phone: str = Field(..., min_length=7, max_length=20)
    email: Optional[str] = Field(None, max_length=120)
    password: str = Field(..., min_length=8, max_length=128)
    # Note: client CANNOT pick their role; self-registration is strictly 'citizen'

    @field_validator("name", "email")
    @classmethod
    def sanitize_strings(cls, v):
        return sanitize_text(v)

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, v):
        cleaned = v.strip()
        if not PHONE_REGEX.match(cleaned):
            raise ValueError("Invalid phone number format")
        return cleaned

class UserLoginRequest(BaseModel):
    phone_or_email: str = Field(..., min_length=3, max_length=120)
    password: str = Field(..., min_length=1, max_length=128)

class PasswordResetRequest(BaseModel):
    phone_or_email: str = Field(..., min_length=3, max_length=120)

class PasswordResetConfirm(BaseModel):
    token: str = Field(..., min_length=10, max_length=128)
    new_password: str = Field(..., min_length=8, max_length=128)

class UserRoleUpdateRequest(BaseModel):
    role: str = Field(...)

    @field_validator("role")
    @classmethod
    def validate_role(cls, v):
        allowed = {"citizen", "responder", "admin"}
        if v.lower() not in allowed:
            raise ValueError(f"Invalid role. Must be one of: {sorted(list(allowed))}")
        return v.lower()


# --- Disaster & Emergency Schemas ---

class DisasterCreateRequest(BaseModel):
    title: str = Field(..., min_length=3, max_length=150)
    type: str = Field(..., min_length=2, max_length=50)
    description: Optional[str] = Field(None, max_length=2000)
    severity: str = Field(..., description="LOW, MEDIUM, HIGH, CRITICAL")
    status: str = Field(default="active", description="active, monitored, resolved")
    location: str = Field(..., min_length=2, max_length=200)
    latitude: Optional[float] = Field(None, ge=-90.0, le=90.0)
    longitude: Optional[float] = Field(None, ge=-180.0, le=180.0)
    radius_km: Optional[float] = Field(0.0, ge=0.0, le=5000.0)
    affected_population: Optional[int] = Field(0, ge=0)

    @field_validator("title", "type", "description", "location")
    @classmethod
    def sanitize(cls, v):
        return sanitize_text(v)

    @field_validator("severity")
    @classmethod
    def validate_severity(cls, v):
        allowed = {"LOW", "MEDIUM", "HIGH", "CRITICAL"}
        if v.upper() not in allowed:
            raise ValueError("Severity must be LOW, MEDIUM, HIGH, or CRITICAL")
        return v.upper()

class EmergencyRequestCreateRequest(BaseModel):
    request_type: str = Field(..., min_length=2, max_length=50)
    priority: str = Field(..., description="LOW, MEDIUM, HIGH, CRITICAL")
    description: str = Field(..., min_length=3, max_length=2000)
    location: str = Field(..., min_length=2, max_length=200)
    phone: str = Field(..., min_length=7, max_length=20)
    people_count: int = Field(default=1, ge=1, le=1000)
    latitude: Optional[float] = Field(None, ge=-90.0, le=90.0)
    longitude: Optional[float] = Field(None, ge=-180.0, le=180.0)
    disaster_id: Optional[str] = Field(None, max_length=64)

    @field_validator("description", "location", "request_type")
    @classmethod
    def sanitize(cls, v):
        return sanitize_text(v)

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, v):
        cleaned = v.strip()
        if not PHONE_REGEX.match(cleaned):
            raise ValueError("Invalid phone number format")
        return cleaned

    @field_validator("priority")
    @classmethod
    def validate_priority(cls, v):
        allowed = {"LOW", "MEDIUM", "HIGH", "CRITICAL"}
        if v.upper() not in allowed:
            raise ValueError("Priority must be LOW, MEDIUM, HIGH, or CRITICAL")
        return v.upper()

class EmergencyRequestUpdateRequest(BaseModel):
    status: Optional[str] = Field(None, max_length=50)
    priority: Optional[str] = Field(None)
    assigned_team: Optional[str] = Field(None, max_length=100)
    description: Optional[str] = Field(None, max_length=2000)

    @field_validator("assigned_team", "description")
    @classmethod
    def sanitize(cls, v):
        return sanitize_text(v)

    @field_validator("status")
    @classmethod
    def validate_status(cls, v):
        if v is None:
            return None
        allowed = {"Requested", "Accepted", "Team Assigned", "In Progress", "Completed", "Cancelled"}
        if v not in allowed:
            raise ValueError(f"Status must be one of: {sorted(list(allowed))}")
        return v

    @field_validator("priority")
    @classmethod
    def validate_priority(cls, v):
        if v is None:
            return None
        allowed = {"LOW", "MEDIUM", "HIGH", "CRITICAL"}
        if v.upper() not in allowed:
            raise ValueError("Priority must be LOW, MEDIUM, HIGH, or CRITICAL")
        return v.upper()

class ShelterCreateRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=150)
    address: str = Field(..., min_length=2, max_length=250)
    latitude: float = Field(..., ge=-90.0, le=90.0)
    longitude: float = Field(..., ge=-180.0, le=180.0)
    capacity: int = Field(default=0, ge=0, le=50000)
    current_occupancy: int = Field(default=0, ge=0, le=50000)
    contact_person: Optional[str] = Field(None, max_length=100)
    contact_phone: Optional[str] = Field(None, max_length=20)
    facilities: Optional[str] = Field(None, max_length=500)
    supplies_status: Optional[str] = Field(None, max_length=200)

    @field_validator("name", "address", "contact_person", "facilities", "supplies_status")
    @classmethod
    def sanitize(cls, v):
        return sanitize_text(v)


# --- AI Triage Schema ---

class AITriageRequest(BaseModel):
    incident_details: str = Field(..., min_length=5, max_length=2000)
    location: Optional[str] = Field(None, max_length=200)
    people_in_danger: Optional[int] = Field(1, ge=0, le=500)

    @field_validator("incident_details", "location")
    @classmethod
    def sanitize(cls, v):
        return sanitize_text(v)


# --- Payment Verification Schema ---

class PaymentVerifyRequest(BaseModel):
    order_id: str = Field(..., min_length=5, max_length=100)
    payment_id: str = Field(..., min_length=5, max_length=100)
    signature: str = Field(..., min_length=10, max_length=256)
    package_name: str = Field(..., min_length=3, max_length=50)

    @field_validator("order_id", "payment_id", "package_name")
    @classmethod
    def sanitize(cls, v):
        return sanitize_text(v)
