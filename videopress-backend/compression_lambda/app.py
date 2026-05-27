"""Compression Lambda — SQS-triggered worker (KHÔNG phải HTTP).

Lambda này được trigger bởi SQS event source mapping. Mỗi message tương ứng
với 1 video cần nén. Lambda gọi MediaConvert tạo job, update DynamoDB.

Example event (SQS):
    {
        "Records": [
            {
                "messageId": "msg-1",
                "body": "{\"job_id\":\"01HXYZ\",\"s3_key\":\"raw/video.mp4\"}",
                "attributes": {...}
            }
        ]
    }

Lambda KHÔNG return HTTP response. Chỉ raise exception nếu fail (SQS sẽ retry
theo redrive policy + DLQ).
"""

import json
from typing import Any

from shared.logger import logger

from handlers import process_compression_job


@logger.inject_lambda_context
def lambda_handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    """Process SQS batch. Trả batchItemFailures cho partial failure."""
    failed_message_ids: list[dict[str, str]] = []

    for record in event.get("Records", []):
        message_id = record.get("messageId", "unknown")
        try:
            body = json.loads(record["body"])
            logger.info("processing job", extra={"message_id": message_id, "job_id": body.get("job_id")})
            process_compression_job.handle(body)
        except Exception as exc:  # pylint: disable=broad-except
            logger.exception(
                "compression job failed",
                extra={"message_id": message_id, "error": str(exc)},
            )
            failed_message_ids.append({"itemIdentifier": message_id})

    # SQS partial batch response — message thành công sẽ delete khỏi queue,
    # message fail sẽ retry hoặc vào DLQ.
    return {"batchItemFailures": failed_message_ids}
