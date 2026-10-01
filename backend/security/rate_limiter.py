"""
backend/security/rate_limiter.py
Sliding-Window In-Memory Rate Limiting Engine

Implements:
- Point 11: Rate-limit login, signup, and expensive API calls
- Prevents brute-force credential stuffing and DoS attacks
- Returns standard HTTP 429 with Retry-After and X-RateLimit headers
"""

import time
from typing import Dict, List, Tuple
from fastapi import Request, HTTPException, status

class SlidingWindowRateLimiter:
    def __init__(self):
        # Key: (client_ip, bucket_name) -> List of epoch timestamps
        self._history: Dict[Tuple[str, str], List[float]] = {}
        self._last_clean = time.time()

    def check_rate_limit(
        self,
        key: str,
        bucket_name: str,
        max_requests: int,
        window_seconds: int
    ) -> Tuple[bool, int, int]:
        """
        Check if request is permitted under sliding window.
        Returns: (is_allowed, remaining_calls, retry_after_seconds)
        """
        now = time.time()
        bucket_key = (key, bucket_name)

        # Cleanup old entries every 60 seconds
        if now - self._last_clean > 60:
            self._cleanup(now)

        timestamps = self._history.setdefault(bucket_key, [])
        cutoff = now - window_seconds

        # Discard timestamps outside window
        self._history[bucket_key] = [t for t in timestamps if t > cutoff]
        current_count = len(self._history[bucket_key])

        if current_count >= max_requests:
            # Oldest timestamp determines when a slot will open
            oldest = self._history[bucket_key][0]
            retry_after = max(1, int(oldest + window_seconds - now))
            return False, 0, retry_after

        # Record this request
        self._history[bucket_key].append(now)
        remaining = max_requests - (current_count + 1)
        return True, remaining, 0

    def _cleanup(self, now: float):
        keys_to_delete = []
        for k, timestamps in self._history.items():
            valid = [t for t in timestamps if t > (now - 300)]
            if valid:
                self._history[k] = valid
            else:
                keys_to_delete.append(k)
        for k in keys_to_delete:
            del self._history[k]
        self._last_clean = now

    def reset(self):
        """Reset all rate limiter state (useful for tests)."""
        self._history.clear()
        self._last_clean = time.time()

# Global instance
limiter = SlidingWindowRateLimiter()

def rate_limit(bucket_name: str, max_requests: int, window_seconds: int = 60):
    """FastAPI dependency to enforce rate limits per client IP."""
    def dependency(request: Request):
        client_ip = request.client.host if request.client else "127.0.0.1"
        # Support X-Forwarded-For if behind a trusted proxy
        forwarded = request.headers.get("x-forwarded-for")
        if forwarded:
            client_ip = forwarded.split(",")[0].strip()

        allowed, remaining, retry_after = limiter.check_rate_limit(
            client_ip, bucket_name, max_requests, window_seconds
        )

        if not allowed:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=f"Rate limit exceeded for '{bucket_name}'. Please try again in {retry_after} seconds.",
                headers={
                    "Retry-After": str(retry_after),
                    "X-RateLimit-Limit": str(max_requests),
                    "X-RateLimit-Remaining": "0",
                }
            )
        return True
    return dependency
