"""Upload Lambda — entry point.

Routes:
    POST /api/v1/uploads/request   → request_presigned_upload.handle
    POST /api/v1/uploads/confirm   → confirm_upload.handle

Flow upload:
    1. Client gọi POST /uploads/request → trả presigned URL S3 + job_id
    2. Client PUT file thẳng lên S3 bằng URL đó
    3. Client gọi POST /uploads/confirm với job_id → tạo SQS message
       cho compression_lambda xử lý.
"""

from typing import Any

from shared.logger import logger
from shared.responses import error_response

from handlers import confirm_upload, request_presigned_upload

_ROUTES = {
    ("POST", "/api/v1/uploads/request"): request_presigned_upload.handle,
    ("POST", "/api/v1/uploads/confirm"): confirm_upload.handle,
}


@logger.inject_lambda_context(correlation_id_path="requestContext.requestId")
def lambda_handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
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
