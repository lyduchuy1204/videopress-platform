# `shared/` — code chung giữa các Lambda

Folder này chứa module Python được **mọi lambda** trong repo dùng chung. Khi `make package` chạy, toàn bộ folder `shared/` sẽ được **copy thật** vào root của từng zip artifact (Lambda zip không hiểu symlink).

## 📂 File trong folder

| File | Vai trò | Khi nào dùng |
|---|---|---|
| `logger.py` | Wrapper [AWS Lambda Powertools Logger](https://docs.powertools.aws.dev/lambda/python/latest/core/logger/) với service name chuẩn | Mọi nơi cần log |
| `auth.py` | `decode_jwt(token)` verify JWT từ Cognito | Lambda authorizer + handler nào cần kiểm tra user |
| `dynamo.py` | `DynamoRepository` class — CRUD wrapper cho 1 table | Handler nào đọc/ghi DynamoDB |
| `responses.py` | `success_response()`, `error_response()` — chuẩn shape API Gateway | Handler HTTP (auth/notification/upload/job_status) |
| `secrets.py` | `get_secret(name)` cached LRU — đọc từ Secrets Manager | Bất kỳ chỗ nào cần secret |

## 🔌 Convention import từ lambda

Trong file lambda (sau khi `make package` copy `shared/` vào):

```python
from shared.logger import logger
from shared.responses import success_response, error_response
from shared.auth import decode_jwt
from shared.dynamo import DynamoRepository
from shared.secrets import get_secret
```

> ⚠️ **KHÔNG** import bằng đường dẫn tương đối kiểu `from ..shared`. Khi build zip, `shared/` nằm cùng cấp với `app.py` nên import tuyệt đối là chuẩn.

## 🧪 Test convention

Test cho `shared/` đặt ở `tests/shared/` (top-level repo, KHÔNG trong từng lambda) để tránh duplicate.

```bash
pytest tests/shared/ -v --cov=shared
```

Mỗi module nên có > 80% coverage vì là code dùng chung — bug ở đây ảnh hưởng tất cả lambda.

## ⚠️ Quy tắc khi sửa shared/

1. **Mọi PR sửa `shared/` cần backend lead review** (đã set trong `CODEOWNERS`).
2. KHÔNG thêm dependency mới vào `shared/` mà không cập nhật `requirements.txt` của tất cả 5 lambda.
3. KHÔNG để state global mutable — Lambda container reuse có thể leak state giữa các invocation.
4. Function trong `shared/` phải **idempotent** và **thread-safe** (Lambda có thể chạy concurrent trong cùng container ở mode provisioned concurrency).

## 📦 Dependency runtime

`shared/` cần các package sau (đã có trong `videopress-common-layer` hoặc `requirements.txt` của từng lambda):

- `aws-lambda-powertools>=2.30`
- `boto3` (có sẵn trong Lambda runtime)
- `pydantic>=2.0` (cho validation, sẽ thêm khi cần)
