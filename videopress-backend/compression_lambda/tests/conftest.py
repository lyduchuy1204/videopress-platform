"""Fixtures cho compression_lambda."""

from typing import Any

import pytest


@pytest.fixture(autouse=True)
def _mock_env(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("MEDIACONVERT_QUEUE_ARN", "arn:aws:mediaconvert:us-east-1:000:queues/test")
    monkeypatch.setenv("MEDIACONVERT_ROLE_ARN", "arn:aws:iam::000:role/test")
    monkeypatch.setenv("JOB_TABLE_NAME", "videopress-jobs-test")
    monkeypatch.setenv("OUTPUT_BUCKET_NAME", "videopress-outputs-test")


@pytest.fixture
def sqs_event() -> dict[str, Any]:
    return {
        "Records": [
            {
                "messageId": "msg-1",
                "body": '{"job_id":"01HXYZ","s3_key":"raw/video.mp4","user_id":"u-1"}',
                "attributes": {"ApproximateReceiveCount": "1"},
                "eventSource": "aws:sqs",
            }
        ]
    }
