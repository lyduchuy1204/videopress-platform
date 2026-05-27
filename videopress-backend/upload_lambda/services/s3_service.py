"""Wrapper boto3 S3 — generate presigned URL + head_object."""

import os


class S3Service:
    """S3 operations cần cho upload flow."""

    def __init__(self) -> None:
        self.bucket = os.environ["UPLOAD_BUCKET_NAME"]
        # self._client = boto3.client("s3")  # TODO

    def generate_presigned_put_url(
        self, key: str, content_type: str, expires_in: int = 900
    ) -> str:
        """Generate presigned URL cho PUT object."""
        raise NotImplementedError

    def object_exists(self, key: str) -> bool:
        """Check S3 object đã được upload chưa (head_object)."""
        raise NotImplementedError
