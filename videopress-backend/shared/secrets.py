"""AWS Secrets Manager helper với in-memory cache.

Lambda warm-start sẽ tận dụng cache → giảm cost + latency.
Cache TTL không cần thiết vì Lambda container có lifetime ngắn (~15 phút idle).
"""

from functools import lru_cache
from typing import Any


@lru_cache(maxsize=32)
def get_secret(name: str) -> str:
    """Lấy secret value từ AWS Secrets Manager. Cache giữa các invocation
    (cùng container Lambda warm).

    Args:
        name: Tên secret hoặc ARN. KHÔNG hardcode account ID — dùng tên.
              VD: "videopress/jwt-signing-key"

    Returns:
        Secret value dạng string. Caller tự parse JSON nếu cần.

    Raises:
        ClientError: secret không tồn tại / IAM thiếu quyền.

    TODO: implement với boto3.client("secretsmanager").get_secret_value().
    """
    raise NotImplementedError(f"get_secret({name!r}) chưa implement")


def get_secret_json(name: str) -> dict[str, Any]:
    """Wrapper trả secret đã parse JSON (cho secret kiểu key-value pair)."""
    import json

    return json.loads(get_secret(name))
