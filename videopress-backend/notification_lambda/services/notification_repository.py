"""Repository pattern cho notification table (DynamoDB)."""

import os
from typing import Any

from shared.dynamo import DynamoRepository


class NotificationRepository(DynamoRepository):
    """CRUD cho table notification.

    Schema:
        PK: user_id (string)
        SK: notif_id (string, ULID)
        Attrs: type, message, read, created_at, payload
    """

    def __init__(self) -> None:
        super().__init__(table_name=os.environ["NOTIFICATION_TABLE_NAME"])

    def list_by_user(
        self, user_id: str, limit: int = 20, cursor: str | None = None
    ) -> dict[str, Any]:
        """Query notif của 1 user, paginate theo cursor (LastEvaluatedKey)."""
        raise NotImplementedError

    def mark_read(self, user_id: str, notif_ids: list[str]) -> int:
        """Update read=True cho nhiều notif. Trả số bản ghi đã update."""
        raise NotImplementedError
