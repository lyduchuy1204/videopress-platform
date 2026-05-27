"""JWT decode helper - verify token Cognito issued.

Dùng cho mọi lambda cần authorize request từ API Gateway. Lambda authorizer
chính sẽ gọi `decode_jwt()` để verify token và trả về payload (sub, email, scope).
"""

from typing import Any


def decode_jwt(token: str) -> dict[str, Any]:
    """Decode + verify JWT từ Cognito.

    Args:
        token: Raw JWT string từ Authorization header (đã strip "Bearer ").

    Returns:
        Payload dict chứa `sub`, `email`, `cognito:groups`, `exp`…

    Raises:
        ValueError: token invalid / expired / signature sai.

    TODO: implement verify với Cognito JWKS (cache key 1h).
    """
    # Placeholder — sẽ implement sau khi có Cognito User Pool ID từ Terraform.
    raise NotImplementedError("decode_jwt chưa implement — cần Cognito JWKS endpoint")
