"""Test handler list_notifications."""

import json
from typing import Any


def test_list_returns_items(api_event: dict[str, Any]) -> None:
    from handlers.list_notifications import handle  # pylint: disable=import-outside-toplevel

    response = handle(api_event)

    assert response["statusCode"] == 200
    body = json.loads(response["body"])
    assert "items" in body
    assert isinstance(body["items"], list)
