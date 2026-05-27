"""Test handler get_job_status."""

import json
from typing import Any


def test_get_returns_job_payload(api_event: dict[str, Any]) -> None:
    from handlers.get_job_status import handle  # pylint: disable=import-outside-toplevel

    response = handle(api_event)

    assert response["statusCode"] == 200
    body = json.loads(response["body"])
    assert body["id"] == "01HXYZ"
    assert "status" in body
    assert "progress" in body


def test_missing_id_returns_400() -> None:
    from handlers.get_job_status import handle  # pylint: disable=import-outside-toplevel

    response = handle({"httpMethod": "GET", "path": "/api/v1/jobs/", "pathParameters": None})
    assert response["statusCode"] == 400
