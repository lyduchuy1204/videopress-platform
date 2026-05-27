"""Test SQS batch handler — partial failure."""

from typing import Any


def test_failed_job_returns_batch_item_failure(sqs_event: dict[str, Any]) -> None:
    """Khi handler raise NotImplementedError, message phải nằm trong
    batchItemFailures để SQS retry.
    """
    from app import lambda_handler  # pylint: disable=import-outside-toplevel

    response = lambda_handler(sqs_event, context=None)

    assert "batchItemFailures" in response
    # Skeleton handle() raise NotImplementedError → message-1 fail
    assert any(item["itemIdentifier"] == "msg-1" for item in response["batchItemFailures"])
