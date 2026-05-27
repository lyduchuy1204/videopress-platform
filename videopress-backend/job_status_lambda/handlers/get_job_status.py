"""GET /api/v1/jobs/{id} — query job status từ DynamoDB."""

from typing import Any

from shared.responses import error_response, success_response


def handle(event: dict[str, Any]) -> dict[str, Any]:
    """Lấy job theo ID, check ownership (job phải thuộc user trong JWT).

    TODO: parse JWT → user_id, query DynamoDB, validate ownership,
    return { id, status, progress, output_url? }.
    """
    path_params = event.get("pathParameters") or {}
    job_id = path_params.get("id")
    if not job_id:
        return error_response(400, "Missing job id", code="INVALID_REQUEST")

    # Mock response — sẽ thay bằng query DynamoDB
    return success_response(
        {
            "id": job_id,
            "status": "PROCESSING",
            "progress": 42,
            "output_url": None,
            "created_at": "2026-01-01T00:00:00Z",
        }
    )
