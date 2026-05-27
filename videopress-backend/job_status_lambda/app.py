"""Job Status Lambda — entry point.

Routes:
    GET /api/v1/jobs/{id} → get_job_status.handle

Example event (API Gateway proxy + path parameter):
    {
        "httpMethod": "GET",
        "path": "/api/v1/jobs/01HXYZ",
        "pathParameters": {"id": "01HXYZ"},
        "headers": {"Authorization": "Bearer ..."}
    }
"""

from typing import Any

from shared.logger import logger
from shared.responses import error_response

from handlers import get_job_status


@logger.inject_lambda_context(correlation_id_path="requestContext.requestId")
def lambda_handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    method = event.get("httpMethod", "")
    path = event.get("path", "")
    logger.info("incoming request", extra={"method": method, "path": path})

    # Path là /api/v1/jobs/{id} → match prefix
    if method == "GET" and path.startswith("/api/v1/jobs/"):
        try:
            return get_job_status.handle(event)
        except NotImplementedError:
            return error_response(501, "Endpoint chưa implement", code="NOT_IMPLEMENTED")
        except Exception as exc:  # pylint: disable=broad-except
            logger.exception("unhandled error")
            return error_response(500, str(exc))

    return error_response(404, f"Route không tồn tại: {method} {path}", code="NOT_FOUND")
