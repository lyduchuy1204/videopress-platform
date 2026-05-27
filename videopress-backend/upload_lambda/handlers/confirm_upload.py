"""POST /api/v1/uploads/confirm — client báo đã PUT xong, enqueue compression job."""

from typing import Any

from shared.responses import success_response


def handle(event: dict[str, Any]) -> dict[str, Any]:
    """Verify object đã tồn tại trên S3, push SQS message để compression_lambda chạy.

    TODO: parse job_id, head_object check, sqs.send_message().
    """
    return success_response({"job_id": "MOCK_JOB_ID", "status": "QUEUED"})
