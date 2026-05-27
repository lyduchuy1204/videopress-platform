"""Fixtures cho notification_lambda."""

from typing import Any

import pytest


@pytest.fixture(autouse=True)
def _mock_env(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("NOTIFICATION_TABLE_NAME", "videopress-notifications-test")
    monkeypatch.setenv("SES_FROM_ADDRESS", "no-reply@videopress.test")
    monkeypatch.setenv("AWS_REGION", "us-east-1")


@pytest.fixture
def api_event() -> dict[str, Any]:
    return {
        "httpMethod": "GET",
        "path": "/api/v1/notifications",
        "queryStringParameters": {"limit": "20"},
        "headers": {"Authorization": "Bearer mock-jwt"},
        "requestContext": {"requestId": "test-request"},
    }
