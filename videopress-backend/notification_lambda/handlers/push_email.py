"""POST /api/v1/notifications/push_email — gửi email qua SES (internal-only).

Endpoint này gọi từ lambda khác (không expose ra public). Có thể chuyển sang
SQS event source nếu volume lớn.
"""

from typing import Any

from shared.responses import success_response


def handle(event: dict[str, Any]) -> dict[str, Any]:
    """Gửi email qua SES.

    TODO: parse body {to, subject, template_id, data}, gọi ses_service.send().
    """
    return success_response({"message_id": "MOCK_MSG_ID", "status": "queued"})
