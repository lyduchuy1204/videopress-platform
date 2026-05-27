"""Repository cho job status table."""

import os
from typing import Any

from shared.dynamo import DynamoRepository


class JobRepository(DynamoRepository):
    """CRUD job status.

    Schema:
        PK: job_id (string, ULID)
        Attrs: user_id, status, progress, mediaconvert_job_id, output_s3_key, ...
    """

    def __init__(self) -> None:
        super().__init__(table_name=os.environ["JOB_TABLE_NAME"])

    def get_for_user(self, job_id: str, user_id: str) -> dict[str, Any] | None:
        """Lấy job + verify ownership. Trả None nếu job không tồn tại
        hoặc không thuộc user (tránh leak existence).
        """
        raise NotImplementedError
