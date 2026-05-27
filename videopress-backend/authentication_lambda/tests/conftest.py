"""Fixtures dùng chung cho test authentication_lambda."""

import os
from typing import Any

import pytest


@pytest.fixture(autouse=True)
def _mock_env(monkeypatch: pytest.MonkeyPatch) -> None:
    """Tự động set env var cho mọi test (không cần Terraform inject thật)."""
    monkeypatch.setenv("COGNITO_USER_POOL_ID", "us-east-1_TESTPOOL")
    monkeypatch.setenv("COGNITO_CLIENT_ID", "test-client-id")
    monkeypatch.setenv("AWS_REGION", "us-east-1")


@pytest.fixture
def api_event() -> dict[str, Any]:
    """Dummy API Gateway proxy event."""
    return {
        "httpMethod": "POST",
        "path": "/api/v1/auth/login",
        "body": '{"email":"test@example.com","password":"test123"}',
        "headers": {"Content-Type": "application/json"},
        "requestContext": {"requestId": "test-request-id"},
    }
