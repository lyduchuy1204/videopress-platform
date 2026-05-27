"""Wrapper boto3 MediaConvert."""

import os
from typing import Any


class MediaConvertService:
    """MediaConvert CreateJob wrapper."""

    def __init__(self) -> None:
        self.queue_arn = os.environ["MEDIACONVERT_QUEUE_ARN"]
        self.role_arn = os.environ["MEDIACONVERT_ROLE_ARN"]
        # self._client = boto3.client("mediaconvert", endpoint_url=...)  # TODO

    def create_job(
        self, input_s3_uri: str, output_s3_prefix: str, preset: str = "h264-720p"
    ) -> str:
        """Tạo MediaConvert job. Trả mediaconvert_job_id."""
        raise NotImplementedError
