# Thêm Lambda mới — Step-by-step

> **Khi nào**: cần endpoint mới không thuộc resource group hiện có (auth/notification/upload/compression/job_status), hoặc có event source mới (Kinesis, EventBridge…). Nếu chỉ thêm endpoint cùng resource group → thêm handler vào lambda hiện có thay vì tạo lambda mới.

---

## Checklist nhanh

- [ ] Tạo folder `<name>_lambda/` ở root repo
- [ ] Copy template từ lambda gần nhất (vd: `authentication_lambda` cho HTTP, `compression_lambda` cho SQS)
- [ ] Update `pyproject.toml` `[tool.pytest.ini_options]` testpaths
- [ ] Update `Makefile` biến `LAMBDAS`
- [ ] Update `Jenkinsfile.ci` mảng `lambdas`
- [ ] Update Terraform IaC (repo `videopress-infrastructure`)
- [ ] Test local + PR

---

## 1. Tạo skeleton folder

```bash
NAME=my_new   # đặt tên theo domain, snake_case, KHÔNG đuôi `_lambda` lặp lại
mkdir -p ${NAME}_lambda/{handlers,services,tests}
touch ${NAME}_lambda/handlers/__init__.py
touch ${NAME}_lambda/services/__init__.py
touch ${NAME}_lambda/tests/__init__.py
```

## 2. Copy template

Cách nhanh: copy 1 lambda gần giống, đổi tên + xoá handler không cần.

```bash
cp -r authentication_lambda/{app.py,handlers,services,tests,requirements.txt,README.md} ${NAME}_lambda/
```

Sau đó sửa:
- `app.py`: route table mới
- `handlers/`: 1 file/endpoint
- `services/`: wrapper boto3 mới (nếu có)
- `tests/conftest.py`: env var fixture
- `README.md`: bảng endpoint, IAM, env vars
- `requirements.txt`: deps runtime tối thiểu

## 3. Update pyproject.toml

Thêm path test vào `[tool.pytest.ini_options].testpaths`:

```toml
testpaths = [
    "shared",
    "authentication_lambda/tests",
    # ...
    "my_new_lambda/tests",   # ← thêm
]
```

Và `[tool.coverage.run].source`:

```toml
source = [
    # ...
    "my_new_lambda",   # ← thêm
]
```

## 4. Update Makefile

```makefile
LAMBDAS := authentication_lambda notification_lambda upload_lambda compression_lambda job_status_lambda my_new_lambda
```

## 5. Update Jenkinsfile.ci

```groovy
pythonLambdaPipeline(
    lambdas: [
        'authentication_lambda',
        // ...
        'my_new_lambda',   // ← thêm
    ],
    // ...
)
```

## 6. Test local

```bash
make lint
make test            # phải pass + coverage >= 70%
make package         # build zip
ls -lh dist/my_new_lambda.zip
```

## 7. Update IaC (repo `videopress-infrastructure`)

Sang repo Terraform, thêm:
- Module `aws_lambda_function` cho lambda mới
- IAM role + policy
- API Gateway route (nếu HTTP) hoặc event source mapping (nếu SQS/Kinesis)
- DynamoDB table / S3 bucket / SQS queue mới (nếu cần)
- Output ARN/URL để wire với resource khác

PR riêng cho repo `videopress-infrastructure`.

## 8. PR + review

- Branch: `feat/<name>-lambda` (vd: `feat/transcription-lambda`)
- Mô tả rõ: endpoint mới, lý do tách lambda riêng (tại sao không gộp vào lambda cũ)
- Tag reviewer: `@videopress-org/backend-leads`
- Sau merge: trigger Jenkins → upload artifact → deploy qua repo IaC
