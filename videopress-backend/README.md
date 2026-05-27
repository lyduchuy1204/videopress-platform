# videopress-backend

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)](#)
[![Coverage](https://img.shields.io/badge/coverage-70%25-yellow)](#)
[![Python](https://img.shields.io/badge/python-3.11-blue)](#)
[![Powertools](https://img.shields.io/badge/aws--lambda--powertools-2.x-orange)](#)

> **Repo 1 / 4** của VideoPress Platform. Chứa source code Python cho 5 AWS Lambda function: `authentication`, `notification`, `upload`, `compression`, `job_status`.

---

## 📑 Mục lục

1. [Mục đích repo](#-mục-đích-repo)
2. [Tech stack](#-tech-stack)
3. [Cấu trúc folder](#-cấu-trúc-folder)
4. [Quick start](#-quick-start)
5. [Testing convention](#-testing-convention)
6. [Build & Package](#-build--package)
7. [CI/CD](#-cicd)
8. [Secrets & Environment](#-secrets--environment)
9. [Contributing](#-contributing)
10. [Owner & Liên hệ](#-owner--liên-hệ)
11. [Liên kết các repo khác](#-liên-kết-các-repo-khác)

---

## 🎯 Mục đích repo

Repo này chứa **toàn bộ application code Python** chạy trên AWS Lambda cho hệ thống VideoPress (API nén video Serverless dùng Private API Gateway + Cognito + DynamoDB + MediaConvert).

> 📘 Spec chi tiết kiến trúc tổng thể: xem `IDEA.md` ở meta repo [`../videopress-platform-docs/`](../videopress-platform-docs/IDEA.md), section **"Repo 1 — videopress-backend (Python Lambda)"**.

Repo này **CHỈ** chứa code application. Hạ tầng (VPC, API Gateway, IAM, DynamoDB, S3) nằm ở repo `videopress-infrastructure`. Pipeline Jenkins shared library nằm ở repo `videopress-cicd`.

**Phạm vi của repo:**

- ✅ Source code Python cho 5 lambda function
- ✅ Shared modules (`shared/`) dùng chung giữa các lambda
- ✅ Unit test + integration test (pytest, mock boto3)
- ✅ Build script đóng gói `*.zip` artifact để Terraform deploy
- ✅ Dev tooling: black, pylint, mypy, coverage
- ❌ KHÔNG chứa Terraform code
- ❌ KHÔNG chứa Jenkins pipeline definition (chỉ có `Jenkinsfile.ci` gọi shared library)
- ❌ KHÔNG chứa AWS account ID, region cụ thể, ARN hardcoded

---

## 🏗️ Tech stack

| Layer | Tool | Version |
|---|---|---|
| Runtime | Python | **3.11** (khớp Lambda runtime `python3.11`) |
| Dependency mgmt | `pip-tools` hoặc `poetry` | latest |
| Test framework | `pytest` + `pytest-cov` | >= 8.0 |
| Type checker | `mypy` | >= 1.8 |
| Formatter | `black` | line-length 100 |
| Linter | `pylint` | >= 3.0 |
| Lambda framework | [AWS Lambda Powertools](https://docs.powertools.aws.dev/lambda/python/) | >= 2.30 |
| Validation | `pydantic` | >= 2.0 |

---

## 📂 Cấu trúc folder

```
videopress-backend/
├── README.md                         ← bạn đang đọc
├── pyproject.toml                    ← shared dev deps + tool config
├── Makefile                          ← make install | test | lint | package
├── Jenkinsfile.ci                    ← gọi shared library Jenkins
├── .python-version                   ← 3.11
├── .gitignore
├── .github/
│   ├── CODEOWNERS
│   └── pull_request_template.md
├── shared/                           ← module chung
│   ├── __init__.py
│   ├── logger.py                     ← AWS Lambda Powertools wrapper
│   ├── auth.py                       ← decode JWT từ Cognito
│   ├── dynamo.py                     ← repository pattern cho DynamoDB
│   ├── responses.py                  ← chuẩn shape API Gateway response
│   ├── secrets.py                    ← Secrets Manager (cached)
│   └── README.md
├── authentication_lambda/            ← /api/v1/auth/*
├── notification_lambda/              ← /api/v1/notifications/*
├── upload_lambda/                    ← /api/v1/uploads/*
├── compression_lambda/               ← SQS-triggered worker
├── job_status_lambda/                ← /api/v1/jobs/{id}
└── docs/
    ├── lambda-conventions.md
    └── adding-new-lambda.md
```

Mỗi `*_lambda/` có cấu trúc giống nhau:

```
authentication_lambda/
├── app.py                ← entry point: app.lambda_handler
├── handlers/             ← 1 file = 1 endpoint
├── services/             ← wrap I/O (Cognito, DynamoDB, SES…)
├── tests/                ← pytest, conftest, fixtures
├── requirements.txt      ← deps runtime (KHÔNG có dev deps)
└── README.md
```

---

## 🚀 Quick start

```bash
# Clone repo
git clone git@github.com:videopress/videopress-backend.git
cd videopress-backend

# Cài đặt môi trường + dev deps
make install

# Chạy test toàn bộ
make test

# Lint + format + typecheck
make lint
make format
make typecheck

# Build zip artifact cho 1 lambda hoặc tất cả
make package
```

> Yêu cầu: Python 3.11 đã cài qua `pyenv` hoặc tương đương. File `.python-version` đã pin sẵn.

---

## 🧪 Testing convention

- **Framework**: `pytest` + `pytest-cov`
- **Vị trí**: mỗi lambda có folder `tests/` riêng; shared/ test nằm ở `tests/shared/` (top-level).
- **Naming**: `test_<module>.py`, function `test_<scenario>_<expected>()`.
- **Fixtures**: dùng `conftest.py` mock `boto3.client`, dummy event API Gateway, dummy SQS record.
- **Coverage tối thiểu**: **70%** per lambda. CI sẽ fail nếu thấp hơn.
- **Mock convention**: dùng `moto` cho AWS service mocks; `pytest-mock` cho monkeypatch.
- **KHÔNG gọi AWS thật** trong unit test. Integration test (gọi real AWS UAT) chạy riêng ở Jenkins stage `integration`.

```bash
# Chạy test 1 lambda
pytest authentication_lambda/tests/ -v

# Chạy test với coverage report HTML
make test
open htmlcov/index.html
```

---

## 📦 Build & Package

Lambda zip được build qua `make package`. Flow:

1. Tạo folder tạm `dist/<lambda_name>/`.
2. **Copy `shared/` vào root của folder tạm** (Lambda zip không hiểu symlink, phải copy thật).
3. Copy toàn bộ source code lambda (`app.py`, `handlers/`, `services/`).
4. Cài deps từ `requirements.txt` vào folder tạm bằng `pip install -r requirements.txt -t .`.
5. Đóng gói thành `dist/<lambda_name>.zip`.
6. Repo `videopress-infrastructure` sẽ upload zip lên S3 artifact bucket và deploy qua `aws_lambda_function`.

> 💡 Lambda Layer chung (`videopress-common-layer`) build từ folder `layer/` (sẽ thêm sau) — chứa `aws-lambda-powertools`, `pydantic`, `boto3` mới. Layer publish qua Jenkins job riêng, KHÔNG đóng kèm zip lambda.

---

## 🤖 CI/CD

- **Pipeline**: file [`Jenkinsfile.ci`](./Jenkinsfile.ci) ở root repo.
- **Shared library**: tất cả logic pipeline nằm ở repo [`videopress-cicd`](../videopress-cicd/) (Jenkins Shared Library, function `pythonLambdaPipeline()`).
- **Trigger**: PR vào `main` chạy lint + test + coverage; merge vào `main` chạy thêm package + upload artifact.
- **Deploy**: KHÔNG xảy ra ở repo này. Repo `videopress-infrastructure` poll artifact S3 + apply Terraform.

Stage Jenkins:

| Stage | Mô tả |
|---|---|
| `Checkout` | Clone source |
| `Lint` | `make lint` |
| `Test` | `make test` (fail nếu coverage < 70%) |
| `Package` | `make package` cho 5 lambda |
| `Upload` | Push zip lên `s3://videopress-artifacts-{nonprod\|prod}/backend/<commit_sha>/` |
| `Notify` | Gửi Teams webhook kết quả |

---

## 🔐 Secrets & Environment

- **TUYỆT ĐỐI KHÔNG hardcode** secret, AWS account ID, ARN, region trong source code.
- Secret (Cognito client secret, JWT signing key, SES SMTP password…) đọc từ **AWS Secrets Manager** thông qua helper [`shared/secrets.py`](./shared/secrets.py) (có cache để giảm cost).
- Environment-specific config (DynamoDB table name, S3 bucket name, MediaConvert queue ARN…) đọc từ **Lambda environment variable** do Terraform inject.
- File `.env*`, `terraform.tfvars`, `*.pem`, `credentials` đã có trong `.gitignore`.

```python
# Đúng pattern
from shared.secrets import get_secret
jwt_key = get_secret("videopress/jwt-signing-key")

# SAI — đừng làm thế này
JWT_KEY = "abc-def-ghi-123"  # ❌
```

---

## 🤝 Contributing

**Branch convention:**

| Prefix | Khi nào dùng | Ví dụ |
|---|---|---|
| `feat/` | Thêm feature mới | `feat/auth-totp-mfa` |
| `fix/` | Sửa bug | `fix/upload-presigned-expiry` |
| `chore/` | Refactor, doc, deps | `chore/bump-powertools-2.31` |

**Commit message** theo Conventional Commits:

```
feat(auth): add TOTP MFA verification flow
fix(notif): correct SES bounce handling for soft-fail
chore(deps): bump aws-lambda-powertools to 2.31.0
docs(readme): clarify package build flow
```

**PR checklist** (xem [`.github/pull_request_template.md`](./.github/pull_request_template.md)):

- [ ] `make lint` + `make test` pass local
- [ ] Coverage ≥ 70%
- [ ] Đã thêm test cho code mới
- [ ] Đã update `requirements.txt` nếu thêm dependency
- [ ] KHÔNG commit secret hay AWS account ID
- [ ] Đã update `docs/lambda-conventions.md` nếu đổi convention

---

## 👥 Owner & Liên hệ

- **Owning team**: Backend
- **Slack**: `#videopress-backend`
- **CODEOWNERS**: xem [`.github/CODEOWNERS`](./.github/CODEOWNERS)
- On-call: rotation hàng tuần, schedule trong PagerDuty service `videopress-backend`

---

## 🔗 Liên kết các repo khác

| Repo | Vai trò |
|---|---|
| [`videopress-infrastructure`](https://github.com/videopress/videopress-infrastructure) | Terraform IaC cho 3 môi trường UAT/Staging/Prod |
| [`videopress-cicd`](https://github.com/videopress/videopress-cicd) | Jenkins Shared Library + Jenkinsfile templates |
| [`videopress-platform-docs`](https://github.com/videopress/videopress-platform-docs) | Meta repo: ADR, kiến trúc tổng thể, IDEA.md, runbook |

---

_Last updated: skeleton scaffold by automation. Maintained by Backend team._
