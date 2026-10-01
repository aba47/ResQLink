"""
backend/security/ai_quota.py
AI Budget & Usage Cap Protection

Implements:
- Point 12: Add usage caps so one user cannot drain your AI budget
- Tracks daily request and token counters per user
- Enforces hard limits before any external AI API call is dispatched
"""

import time
from typing import Dict, Tuple, Optional
from fastapi import HTTPException, status

DEFAULT_DAILY_REQUEST_CAP = 10
DEFAULT_DAILY_TOKEN_CAP = 10_000
WINDOW_SECONDS = 86_400 # 24 hours

class AIQuotaManager:
    def __init__(self):
        # Key: user_id -> { "window_start": float, "requests_used": int, "tokens_used": int }
        self._user_usage: Dict[str, Dict[str, Any]] = {}

    def _get_user_state(self, user_id: str) -> Dict[str, Any]:
        now = time.time()
        state = self._user_usage.get(user_id)
        if not state or (now - state["window_start"]) > WINDOW_SECONDS:
            state = {
                "window_start": now,
                "requests_used": 0,
                "tokens_used": 0
            }
            self._user_usage[user_id] = state
        return state

    def check_and_reserve(
        self,
        user_id: str,
        user_role: str = "citizen",
        estimated_tokens: int = 500
    ) -> Tuple[bool, int, int]:
        """
        Verify if user has sufficient quota remaining before calling AI model.
        Admins and responders have elevated/unlimited quota.
        """
        if user_role in ["admin", "responder"]:
            return True, 999999, 999999

        state = self._get_user_state(user_id)

        if state["requests_used"] >= DEFAULT_DAILY_REQUEST_CAP:
            remaining_seconds = int(WINDOW_SECONDS - (time.time() - state["window_start"]))
            hours = max(1, remaining_seconds // 3600)
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=f"Daily AI emergency triage quota exceeded ({DEFAULT_DAILY_REQUEST_CAP} requests/day). Quota resets in ~{hours} hour(s)."
            )

        if state["tokens_used"] + estimated_tokens > DEFAULT_DAILY_TOKEN_CAP:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=f"Daily AI token budget limit reached ({DEFAULT_DAILY_TOKEN_CAP} tokens/day). Please wait for daily reset."
            )

        # Increment usage
        state["requests_used"] += 1
        state["tokens_used"] += estimated_tokens

        remaining_requests = DEFAULT_DAILY_REQUEST_CAP - state["requests_used"]
        remaining_tokens = DEFAULT_DAILY_TOKEN_CAP - state["tokens_used"]
        return True, remaining_requests, remaining_tokens

    def record_actual_tokens(self, user_id: str, actual_tokens: int, estimated_tokens: int = 500):
        """Adjust token count if actual tokens differs from estimate."""
        state = self._get_user_state(user_id)
        diff = actual_tokens - estimated_tokens
        state["tokens_used"] = max(0, state["tokens_used"] + diff)

    def get_user_quota(self, user_id: str, user_role: str = "citizen") -> Dict[str, Any]:
        if user_role in ["admin", "responder"]:
            return {
                "requests_limit": "unlimited",
                "requests_remaining": "unlimited",
                "tokens_limit": "unlimited",
                "tokens_remaining": "unlimited",
            }
        state = self._get_user_state(user_id)
        return {
            "requests_limit": DEFAULT_DAILY_REQUEST_CAP,
            "requests_used": state["requests_used"],
            "requests_remaining": max(0, DEFAULT_DAILY_REQUEST_CAP - state["requests_used"]),
            "tokens_limit": DEFAULT_DAILY_TOKEN_CAP,
            "tokens_used": state["tokens_used"],
            "tokens_remaining": max(0, DEFAULT_DAILY_TOKEN_CAP - state["tokens_used"]),
        }

    def reset_quota(self, user_id: str):
        """Reset quota for testing or user support."""
        if user_id in self._user_usage:
            del self._user_usage[user_id]

# Global instance
ai_quota = AIQuotaManager()
