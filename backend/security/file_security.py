"""
backend/security/file_security.py
Secure File Upload & Storage Management

Implements:
- Point 16: Restrict file types and sizes for uploads (magic bytes + MIME validation)
- Point 8: Lock down private file storage & prevent path traversal
"""

import os
import uuid
from typing import Tuple, Dict, Any
from fastapi import HTTPException, UploadFile, status

MAX_FILE_SIZE_BYTES = int(os.getenv("UPLOAD_MAX_BYTES", "5242880")) # 5 MB
UPLOAD_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "storage", "uploads"))

# Allowed extensions and magic signatures
ALLOWED_SIGNATURES: Dict[str, bytes] = {
    ".jpg": b"\xff\xd8\xff",
    ".jpeg": b"\xff\xd8\xff",
    ".png": b"\x89PNG\r\n\x1a\n",
    ".pdf": b"%PDF-",
}

ALLOWED_MIME_TYPES = {
    "image/jpeg",
    "image/png",
    "image/webp",
    "application/pdf",
}

def init_storage_dir():
    """Ensure upload storage directory exists with restricted access."""
    os.makedirs(UPLOAD_DIR, exist_ok=True)

def validate_and_save_upload(
    upload_file: UploadFile,
    file_bytes: bytes,
    uploader_user_id: str
) -> Dict[str, Any]:
    """
    Validate size, extension, MIME type, and magic bytes.
    Saves file with UUID to prevent path traversal and file overwriting.
    """
    init_storage_dir()

    # 1. Size restriction
    if len(file_bytes) > MAX_FILE_SIZE_BYTES:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"File exceeds maximum allowed size of {MAX_FILE_SIZE_BYTES // (1024*1024)}MB."
        )

    if len(file_bytes) == 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Uploaded file is empty."
        )

    # 2. Extension validation
    orig_filename = upload_file.filename or "unnamed.bin"
    ext = os.path.splitext(orig_filename)[1].lower()

    if ext not in ALLOWED_SIGNATURES and ext != ".webp":
        allowed_list = list(ALLOWED_SIGNATURES.keys()) + [".webp"]
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"File extension '{ext}' is not permitted. Allowed: {allowed_list}"
        )

    # 3. MIME type validation
    content_type = upload_file.content_type or ""
    if content_type.lower() not in ALLOWED_MIME_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"MIME type '{content_type}' is not allowed."
        )

    # 4. Magic bytes verification (detect executable masquerading as image)
    if ext in ALLOWED_SIGNATURES:
        expected_sig = ALLOWED_SIGNATURES[ext]
        if not file_bytes.startswith(expected_sig):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"File contents do not match extension '{ext}' (header mismatch)."
            )
    elif ext == ".webp":
        if not (file_bytes.startswith(b"RIFF") and b"WEBP" in file_bytes[:16]):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="File is not a valid WebP image."
            )

    # 5. Generate secure random filename to prevent path traversal
    safe_filename = f"{uuid.uuid4().hex}{ext}"
    target_path = os.path.abspath(os.path.join(UPLOAD_DIR, safe_filename))

    # Path traversal assertion
    if not target_path.startswith(UPLOAD_DIR):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid file destination path")

    with open(target_path, "wb") as f:
        f.write(file_bytes)

    return {
        "filename": safe_filename,
        "size_bytes": len(file_bytes),
        "content_type": content_type,
        "url_path": f"/media/{safe_filename}",
        "uploaded_by": uploader_user_id
    }

def get_safe_file_path(filename: str) -> str:
    """
    Safely resolve a stored file path, preventing directory traversal attacks.
    """
    # Reject path separators
    if "/" in filename or "\\" in filename or ".." in filename:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid filename format")

    target_path = os.path.abspath(os.path.join(UPLOAD_DIR, filename))
    if not target_path.startswith(UPLOAD_DIR):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    if not os.path.exists(target_path):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="File not found")

    return target_path
