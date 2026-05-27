"""Test handler request_presigned_upload."""

import json
from typing import Any


def test_request_returns_presigned_url(api_event: dict[str, Any]) -> None:
    from handlers.request_presigned_upload import handle  # pylint: disable=import-outside-toplevel

    response = handle(api_event)

    assert response["statusCode"] == 200
    body = json.loads(response["body"])
    assert "upload_url" in body
    assert "job_id" in body
    assert body["expires_in"] == 900
