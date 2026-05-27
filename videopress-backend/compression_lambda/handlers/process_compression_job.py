"""Process 1 compression job từ SQS message body."""

from typing import Any

from shared.logger import logger


def handle(message_body: dict[str, Any]) -> None:
    """Xử lý 1 video compression job.

    Args:
        message_body: dict đã parse từ SQS record.body, có shape:
            {
                "job_id": "01HXYZ...",
                "s3_key": "raw/user-123/video.mp4",
                "user_id": "user-123",
                "preset": "h264-720p"  # optional
            }

    TODO:
        1. Validate input
        2. Update job status PENDING → PROCESSING (DynamoDB)
        3. Gọi MediaConvert CreateJob với input s3 + output preset
        4. Update job với mediaconvert_job_id
        5. Lambda kết thúc — completion sẽ được EventBridge handle riêng
    """
    job_id = message_body.get("job_id")
    logger.info("compression job started", extra={"job_id": job_id})
    raise NotImplementedError("MediaConvert integration chưa implement")
