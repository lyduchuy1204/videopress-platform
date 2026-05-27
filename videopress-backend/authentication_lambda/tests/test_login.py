"""Test cho POST /api/v1/auth/login handler."""

import json
from typing import Any


def test_login_returns_mock_token(api_event: dict[str, Any]) -> None:
    """Skeleton test — login handler trả mock token có shape đúng."""
    from handlers.login import handle  # pylint: disable=import-outside-toplevel

    response = handle(api_event)

    assert response["statusCode"] == 200
    body = json.loads(response["body"])
    assert "access_token" in body
    assert body["token_type"] == "Bearer"
    assert body["expires_in"] == 3600
