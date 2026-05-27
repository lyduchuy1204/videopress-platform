"""POST /api/v1/auth/login — đăng nhập với email + password."""

from typing import Any

from shared.responses import success_response


def handle(event: dict[str, Any]) -> dict[str, Any]:
    """Xác thực user qua Cognito InitiateAuth.

    TODO: parse body, validate input (pydantic), gọi cognito_service.login(),
    trả tokens hoặc lỗi.
    """
    # Mock response — sẽ thay bằng call Cognito thật khi có User Pool
    return success_response(
        {
            "access_token": "MOCK_ACCESS_TOKEN",
            "refresh_token": "MOCK_REFRESH_TOKEN",
            "expires_in": 3600,
            "token_type": "Bearer",
        }
    )
