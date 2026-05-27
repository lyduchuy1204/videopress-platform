"""Wrapper boto3 cognito-idp. Tách ra service để mock dễ trong test."""

import os
from typing import Any


class CognitoService:
    """Wrapper các operation Cognito IDP cần dùng.

    Đọc User Pool ID + Client ID từ env var (do Terraform inject), KHÔNG hardcode.
    """

    def __init__(self) -> None:
        self.user_pool_id = os.environ["COGNITO_USER_POOL_ID"]
        self.client_id = os.environ["COGNITO_CLIENT_ID"]
        # self._client = boto3.client("cognito-idp")  # TODO

    def login(self, email: str, password: str) -> dict[str, Any]:
        """Initiate USER_PASSWORD_AUTH flow."""
        raise NotImplementedError

    def refresh(self, refresh_token: str) -> dict[str, Any]:
        """Initiate REFRESH_TOKEN_AUTH flow."""
        raise NotImplementedError

    def global_sign_out(self, access_token: str) -> None:
        """Revoke tất cả token của user."""
        raise NotImplementedError
