# 🏗️ videopress-infrastructure

[![Terraform](https://img.shields.io/badge/Terraform-%E2%89%A5%201.11-7B42BC?logo=terraform)](https://www.terraform.io)
[![AWS Provider](https://img.shields.io/badge/AWS%20Provider-~%3E%205.0-FF9900?logo=amazonaws)](https://registry.terraform.io/providers/hashicorp/aws/latest)
[![License](https://img.shields.io/badge/license-Internal--Only-lightgrey)](#)
[![Pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit)](https://pre-commit.com)

> **Repo 2/4** trong VideoPress Platform — Terraform IaC quản lý hạ tầng AWS cho 3 môi trường UAT / Staging / Prod.

---

## 📑 Mục lục

1. [🎯 Mục đích](#-mục-đích)
2. [🏗️ Tech stack](#%EF%B8%8F-tech-stack)
3. [📂 Cấu trúc folder](#-cấu-trúc-folder)
4. [🌐 Network architecture](#-network-architecture)
5. [🚀 Quick start (UAT)](#-quick-start-uat)
6. [🧱 Module list](#-module-list)
7. [🔐 Backend state](#-backend-state)
8. [⚠️ Pre-commit hooks](#%EF%B8%8F-pre-commit-hooks)
9. [🤖 CI/CD](#-cicd)
10. [🛡️ DynamoDB safety](#%EF%B8%8F-dynamodb-safety--7-nguyên-tắc)
11. [💰 Cost](#-cost)
12. [🚨 Rollback procedure](#-rollback-procedure)
13. [👥 Owner](#-owner)
14. [🔗 Cross-repo links](#-cross-repo-links)

---

## 🎯 Mục đích

Repo này chứa **toàn bộ Terraform code** quản lý hạ tầng AWS cho VideoPress Platform — một platform Serverless nén video. Cụ thể:

- Định nghĩa **3 stack độc lập** (UAT / Staging / Prod) theo pattern *folder-per-env*.
- Dùng **module tái sử dụng** cho VPC, API Gateway, Lambda, Cognito, DynamoDB, S3, SQS, SNS, Secrets, Monitoring.
- **Tách CI/CD** thành 3 Jenkinsfile theo concern: `plan` (PR check) / `deploy` (apply theo env, có approval) / `rollback` (emergency).
- Áp dụng **7 nguyên tắc an toàn DynamoDB** (xem mục dưới) để tránh mất data.

Repo này **KHÔNG chứa** code Lambda Python — code nằm ở [`videopress-backend`](https://github.com/videopress/videopress-backend). Repo này pull artifact `.zip` đã build từ S3 do CI backend đẩy lên.

---

## 🏗️ Tech stack

| Thành phần | Phiên bản |
|---|---|
| Terraform | `>= 1.11.0` (yêu cầu **S3 native locking** qua `use_lockfile = true`, không cần DynamoDB lock) |
| AWS Provider | `~> 5.0` |
| Pre-commit framework | `>= 3.0` |
| TFLint | `>= 0.50` (preset `recommended` + plugin `aws`) |
| tfsec | `>= 1.28` |
| terraform-docs | `>= 0.16` |
| Infracost | `>= 0.10` |
| Jenkins | `2.x` (LTS), shared library tại [`videopress-cicd`](https://github.com/videopress/videopress-cicd) |

> 💡 Vì sao Terraform 1.11+? Từ 1.10 trở đi, S3 backend có `use_lockfile = true` thay thế DynamoDB lock đã deprecated — giảm 1 resource cần bootstrap.

---

## 📂 Cấu trúc folder

```
videopress-infrastructure/
├── README.md                         ← bạn đang đọc
├── ARCHITECTURE.md                   ← sơ đồ kiến trúc + ADR pointer
├── .gitignore
├── .tflint.hcl
├── .pre-commit-config.yaml
├── Makefile                          ← shortcut init/plan/apply per env
├── Jenkinsfile.plan                  ← PR check (mọi env)
├── Jenkinsfile.deploy                ← apply theo env, có approval
├── Jenkinsfile.rollback              ← emergency rollback
├── .github/
│   ├── CODEOWNERS
│   └── pull_request_template.md
│
├── bootstrap/                        ← chạy 1 lần per AWS account (nonprod + prod)
│   ├── main.tf                       ← S3 state bucket + KMS + state archive
│   ├── variables.tf
│   ├── outputs.tf
│   ├── versions.tf
│   ├── terraform.tfvars.example
│   └── README.md
│
├── modules/                          ← 11 module tái dùng
│   ├── vpc-network/
│   ├── api-gateway-private/
│   ├── lambda-function/
│   ├── lambda-layer/
│   ├── cognito-user-pool/
│   ├── dynamodb-table/
│   ├── s3-bucket-secure/
│   ├── sqs-queue/
│   ├── sns-topic-email/
│   ├── secrets-manager-secret/
│   └── monitoring-stack/
│
├── envs/                             ← 3 stack độc lập
│   ├── uat/
│   ├── staging/
│   └── prod/
│
└── policies/                         ← IAM policy JSON tách riêng
    ├── lambda-execution-base.json
    ├── lambda-dynamodb-rw-scoped.json
    ├── lambda-s3-rw-scoped.json
    └── terraform-runner-prod.json
```

---

## 🌐 Network architecture

> Chi tiết đầy đủ ở [`IDEA.md` — Network Architecture](../IDEA.md#-network-architecture--vpc-riêng-cho-mỗi-môi-trường).

**3 VPC độc lập, KHÔNG peering**, dải CIDR tách bạch:

| Môi trường | VPC CIDR | Số AZ | NAT Gateway | Public CIDR | Private CIDR | VPCE CIDR |
|---|---|---|---|---|---|---|
| **UAT** | `10.10.0.0/16` | 2 | 1 (single, cost-saving) | `10.10.1-2.0/24` | `10.10.11-12.0/24` | `10.10.21-22.0/24` |
| **Staging** | `10.20.0.0/16` | 2 | 1 (single) | `10.20.1-2.0/24` | `10.20.11-12.0/24` | `10.20.21-22.0/24` |
| **Prod** | `10.30.0.0/16` | 3 | 3 (per AZ, HA) | `10.30.1-3.0/24` | `10.30.11-13.0/24` | `10.30.21-23.0/24` |

VPC Endpoints per env: `s3` + `dynamodb` (Gateway, free) + `execute-api` `secretsmanager` `logs` `sqs` `sns` `kms` `cognito-idp` (Interface).

---

## 🚀 Quick start (UAT)

> Giả định bạn đã chạy xong `bootstrap/` cho account `nonprod` và biết tên S3 state bucket + KMS key ARN.

```bash
# 1. Vào folder env UAT
cd envs/uat

# 2. Copy file biến mẫu, sửa giá trị
cp terraform.tfvars.example terraform.tfvars
# Mở terraform.tfvars, điền: aws_region, project, owner_team, ...

# 3. Sửa backend.tf — paste tên bucket + KMS key ARN từ output bootstrap
# (chỉ làm 1 lần per env)

# 4. Init backend + provider plugin
terraform init

# 5. Xem plan (KHÔNG apply gì hết)
terraform plan -out=tfplan.bin

# 6. Apply (chỉ làm sau khi review plan)
terraform apply tfplan.bin

# 7. Smoke test endpoint API
terraform output api_invoke_url
curl -H "Authorization: Bearer <token>" $(terraform output -raw api_invoke_url)/healthz
```

Để dùng shortcut `make`:

```bash
make init-uat
make plan-uat
make apply-uat
```

---

## 🧱 Module list

Bảng dưới lấy từ [`IDEA.md` Resource list](../IDEA.md#%EF%B8%8F-repo-2--videopress-infrastructure-terraform-iac):

| Module | Resource AWS chính | Số lượng / env |
|---|---|---|
| `vpc-network` | VPC, Subnets, NAT, IGW, Route Tables, **9 VPC Endpoints**, Flow Log | 1 |
| `api-gateway-private` | `aws_api_gateway_rest_api` (PRIVATE), Cognito Authorizer, resource policy | 1 |
| `lambda-function` | Lambda + IAM role + log group + permissions | 5 (auth/notif/upload/compression/job_status) |
| `lambda-layer` | `aws_lambda_layer_version` từ S3 | 1 |
| `cognito-user-pool` | User Pool + App Client + Domain + Groups + MFA | 1 |
| `dynamodb-table` | Table + PITR + KMS + `deletion_protection` | 3 (`Users`/`Jobs`/`Notifications`) |
| `s3-bucket-secure` | Bucket + KMS + versioning + lifecycle + block public | 2 (`input`/`output`) |
| `sqs-queue` | Queue + DLQ + alarm "stuck messages" | 1 |
| `sns-topic-email` | Topic + email subscription + access policy | 1 |
| `secrets-manager-secret` | Secret + (optional) rotation Lambda | 1 |
| `monitoring-stack` | CloudWatch dashboards + alarms (5xx/latency/throttle) + SNS alert | 1 |

---

## 🔐 Backend state

Mỗi stack env trỏ tới **1 S3 backend riêng** (theo account), khoá theo prefix:

```hcl
# envs/uat/backend.tf (ví dụ)
terraform {
  backend "s3" {
    bucket       = "videopress-tfstate-nonprod-<account-id>"
    key          = "envs/uat/terraform.tfstate"
    region       = "ap-southeast-1"
    encrypt      = true
    kms_key_id   = "arn:aws:kms:ap-southeast-1:<account-id>:key/<key-id>"
    use_lockfile = true   # ✅ S3 native locking, KHÔNG cần DynamoDB lock table
  }
}
```

**Phương án B — 2 account**:

| Bucket | Account | Key path |
|---|---|---|
| `videopress-tfstate-nonprod-<acct>` | nonprod | `envs/uat/terraform.tfstate`, `envs/staging/terraform.tfstate` |
| `videopress-tfstate-prod-<acct>` | prod | `envs/prod/terraform.tfstate` |
| `videopress-state-archive-<acct>` | mỗi account 1 cái | backup tự động trước mỗi `apply prod` |

> ⚠️ S3 bucket backend KHÔNG được xoá sau khi bootstrap xong. Nếu mất, mất luôn state — coi như chưa từng có infra.

---

## ⚠️ Pre-commit hooks

Repo dùng [pre-commit](https://pre-commit.com) với hooks từ [antonbabenko/pre-commit-terraform](https://github.com/antonbabenko/pre-commit-terraform):

| Hook | Tác dụng |
|---|---|
| `terraform_fmt` | Format `.tf` theo chuẩn HashiCorp |
| `terraform_validate` | Validate syntax + reference |
| `terraform_tflint` | Lint HCL + AWS resource convention |
| `terraform_tfsec` | Security scan AWS misconfig (block public S3, KMS, ...) |
| `terraform_docs` | Tự sinh table Inputs/Outputs trong README module |

Cài đặt:

```bash
pip install pre-commit
pre-commit install
pre-commit run --all-files
```

---

## 🤖 CI/CD

3 Jenkinsfile gọi shared library [`videopress-cicd`](https://github.com/videopress/videopress-cicd):

| File | Trigger | Approval |
|---|---|---|
| [`Jenkinsfile.plan`](./Jenkinsfile.plan) | PR mở/push | ❌ |
| [`Jenkinsfile.deploy`](./Jenkinsfile.deploy) | Merge `main` (UAT auto), tag `*-staging` (Staging), tag semver (Prod) | UAT ❌ · Staging ✅ 1 reviewer · **Prod ✅ 2 reviewer + 30 phút cooldown** |
| [`Jenkinsfile.rollback`](./Jenkinsfile.rollback) | Manual only | ✅ **2 lần** (trước tải state, trước apply) |

---

## 🛡️ DynamoDB safety — 7 nguyên tắc

> Trích từ [`IDEA.md` — Phân tích an toàn DynamoDB](../IDEA.md#%EF%B8%8F-phân-tích-cicd-cho-dynamodb-nhạy-cảm).

1. **`prevent_destroy = true`** ở Terraform lifecycle cho mọi DynamoDB table prod.
2. **`deletion_protection_enabled = true`** ở AWS API layer (chặn ngay cả khi vào Console).
3. **PITR (Point-In-Time Recovery)** bật toàn thời gian — restore tới bất kỳ giây nào trong 35 ngày.
4. **Plan review bắt buộc 2 mắt** cho mọi PR đụng `aws_dynamodb_table` — bot Jenkins parse plan, **CHẶN merge** nếu thấy:
   - `~ hash_key` / `~ range_key` → forces replacement.
   - `~ attribute` đổi type.
   - `- resource` (destroy).
5. **Snapshot trước apply prod**: pipeline tự gọi `aws dynamodb create-backup` trước `terraform apply`, lưu 30 ngày.
6. **Tách IAM Role per env**: runner UAT KHÔNG có quyền chạm DynamoDB prod (`aws:RequestedRegion` + tag-based).
7. **Backup state file**: trước mỗi apply prod, upload `terraform.tfstate` lên S3 archive với timestamp.

---

## 💰 Cost

Idle cost ước tính (chi tiết: [`IDEA.md` — Estimated monthly cost](../IDEA.md#-estimated-monthly-cost-3-env)):

| Env | Idle / tháng |
|---|---|
| UAT | ~$142 |
| Staging | ~$146 |
| Prod | ~$285 |
| **Tổng** | **~$573** |

> 💡 ~70% cost UAT/Staging là VPC Interface Endpoints. Có thể cắt $100/env nếu dùng Public API + WAF.

Xem cost diff trên PR:

```bash
infracost breakdown --path envs/uat
make infracost-uat
```

---

## 🚨 Rollback procedure

Tham chiếu chi tiết: [`Jenkinsfile.rollback`](./Jenkinsfile.rollback).

Checklist khi sự cố prod:

- [ ] Tạo incident ticket Jira (mã `INC-XXXX`).
- [ ] Notify Teams channel `#videopress-oncall`.
- [ ] Trigger `Jenkinsfile.rollback` từ Jenkins UI với `target_env=prod`, `reason=...`, `incident_ticket=INC-XXXX`.
- [ ] Approval lần 1 (SRE on-call + Engineering Manager).
- [ ] Review plan của state cũ.
- [ ] Approval lần 2.
- [ ] Apply.
- [ ] (Nếu cần) Restore DynamoDB từ PITR — bật flag input.
- [ ] Smoke test pass.
- [ ] Post-mortem trong 48 giờ.

---

## 👥 Owner

- **Primary**: SRE / DevOps team — `@videopress-org/devops-team`
- **Module reviewers**: SRE leads — `@videopress-org/sre-leads`
- **Prod approvers**: SRE on-call + Security — `@videopress-org/sre-oncall`, `@videopress-org/security-team`

Liên hệ: `#videopress-platform` Slack/Teams channel.

---

## 🔗 Cross-repo links

| Repo | Mục đích |
|---|---|
| [`videopress-backend`](https://github.com/videopress/videopress-backend) | Python Lambda code (5 lambda) — repo này pull `.zip` artifact |
| [`videopress-cicd`](https://github.com/videopress/videopress-cicd) | Jenkins shared library cho `terraformPlanPipeline`, `terraformDeployPipeline`, `terraformRollbackPipeline` |
| [`videopress-platform-docs`](https://github.com/videopress/videopress-platform-docs) | (optional) ADR, runbook, diagram |
| [`IDEA.md` gốc](../IDEA.md) | Tài liệu thiết kế tổng — đọc trước khi đụng vào code |
