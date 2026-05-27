"""POST /api/v1/uploads/request — generate presigned URL S3 cho client PUT."""

from typing import Any

from shared.responses import success_response


def handle(event: dict[str, Any]) -> dict[str, Any]:
    """Tạo presigned URL S3 PUT (TTL 15 phút), trả kèm job_id.

    TODO: validate file_name + content_type, generate job_id (ULID),
    gọi s3_client.generate_presigned_url("put_object", ...).
    """
    return success_response(
        {
            "job_id": "MOCK_JOB_ID",
            "upload_url": "https://s3.amazonaws.com/mock-bucket/mock-key?X-Amz-Signature=...",
            "expires_in": 900,
        }
    )
