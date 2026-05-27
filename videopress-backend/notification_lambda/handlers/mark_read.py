"""POST /api/v1/notifications/mark_read — đánh dấu đã đọc."""

from typing import Any

from shared.responses import success_response


def handle(event: dict[str, Any]) -> dict[str, Any]:
    """Update flag read=true cho 1 hoặc nhiều notification id.

    TODO: parse body {ids: [...]}, gọi repository.mark_read(user_id, ids).
    """
    return success_response({"updated": 0})
