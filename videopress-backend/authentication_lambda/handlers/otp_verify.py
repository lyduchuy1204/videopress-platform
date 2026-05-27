"""POST /api/v1/auth/otp_verify — verify OTP code (MFA / passwordless)."""

from typing import Any

from shared.responses import success_response


def handle(event: dict[str, Any]) -> dict[str, Any]:
    """Verify OTP 6 chữ số gửi qua SES email.

    TODO: lookup OTP trong DynamoDB, check expiry, mark consumed, issue token.
    """
    return success_response({"verified": True, "session_token": "MOCK_SESSION"})
