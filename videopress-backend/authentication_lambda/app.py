"""Authentication Lambda — entry point.

Handle các endpoint xác thực user qua Cognito + custom OTP.

Routes:
    POST /api/v1/auth/login         → handlers.login.handle
    POST /api/v1/auth/otp_verify    → handlers.otp_verify.handle
    POST /api/v1/auth/refresh_token → handlers.refresh_token.handle
    POST /api/v1/auth/logout        → handlers.logout.handle

Example event (API Gateway proxy):
    {
        "httpMethod": "POST",
        "path": "/api/v1/auth/login",
        "body": '{"email":"a@b.com","password":"***"}',
        "headers": {"Content-Type": "application/json"}
    }

Example response:
    {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": '{"access_token":"...","refresh_token":"...","expires_in":3600}'
    }
"""

from typing import Any

from shared.logger import logger
from shared.responses import error_response

from handlers import login, logout, otp_verify, refresh_token

# Route map: (method, path) -> handler.handle(event)
_ROUTES = {
    ("POST", "/api/v1/auth/login"): login.handle,
    ("POST", "/api/v1/auth/otp_verify"): otp_verify.handle,
    ("POST", "/api/v1/auth/refresh_token"): refresh_token.handle,
    ("POST", "/api/v1/auth/logout"): logout.handle,
}


@logger.inject_lambda_context(correlation_id_path="requestContext.requestId")
def lambda_handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    """Entry point của Lambda. Route theo (httpMethod, path)."""
    method = event.get("httpMethod", "")
    path = event.get("path", "")
    logger.info("incoming request", extra={"method": method, "path": path})

    handler = _ROUTES.get((method, path))
    if handler is None:
        return error_response(404, f"Route không tồn tại: {method} {path}", code="NOT_FOUND")

    try:
        return handler(event)
    except NotImplementedError as exc:
        logger.warning("handler chưa implement", extra={"error": str(exc)})
        return error_response(501, "Endpoint chưa implement", code="NOT_IMPLEMENTED")
    except Exception as exc:  # pylint: disable=broad-except
        logger.exception("unhandled error in handler")
        return error_response(500, str(exc))
