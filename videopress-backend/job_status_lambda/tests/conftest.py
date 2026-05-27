"""Fixtures cho job_status_lambda."""

from typing import Any

import pytest


@pytest.fixture(autouse=True)
def _mock_env(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("JOB_TABLE_NAME", "videopress-jobs-test")
    monkeypatch.setenv("AWS_REGION", "us-east-1")


@pytest.fixture
def api_event() -> dict[str, Any]:
    return {
        "httpMethod": "GET",
        "path": "/api/v1/jobs/01HXYZ",
        "pathParameters": {"id": "01HXYZ"},
        "headers": {"Authorization": "Bearer mock"},
        "requestContext": {"requestId": "test-request"},
    }
