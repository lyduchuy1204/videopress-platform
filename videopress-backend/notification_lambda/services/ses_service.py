"""Wrapper boto3 SES — gửi email transactional."""

import os
from typing import Any


class SesService:
    """Wrapper SES SendEmail / SendTemplatedEmail."""

    def __init__(self) -> None:
        self.from_address = os.environ["SES_FROM_ADDRESS"]
        # self._client = boto3.client("ses")  # TODO

    def send(
        self,
        to: str,
        subject: str,
        body_html: str,
        body_text: str,
    ) -> dict[str, Any]:
        """Gửi email plain (không template).

        Args:
            to: Email người nhận.
            subject: Tiêu đề.
            body_html: HTML body.
            body_text: Plain text body (fallback).

        Returns:
            dict {"message_id": "..."}
        """
        raise NotImplementedError

    def send_template(self, to: str, template_id: str, data: dict[str, Any]) -> dict[str, Any]:
        """Gửi qua SES template đã pre-define."""
        raise NotImplementedError
