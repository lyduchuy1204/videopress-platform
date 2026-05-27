"""GET /api/v1/notifications — list notification của user hiện tại."""

from typing import Any

from shared.responses import success_response


def handle(event: dict[str, Any]) -> dict[str, Any]:
    """Query DynamoDB notification table theo user_id (từ JWT claims).

    TODO: parse JWT từ Authorization header, query repository, paginate.
    """
    return success_response(
        {
            "items": [
                {
                    "id": "notif-1",
                    "type": "JOB_COMPLETED",
                    "message": "Video của bạn đã nén xong",
                    "read": False,
                    "created_at": "2026-01-01T00:00:00Z",
                }
            ],
            "next_cursor": None,
        }
    )
