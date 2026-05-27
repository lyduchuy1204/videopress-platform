"""POST /api/v1/auth/refresh_token — đổi refresh token thành access token mới."""

from typing import Any

from shared.responses import success_response


def handle(event: dict[str, Any]) -> dict[str, Any]:
    """Gọi Cognito InitiateAuth với REFRESH_TOKEN_AUTH flow.

    TODO: parse refresh_token từ body, gọi Cognito, trả access_token mới.
    """
    return success_response(
        {"access_token": "MOCK_NEW_ACCESS_TOKEN", "expires_in": 3600, "token_type": "Bearer"}
    )
