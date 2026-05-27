"""Fixtures cho upload_lambda."""

from typing import Any

import pytest


@pytest.fixture(autouse=True)
def _mock_env(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("UPLOAD_BUCKET_NAME", "videopress-uploads-test")
    monkeypatch.setenv("COMPRESSION_QUEUE_URL", "https://sqs.test/queue")
    monkeypatch.setenv("AWS_REGION", "us-east-1")


@pytest.fixture
def api_event() -> dict[str, Any]:
    return {
        "httpMethod": "POST",
        "path": "/api/v1/uploads/request",
        "body": '{"file_name":"video.mp4","content_type":"video/mp4"}',
        "headers": {"Authorization": "Bearer mock"},
        "requestContext": {"requestId": "test-request"},
    }
