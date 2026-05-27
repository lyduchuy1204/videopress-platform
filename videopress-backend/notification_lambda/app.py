"""Notification Lambda — entry point.

Handle các endpoint notification cho user (in-app + email).

Routes:
    GET  /api/v1/notifications              → list_notifications.handle
    POST /api/v1/notifications/mark_read    → mark_read.handle
    POST /api/v1/notifications/push_email   → push_email.handle (internal)

Example event:
    {
        "httpMethod": "GET",
        "path": "/api/v1/notifications",
        "queryStringParameters": {"limit": "20", "cursor": "abc"}
    }

Example response:
    {
        "statusCode": 200,
        "body": '{"items":[...],"next_cursor":"xyz"}'
    }
"""

from typing import Any

from shared.logger import logger
from shared.responses import error_response

from handlers import list_notifications, mark_read, push_email

_ROUTES = {
    ("GET", "/api/v1/notifications"): list_notifications.handle,
    ("POST", "/api/v1/notifications/mark_read"): mark_read.handle,
    ("POST", "/api/v1/notifications/push_email"): push_email.handle,
}


@logger.inject_lambda_context(correlation_id_path="requestContext.requestId")
def lambda_handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    """Entry point — route theo (httpMethod, path)."""
    method = event.get("httpMethod", "")
    path = event.get("path", "")
    logger.info("incoming request", extra={"method": method, "path": path})

    handler = _ROUTES.get((method, path))
    if handler is None:
        return error_response(404, f"Route không tồn tại: {method} {path}", code="NOT_FOUND")

    try:
        return handler(event)
    except NotImplementedError:
        return error_response(501, "Endpoint chưa implement", code="NOT_IMPLEMENTED")
    except Exception as exc:  # pylint: disable=broad-except
        logger.exception("unhandled error")
        return error_response(500, str(exc))
