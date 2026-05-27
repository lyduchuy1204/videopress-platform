"""POST /api/v1/auth/logout — revoke refresh token."""

from typing import Any

from shared.responses import success_response


def handle(event: dict[str, Any]) -> dict[str, Any]:
    """Gọi Cognito GlobalSignOut hoặc RevokeToken.

    TODO: parse access token từ Authorization header, gọi Cognito sign-out.
    """
    return success_response({"message": "Logged out"}, status_code=200)
