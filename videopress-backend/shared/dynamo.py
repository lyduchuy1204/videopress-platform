"""DynamoDB repository pattern wrapper.

Tách logic CRUD DynamoDB ra khỏi handler để dễ test (mock repo dễ hơn mock boto3).
"""

from typing import Any, Optional


class DynamoRepository:
    """Repository pattern wrapper cho 1 DynamoDB table.

    Usage:
        repo = DynamoRepository(table_name="videopress-jobs-uat")
        item = repo.get_item({"job_id": "abc-123"})
        repo.put_item({"job_id": "abc-123", "status": "PENDING"})

    TODO: implement với boto3.resource("dynamodb").Table(name).
    """

    def __init__(self, table_name: str) -> None:
        """Init repo cho 1 table cụ thể.

        Args:
            table_name: Tên DynamoDB table (đọc từ env var, KHÔNG hardcode).
        """
        self.table_name = table_name
        # self._table = boto3.resource("dynamodb").Table(table_name)  # TODO

    def get_item(self, key: dict[str, Any]) -> Optional[dict[str, Any]]:
        """Lấy 1 item theo primary key. Trả None nếu không tồn tại."""
        raise NotImplementedError

    def put_item(self, item: dict[str, Any]) -> None:
        """Upsert 1 item."""
        raise NotImplementedError

    def query(self, **kwargs: Any) -> list[dict[str, Any]]:
        """Query theo partition key + sort key condition."""
        raise NotImplementedError

    def delete_item(self, key: dict[str, Any]) -> None:
        """Xoá 1 item theo primary key."""
        raise NotImplementedError
