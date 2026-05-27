# Lambda Conventions — videopress-backend

> **Audience**: Backend dev mới join repo. Đọc xong file này hiểu cách viết 1 lambda đúng convention.

Tài liệu này chuẩn hoá cách viết, structure, đặt tên, log, handle error, test cho mọi lambda trong repo. Khi tạo lambda mới, đọc thêm [`adding-new-lambda.md`](./adding-new-lambda.md).

---

## 1. Entry point

- **File**: `app.py` ở root mỗi `*_lambda/`.
- **Function**: `lambda_handler(event, context)` — đúng chữ ký AWS Lambda yêu cầu.
- **Decorator**: dùng `@logger.inject_lambda_context(correlation_id_path="requestContext.requestId")` để propagate request ID vào mọi log line.

```python
from shared.logger import logger

@logger.inject_lambda_context(correlation_id_path="requestContext.requestId")
def lambda_handler(event, context):
    ...
```

---

## 2. Routing trong app.py

Mỗi lambda phục vụ **nhiều endpoint cùng resource group** (vd: `auth_lambda` xử lý tất cả `/api/v1/auth/*`). Dùng dict `_ROUTES` map `(method, path)` → `handler.handle`.

```python
_ROUTES = {
    ("POST", "/api/v1/auth/login"): login.handle,
    ("POST", "/api/v1/auth/logout"): logout.handle,
}

handler = _ROUTES.get((event["httpMethod"], event["path"]))
if handler is None:
    return error_response(404, "...", code="NOT_FOUND")
return handler(event)
```

> Path có `{id}` như `/api/v1/jobs/{id}`: dùng `event["pathParameters"]["id"]`, route bằng `path.startswith(...)`.

---

## 3. Handler pattern

- 1 file = 1 endpoint trong `handlers/`.
- Function entry tên `handle(event)` — KHÔNG phải `handler` (tránh trùng module).
- Handler **KHÔNG** trực tiếp gọi boto3 — phải qua `services/` để mock được.
- Handler return dict đúng shape API Gateway proxy (qua `success_response` / `error_response`).

```python
# handlers/login.py
def handle(event: dict) -> dict:
    body = json.loads(event.get("body") or "{}")
    # validate qua pydantic model (chưa skeleton)
    tokens = cognito_service.login(body["email"], body["password"])
    return success_response(tokens)
```

---

## 4. Response shape

Dùng `shared.responses.success_response()` và `error_response()`. KHÔNG tự build dict.

**Success:**
```json
{
  "statusCode": 200,
  "headers": { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
  "body": "{...JSON...}"
}
```

**Error:**
```json
{
  "statusCode": 400,
  "headers": {...},
  "body": "{\"error\":{\"code\":\"INVALID_INPUT\",\"message\":\"email is required\"}}"
}
```

Error code dùng UPPER_SNAKE_CASE, có ý nghĩa cho client parse: `INVALID_TOKEN`, `NOT_FOUND`, `RATE_LIMITED`, `INTERNAL_ERROR`.

---

## 5. Error handling

- **Validation error** (input sai shape) → `400` + `INVALID_INPUT`.
- **Auth error** → `401` + `UNAUTHORIZED` hoặc `403` + `FORBIDDEN`.
- **Not found** → `404` + `NOT_FOUND` (kể cả khi resource tồn tại nhưng user không own → trả 404 để chống enumeration).
- **NotImplementedError** → `501` + `NOT_IMPLEMENTED` (handler skeleton).
- **Catch-all `Exception`** trong `app.py` → `500` + log full traceback bằng `logger.exception()`.

```python
try:
    return handler(event)
except NotImplementedError:
    return error_response(501, "Endpoint chưa implement", code="NOT_IMPLEMENTED")
except Exception as exc:
    logger.exception("unhandled error")
    return error_response(500, str(exc))
```

> SQS lambda (`compression_lambda`) **KHÔNG** catch exception — phải để raise hoặc return `batchItemFailures` để SQS retry.

---

## 6. Logging với correlation ID

- Dùng `from shared.logger import logger` — KHÔNG `import logging` standard library.
- Powertools tự inject correlation_id vào mọi log nếu dùng decorator ở đầu `lambda_handler`.
- Format JSON structured (CloudWatch Logs Insights query dễ hơn).

```python
logger.info("user login", extra={"user_email": email})
logger.warning("rate limit hit", extra={"user_id": user_id, "endpoint": "login"})
logger.exception("dynamodb call failed")  # auto include traceback
```

**KHÔNG log:**
- Password, JWT raw, OTP code, secret key
- AWS account ID, ARN đầy đủ (chỉ log resource name)
- PII không cần thiết (email full → mask `a***@example.com` nếu log production)

---

## 7. Secret loading

Dùng `shared.secrets.get_secret(name)` — đã cache LRU, gọi nhiều lần OK.

```python
from shared.secrets import get_secret, get_secret_json

jwt_key = get_secret("videopress/jwt-signing-key")
db_creds = get_secret_json("videopress/db-credentials")  # {"username":..., "password":...}
```

KHÔNG đọc secret trong import time module (fail nếu Lambda cold-start không có IAM tạm thời). Đọc lazy trong function lần đầu cần.

---

## 8. Environment variable

Đọc từ `os.environ["VAR_NAME"]` — fail-fast nếu thiếu (Lambda không khởi động được). Tên var UPPER_SNAKE_CASE, có prefix domain:

| Pattern | Ví dụ |
|---|---|
| Resource name | `JOB_TABLE_NAME`, `UPLOAD_BUCKET_NAME` |
| Resource URL/ARN | `COMPRESSION_QUEUE_URL`, `MEDIACONVERT_QUEUE_ARN` |
| Service config | `COGNITO_USER_POOL_ID`, `SES_FROM_ADDRESS` |

KHÔNG đọc env var có default fallback hardcode account ID/region.

---

## 9. Testing pattern

- **Framework**: pytest + pytest-mock + moto (mock boto3).
- **Layout**: `tests/conftest.py` cho fixtures, `tests/test_<module>.py` cho test.
- **Naming**: `test_<scenario>_<expected>()`. VD: `test_login_with_invalid_password_returns_401()`.
- **Auto-mock env**: mọi test có fixture `_mock_env` autouse → set env var.
- **AAA pattern**: Arrange / Act / Assert, mỗi test 1 ý.

```python
def test_login_with_valid_creds_returns_tokens(api_event, mocker):
    # Arrange
    mock_cognito = mocker.patch("services.cognito_service.CognitoService.login")
    mock_cognito.return_value = {"AccessToken": "abc", "RefreshToken": "def"}

    # Act
    response = handle(api_event)

    # Assert
    assert response["statusCode"] == 200
    assert "access_token" in json.loads(response["body"])
```

**Coverage**: tối thiểu **70%** — CI fail nếu thấp hơn. Mục tiêu thực tế **80%+** cho code quan trọng (auth, secrets).

---

## 10. Type hints

- Bật cho function public (handler, service method).
- Dùng built-in generic Python 3.11: `dict[str, Any]`, `list[str]`, `str | None`.
- KHÔNG dùng `typing.Dict`, `typing.List` (deprecated style).
- Run `make typecheck` trước khi push — mypy phải pass.

---

## 11. Docstring

- Module: 1 dòng tóm tắt + ví dụ event/response nếu là handler.
- Function public: docstring Google style (`Args:`, `Returns:`, `Raises:`).
- Skeleton chưa implement: ghi `TODO:` rõ ràng để pylint không complain mà reviewer biết.

---

## 12. Dependency

- `requirements.txt` per lambda — chỉ deps **runtime** (KHÔNG có pytest, mypy, black).
- Pin version: `aws-lambda-powertools>=2.30,<3.0` (cho phép patch, chặn major).
- Dev deps tập trung ở `pyproject.toml` `[project.optional-dependencies] dev`.
- Layer chung (`videopress-common-layer`) chứa `aws-lambda-powertools`, `pydantic`, `boto3` mới — KHÔNG đóng cùng zip.

---

Có gì chưa rõ → hỏi `#videopress-backend` Slack.
