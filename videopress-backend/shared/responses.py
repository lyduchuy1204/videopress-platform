"""Helper tạo response chuẩn API Gateway proxy integration.

Mọi handler nên return qua 2 helper này thay vì tự build dict, để đảm bảo
shape `{statusCode, body, headers}` đồng nhất + có CORS header chuẩn.
"""

import json
from typing import Any

# CORS header chuẩn — production có thể siết lại Origin từ env var.
_DEFAULT_HEADERS = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type,Authorization",
}


def success_response(body: Any, status_code: int = 200) -> dict[str, Any]:
    """Trả response thành công.

    Args:
        body: Object JSON-serializable (dict/list/str/int).
        status_code: 200 (default), 201 cho create, 204 cho no-content.

    Returns:
        Dict đúng format API Gateway proxy integration.
    """
    return {
        "statusCode": status_code,
        "headers": _DEFAULT_HEADERS,
        "body": json.dumps(body, default=str),
    }


def error_response(status_code: int, message: str, code: str = "INTERNAL_ERROR") -> dict[str, Any]:
    """Trả response lỗi với shape chuẩn.

    Args:
        status_code: HTTP status (4xx/5xx).
        message: Thông báo lỗi human-readable.
        code: Error code symbolic dành cho client parse (vd: "INVALID_TOKEN").
    """
    return {
        "statusCode": status_code,
        "headers": _DEFAULT_HEADERS,
        "body": json.dumps({"error": {"code": code, "message": message}}),
    }
