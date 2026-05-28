# 🎬 VideoPress Platform — Sample Project Idea

> **Multi-repo Serverless Video Compression Platform** triển khai trên AWS bằng Terraform + Python Lambda + Jenkins CI/CD.
> Đây là **đề xuất ý tưởng** (file `IDEA.md`) cho sample project trước khi scaffold code.

---

## ⚡ TL;DR — Tóm tắt 30 giây

- **Sample project**: API nén video Serverless, đủ phong phú để học stack enterprise (Private API + Cognito + DynamoDB + Lambda VpcConfig).
- **Multi-repo**: 3 repo bắt buộc (`videopress-backend` / `videopress-infrastructure` / `videopress-cicd`) + 1 repo `videopress-platform-docs` optional. Tổng **3 hoặc 4 repo độc lập** trong cùng GitHub org `videopress` — KHÔNG có "meta repo cha".
- **3 môi trường**: UAT / Staging / Prod, mỗi env **VPC riêng** (CIDR `10.10` / `10.20` / `10.30`), KHÔNG peering.
- **Account model**: Mặc định **Phương án B — 2 AWS account** (non-prod + prod).
- **CI/CD**: 4 Jenkinsfile theo concern (CI / Plan / Deploy / Rollback) + 2 bonus (smoke-test, layer-build). DynamoDB có 7 nguyên tắc an toàn.
- **Cost idle**: ~$573/tháng cho 3 env (70% là VPC Interface Endpoints — có thể cắt $100/env nếu chấp nhận Public API).
- **Scaffold**: 4 phase, ~3-4 tuần.

> 💡 **Gặp thuật ngữ lạ?** Nhảy thẳng tới [📖 Glossary](#-glossary--thuật-ngữ-trong-tài-liệu) trước khi đọc tiếp.

---

## 📑 Mục lục

1. [Use case business](#-use-case-business)
2. [📖 Glossary — Thuật ngữ](#-glossary--thuật-ngữ-trong-tài-liệu)
3. [Sơ đồ kiến trúc tổng](#%EF%B8%8F-sơ-đồ-kiến-trúc-tổng-high-level)
4. [Account model — quyết định trước](#%EF%B8%8F-account-model--quyết-định-trước-khi-scaffold)
5. [Network Architecture — VPC riêng cho 3 env](#-network-architecture--vpc-riêng-cho-mỗi-môi-trường)
6. [Multi-repo structure (4 repo)](#%EF%B8%8F-multi-repo-structure-cấp-organization)
7. [Repo 1 — Backend (Python Lambda)](#-repo-1--videopress-backend-python-lambda)
8. [Repo 2 — Infrastructure (Terraform)](#%EF%B8%8F-repo-2--videopress-infrastructure-terraform-iac)
9. [Repo 3 — CI/CD (Jenkins)](#-repo-3--videopress-cicd-jenkins-shared-library)
10. [Phân tích an toàn DynamoDB + 4 Jenkinsfile](#%EF%B8%8F-phân-tích-cicd-cho-dynamodb-nhạy-cảm)
11. [Security & Secrets](#-security--secrets)
12. [Repo 4 — Docs (optional)](#-repo-4--videopress-platform-docs-optional-khuyến-nghị)
13. [Lộ trình triển khai](#-lộ-trình-triển-khai-4-phases-3-4-tuần)
14. [💰 Estimated monthly cost (3 env)](#-estimated-monthly-cost-3-env)
15. [Tiêu chí khả thi + 9 câu hỏi xác nhận](#-tiêu-chí-khả-thi-cho-sample-project-này)

---

## 🎯 Use case business

**VideoPress** là platform nén video upload từ user về dung lượng nhỏ hơn (giữ chất lượng), trả về link download. API thiết kế kiểu enterprise (Private API qua VPC Endpoint + Cognito auth) — phản ánh đúng pattern doanh nghiệp tài chính/ngân hàng/internal corp đang dùng (giống template UBank V2 tham khảo).

**Workflow user**:
1. User đăng nhập qua Cognito → nhận access token.
2. Gọi API xin **presigned URL** → upload video lên S3 input bucket.
3. Submit job nén → API trả về `job_id`, đẩy job vào SQS queue.
4. **Worker Lambda** nhận từ SQS → gọi MediaConvert nén → cập nhật DynamoDB status.
5. Job xong → SNS gửi notification (email/webhook).
6. User gọi `GET /jobs/{id}` → nhận presigned URL download output từ S3 result bucket.

> 💡 Đủ phong phú để minh hoạ: **API GW + Lambda + DynamoDB + Cognito + S3 + SQS + SNS + Secrets + VPC Endpoint** — đúng spectrum của template gốc.

---

## 📖 Glossary — Thuật ngữ trong tài liệu

> 💡 **Đọc trước nếu bạn lần đầu gặp các thuật ngữ kỹ thuật bên dưới.** Section này đặt sớm để các phần sau dùng từ không phải "trỏ ngược lên giải thích".

| Thuật ngữ | Nghĩa |
|---|---|
| **Bounded context (DDD)** | Một "ranh giới logic" của business domain — VD ở đây: Backend / Infrastructure / CI/CD là 3 bounded context khác nhau, mỗi cái 1 repo. |
| **Monorepo** | Tất cả code trong 1 repo Git lớn. Đối ngược với multi-repo. |
| **Multi-repo** | Mỗi domain/service 1 repo riêng. Project này dùng multi-repo. |
| **Bazel / Nx** | 2 tool quản lý monorepo lớn (Google/Meta dùng). Cho phép build incremental theo file thay đổi. Project nhỏ không cần. |
| **RFC 1918** | Chuẩn IP "private" không định tuyến internet (`10.x.x.x`, `172.16-31.x.x`, `192.168.x.x`). Dùng cho mạng VPC nội bộ. |
| **VPC Endpoint (VPCE)** | Cổng đặc biệt cho phép resource trong VPC gọi AWS service mà không qua internet. 2 loại: Gateway (free, cho S3/DynamoDB) và Interface (~$7.5/AZ/tháng). |
| **S3 native locking** | Cơ chế lock state file Terraform trực tiếp trên S3 từ Terraform 1.10+ (qua `use_lockfile = true`). Thay thế DynamoDB lock đã deprecated. |
| **PITR** | Point-In-Time Recovery — DynamoDB cho phép restore table về bất kỳ giây nào trong 35 ngày qua. Bật miễn phí, restore mất phí. |
| **DLQ** | Dead Letter Queue — queue phụ chứa message SQS xử lý lỗi nhiều lần. Để debug + retry. |
| **OIDC** | OpenID Connect — chuẩn xác thực federation (vd: Jenkins assume AWS role qua JWT, không cần access key tĩnh). |
| **`pip-tools`** | Tool Python pin version dependencies (`pip-compile` sinh `requirements.txt` khoá version từ `requirements.in`). |
| **`paths-filter`** | Action GitHub/Jenkins lọc path file thay đổi để chỉ trigger pipeline liên quan. Cần khi monorepo. |
| **Blast radius** | Phạm vi thiệt hại khi sự cố. Tách account/VPC/repo giúp giảm blast radius. |
| **Folder-per-env** | Pattern Terraform: `envs/uat/`, `envs/staging/`, `envs/prod/` là 3 stack độc lập, dùng chung `modules/`. Đối ngược với Terraform Workspaces. |
| **`tfsec` / `tflint` / `checkov`** | 3 tool quét Terraform: tflint (cú pháp HCL), tfsec (security cấu hình AWS), checkov (compliance CIS/NIST). |
| **Smoke test** | Bộ test "phải pass" sau deploy để xác nhận hệ thống chạy cơ bản. Project này dùng curl/Postman gọi vài endpoint chính. |
| **Spock** | Test framework cho Groovy — dùng test các class trong Jenkins shared library. |

### Vì sao Lambda đặt **trong VPC** (VpcConfig)?

Đây là quyết định kiến trúc quan trọng — Lambda mặc định **chạy bên ngoài VPC** của bạn (trong VPC nội bộ AWS). Đặt Lambda vào VPC chỉ khi cần 1 trong 3 lý do:

| Lý do | Ví dụ trong project này |
|---|---|
| **Cần truy cập resource trong VPC** | Lambda gọi RDS/ElastiCache/EC2 internal (chưa có trong scope demo) |
| **Cần đi qua VPN/Direct Connect tới on-premises** | Lambda gọi LDAP/AD nội bộ corp |
| **Compliance: traffic phải qua Flow Log + có địa chỉ IP có thể audit** | Tổ chức tài chính/ngân hàng (giống template UBank V2 gốc) |

Trade-off khi đặt Lambda trong VPC:
- ⚠️ Cold start lâu hơn ~200ms (cần attach ENI). Đã được cải thiện nhiều từ 2019 nhưng vẫn có.
- ⚠️ Mỗi Lambda concurrent execution chiếm 1 IP trong subnet → cần subnet đủ lớn (`/24` = 251 IP usable).
- ⚠️ Lambda muốn ra Internet phải qua NAT Gateway (tốn tiền + latency).
- ✅ Truy cập DynamoDB/S3/Secrets Manager qua **VPC Endpoint** miễn phí (Gateway) hoặc rẻ (Interface).

> Project này chọn đặt Lambda trong VPC vì **muốn pattern enterprise** giống template gốc — traffic Lambda → DynamoDB/Secrets đi qua VPC Endpoint, có VPC Flow Log audit. Nếu chỉ làm side project public, có thể bỏ VpcConfig để Lambda warm hơn.

### Path API GW → Lambda KHÔNG qua VPC

Một điểm dễ hiểu nhầm: API Gateway invoke Lambda **đi qua AWS service backbone**, KHÔNG qua VPC của bạn. Cụ thể:

```
Client → VPCE (execute-api) → API Gateway → [AWS service backbone] → Lambda
                                                                       │
                                                                       │ Lambda code chạy
                                                                       │ + có VpcConfig
                                                                       ▼
                                                  Lambda gọi ra ngoài (VPC ENI)
                                                       ↓
                                                  DynamoDB / S3 / Secrets (qua VPCE)
```

→ VPC config của Lambda **chỉ ảnh hưởng outbound** (Lambda gọi resource khác), KHÔNG ảnh hưởng inbound (API Gateway gọi Lambda).

---

## 🗺️ Sơ đồ kiến trúc tổng (high-level)

```
                          ┌──────────────────────────────────┐
                          │  External Client (VPN/Direct     │
                          │  Connect tới corporate network)  │
                          └────────────────┬─────────────────┘
                                           │ HTTPS (private)
                                           ▼
   ┌─────────────────────────────────────────────────────────────────────────┐
   │  ENV VPC (UAT / Staging / Prod — TÁCH HOÀN TOÀN)                        │
   │                                                                         │
   │   ┌───────────────────┐         ┌───────────────────────────────┐      │
   │   │ Public Subnet     │         │ Private Subnet (workload)     │      │
   │   │  ┌─────────┐      │         │  ┌────────────────────┐       │      │
   │   │  │NAT GW   │◄─────┼─────────┼──┤ Lambda (in VPC)    │       │      │
   │   │  └────┬────┘      │         │  │  - authentication  │       │      │
   │   │       │ outbound  │         │  │  - notification    │       │      │
   │   │  ┌────▼────┐      │         │  │  - upload          │       │      │
   │   │  │  IGW    │      │         │  │  - compression     │       │      │
   │   │  └─────────┘      │         │  │  - job_status      │       │      │
   │   └───────────────────┘         │  └─────────┬──────────┘       │      │
   │                                 │            │                  │      │
   │   ┌───────────────────┐         │  ┌─────────▼──────────┐       │      │
   │   │ VPCE Subnet       │         │  │ DynamoDB / S3 /    │       │      │
   │   │  ┌────────────┐   │◄────────┼──┤ Secrets Manager    │       │      │
   │   │  │VPC Endpoint│   │         │  │ (qua VPCE Gateway/ │       │      │
   │   │  │ execute-api│◄──┼─────────┼──┤ Interface)         │       │      │
   │   │  │ Cognito-IDP│   │         │  └────────────────────┘       │      │
   │   │  │ DynamoDB(Gw)│  │         │                               │      │
   │   │  │ S3 (Gw)    │   │         └───────────────────────────────┘      │
   │   │  └────────────┘   │                                                │
   │   └───────────────────┘                                                │
   │             ▲                                                          │
   │             │ chỉ chấp nhận traffic từ VPCE này                        │
   │   ┌─────────┴─────────┐                                                │
   │   │ API Gateway PRIVATE                                                │
   │   │ + Cognito Authorizer  ────► sẽ trigger Lambda                      │
   │   └───────────────────┘                                                │
   └─────────────────────────────────────────────────────────────────────────┘
                            │
                            │ async events (compression jobs)
                            ▼
                   ┌─────────────────┐      ┌──────────────────┐
                   │ SQS queue       │ ───► │ Compression      │
                   │ + DLQ           │      │ worker Lambda    │
                   └─────────────────┘      └────────┬─────────┘
                                                    │
                                                    ▼
                                            ┌──────────────┐
                                            │ AWS          │
                                            │ MediaConvert │
                                            └──────────────┘
```

> 📌 **VPC tách 100%** giữa 3 env — KHÔNG peering, KHÔNG transit gateway, KHÔNG NACL chung. Lý do: chặn cross-env traffic ngay tầng network.

> ⚠️ **Lưu ý đọc sơ đồ**: Mũi tên từ "API Gateway PRIVATE → Lambda" trong sơ đồ là **luồng logic** (API GW invoke Lambda), KHÔNG phải traffic đi qua VPC. AWS service backbone tự xử lý phần này. Lambda chỉ "đặt trong VPC" cho **outbound calls** (đi xuống DynamoDB/S3/Secrets). Xem chi tiết section "Path API GW → Lambda KHÔNG qua VPC" ở trên.

---

## 🏛️ Account model — quyết định trước khi scaffold

> Đây là quyết định kiến trúc **đầu tiên** cần chốt. 3 phương án phổ biến:

| Phương án | Mô tả | Phù hợp khi |
|---|---|---|
| **A. 1 AWS Account** cho cả 3 env | Tách bằng VPC + tag `Environment` + IAM condition | Demo/POC, team < 3 người, ngân sách hạn chế |
| **B. 2 AWS Account** (Non-prod + Prod) ⭐ **khuyến nghị** | UAT+Staging chung 1 account; Prod 1 account riêng | Hầu hết startup/SME, đảm bảo blast radius prod |
| **C. 3 AWS Account** (mỗi env 1 account) | Tách hoàn toàn | Enterprise, có ControlTower, compliance PCI/SOC2 |

> 📌 **Trong tài liệu này** mọi câu nói "1 / env" hoặc "1 per env" áp dụng cho **cả 3 phương án** — chỉ khác chỗ AWS Account ID.
>
> **Resource list sẽ giả định Phương án B (2 account)**: UAT+Staging trên `videopress-nonprod`, Prod trên `videopress-prod`. Network 3 VPC tách biệt vẫn áp dụng được trên cả 3 phương án.

### Hệ quả lên cấu trúc IaC

| Phương án | Backend S3 | Jenkins runner role | Cross-account assume |
|---|---|---|---|
| A — 1 account | 1 bucket, prefix theo env | 1 role với condition `aws:RequestedRegion` + tag | Không cần |
| B — 2 account | 2 bucket (non-prod + prod) | 2 role (1 per account) | Có — Jenkins assume role qua OIDC |
| C — 3 account | 3 bucket | 3 role | Có — phức tạp hơn |

---

## 🌐 Network Architecture — VPC riêng cho mỗi môi trường

> Đây là yêu cầu **bắt buộc** theo design: **3 VPC độc lập** cho UAT / Staging / Prod, không peering với nhau.

### CIDR Planning (RFC 1918, không trùng với corp network)

| Môi trường | VPC CIDR | Số AZ | Public CIDR (NAT, ALB nếu có) | Private CIDR (Lambda, RDS) | VPCE CIDR (endpoint ENI) |
|---|---|---|---|---|---|
| **UAT** | `10.10.0.0/16` | 2 | `10.10.1.0/24`, `10.10.2.0/24` | `10.10.11.0/24`, `10.10.12.0/24` | `10.10.21.0/24`, `10.10.22.0/24` |
| **Staging** | `10.20.0.0/16` | 2 | `10.20.1.0/24`, `10.20.2.0/24` | `10.20.11.0/24`, `10.20.12.0/24` | `10.20.21.0/24`, `10.20.22.0/24` |
| **Prod** | `10.30.0.0/16` | 3 | `10.30.1-3.0/24` | `10.30.11-13.0/24` | `10.30.21-23.0/24` |

> 💡 **Tách 3 dải CIDR rõ ràng** giúp dễ debug log VPC Flow — chỉ nhìn IP biết ngay thuộc env nào.

### Quyết định kiến trúc network

> Quyết định này sẽ được lưu thành **ADR (Architecture Decision Record)** ở repo `videopress-platform-docs/adr/0006-network-isolation.md` khi scaffold.

| Quyết định | Lý do |
|---|---|
| ❌ **KHÔNG VPC Peering** giữa UAT/Staging/Prod | Rủi ro lateral movement: bug ở UAT có thể "thấy" prod. Chặn ngay tầng network. |
| ❌ **KHÔNG Transit Gateway chung** | Cùng lý do — TGW = single point of attack nếu IAM bị lộ. |
| ✅ **3 VPC hoàn toàn độc lập**, có thể ở 3 AWS Account khác nhau | Best practice enterprise: mỗi env 1 account hoặc tối thiểu tách VPC. |
| ✅ **Mỗi VPC có Internet egress riêng** (NAT Gateway riêng) | Lambda outbound (gọi 3rd party) không chia sẻ NAT giữa env → log/cost rõ ràng. |
| ✅ **Mỗi VPC có VPC Endpoint riêng** cho `execute-api`, `dynamodb`, `s3`, `secretsmanager`, `logs` | Traffic không qua public Internet, giảm cost data transfer. Endpoint policy giới hạn theo tag env. |
| ✅ **Multi-AZ**: UAT/Staging dùng 2 AZ (cost), Prod dùng 3 AZ (HA) | Đánh đổi cost/HA hợp lý cho mỗi env. |
| ⚠️ **Single NAT** ở UAT/Staging (rẻ ~$32/tháng); **NAT mỗi AZ** ở Prod (HA, ~$96/tháng) | Mỗi env xác định trade-off riêng. |

### VPC Endpoint per env (KHÔNG dùng chung)

Mỗi VPC tự deploy đầy đủ:
- **Gateway Endpoint** (free): `s3`, `dynamodb`
- **Interface Endpoint** (~$7.5/tháng/AZ): `execute-api`, `secretsmanager`, `logs`, `sqs`, `sns`, `kms`, `cognito-idp`

> Prod 3 AZ × 7 interface endpoint = ~$157/tháng cho VPC endpoints (đáng giá so với cost data transfer + bảo mật).

### Sơ đồ network 3 VPC tách biệt

```
┌────────────────────────────────────────────────────────────────────────┐
│                       AWS Account (hoặc 2 Account)                     │
│                                                                        │
│   ┌─ UAT VPC ─────────────────┐    ┌─ Staging VPC ─────────────┐      │
│   │ 10.10.0.0/16  · 2 AZ      │    │ 10.20.0.0/16  · 2 AZ      │      │
│   │ ├─ Public  10.10.1.0/24   │    │ ├─ Public  10.20.1.0/24   │      │
│   │ │  + NAT GW (single)      │    │ │  + NAT GW (single)      │      │
│   │ ├─ Private 10.10.11.0/24  │    │ ├─ Private 10.20.11.0/24  │      │
│   │ │  → Lambda VPC config    │    │ │  → Lambda VPC config    │      │
│   │ └─ VPCE   10.10.21.0/24   │    │ └─ VPCE   10.20.21.0/24   │      │
│   │   - execute-api (Private  │    │   - execute-api (Private  │      │
│   │     API GW endpoint)      │    │     API GW endpoint)      │      │
│   │   - dynamodb / s3 (Gw)    │    │   - dynamodb / s3 (Gw)    │      │
│   └─────────────────┬─────────┘    └────────────┬──────────────┘      │
│                     │                           │                      │
│                     │   ❌  KHÔNG peering ❌    │                      │
│                     │                           │                      │
│   ┌─ Prod VPC ──────┴───────────────────────────┴─┐                   │
│   │ 10.30.0.0/16  · 3 AZ (Multi-AZ HA)            │                   │
│   │ ├─ Public  10.30.1-3.0/24  (NAT GW per AZ)    │                   │
│   │ ├─ Private 10.30.11-13.0/24                   │                   │
│   │ │  → Lambda VPC config (Multi-AZ)             │                   │
│   │ └─ VPCE   10.30.21-23.0/24                    │                   │
│   │   - execute-api / dynamodb / s3 / secrets /   │                   │
│   │     logs / sqs / sns / kms / cognito-idp      │                   │
│   └───────────────────────────────────────────────┘                   │
│                                                                        │
│   Truy cập từ corp: VPN Site-to-Site / Direct Connect → từng VPC      │
│   (KHÔNG share Direct Connect attachment giữa env)                     │
└────────────────────────────────────────────────────────────────────────┘
```

### Module Terraform `vpc-network`

Một module duy nhất, parameterize CIDR/AZ count:

```hcl
module "vpc" {
  source = "../../modules/vpc-network"

  name           = "videopress-${var.environment}"
  cidr_block     = var.vpc_cidr            # 10.10.0.0/16 (uat) / 10.20.0.0/16 / 10.30.0.0/16
  az_count       = var.az_count            # 2 cho uat/staging, 3 cho prod
  single_nat     = var.single_nat_gateway  # true cho uat/staging, false cho prod
  enable_flow_log = true
  flow_log_retention_days = var.environment == "prod" ? 90 : 30

  vpc_endpoints = [
    "s3",                 # Gateway, free
    "dynamodb",           # Gateway, free
    "execute-api",        # Interface
    "secretsmanager",     # Interface
    "logs",               # Interface
    "sqs",                # Interface
    "sns",                # Interface
    "kms",                # Interface
    "cognito-idp",        # Interface
  ]

  tags = local.common_tags
}
```

---

## 🗺️ Multi-repo structure (cấp Organization)

> Mỗi block dưới đây là **1 GitHub repo độc lập** trong cùng GitHub org `videopress`. Tách repo theo **bounded context** (DDD) chứ không theo kỹ thuật — giúp team owner rõ ràng, blast radius khi sự cố nhỏ.

```
GitHub org: videopress
│
├── videopress-backend/             ← Repo 1: Python Lambda code
├── videopress-infrastructure/      ← Repo 2: Terraform IaC (3 env: uat/staging/prod)
├── videopress-cicd/                ← Repo 3: Jenkins Shared Library + Jenkinsfiles
└── videopress-platform-docs/       ← Repo 4 (optional): Architecture diagrams, ADR, runbook
```

> 📌 **Folder local trên máy bạn** (sau khi `git clone` cả 4 repo) sẽ có dạng:
>
> ```
> ~/work/videopress/
> ├── videopress-backend/          (git remote: github.com/videopress/videopress-backend)
> ├── videopress-infrastructure/   (git remote: github.com/videopress/videopress-infrastructure)
> ├── videopress-cicd/             (git remote: github.com/videopress/videopress-cicd)
> └── videopress-platform-docs/    (git remote: github.com/videopress/videopress-platform-docs)
> ```
>
> Folder `~/work/videopress/` ở trên chỉ là **convention local** — KHÔNG phải repo Git, không cần `git init` cho nó.

### Lý do chọn 4 repo (KHÔNG monorepo)

| Lý do | Giải thích |
|---|---|
| **Blast radius nhỏ** | PR repo backend không trigger pipeline IaC, ngược lại |
| **Permission tách** | Dev backend không cần quyền sửa Terraform; SRE/DevOps không cần quyền merge code Python |
| **CI/CD pipeline đơn giản** | Mỗi repo có Jenkinsfile riêng, không phải `paths-filter` phức tạp |
| **Versioning độc lập** | Backend tag `v1.2.3`, IaC tag `infra-v0.5.0` — không bị "1 commit thay đổi 2 lifecycle" |
| **Audit dễ** | CloudTrail event nào của runner nào, compliance soi tách bạch |

> ❌ **KHÔNG** dùng monorepo cho đề tài này vì:
> - Có data nhạy cảm (DynamoDB customer data) — cần compliance approval tách rõ ai sửa gì.
> - Team size nhỏ, monorepo lợi ích chính (chia sẻ code) không lớn.
> - Jenkins on-prem không có lợi thế xử lý monorepo như Bazel/Nx của Google/FB.

---

## 📦 Repo 1 — `videopress-backend` (Python Lambda)

> **Owner**: Backend team. **Tech**: Python 3.11, Poetry/pip-tools, pytest.

### Cấu trúc folder (mỗi `*_lambda/` = 1 lambda function)

```
videopress-backend/
├── README.md
├── pyproject.toml                    ← shared dev deps (black, pylint, pytest, mypy)
├── Makefile                          ← make test | make lint | make package | make zip
├── .python-version                   ← 3.11
├── .gitignore
├── Jenkinsfile.ci                    ← gọi shared library: lint + test + package
├── shared/                           ← code chung dùng nhiều lambda
│   ├── logger.py                     ← AWS Lambda Powertools wrapper
│   ├── auth.py                       ← decode JWT từ Cognito
│   ├── dynamo.py                     ← repository pattern cho DynamoDB
│   ├── responses.py                  ← chuẩn shape `{statusCode, body, headers}`
│   └── secrets.py                    ← lấy secret từ Secrets Manager (cached)
├── authentication_lambda/            ← /api/v1/auth/* — login, OTP, refresh token
│   ├── app.py                        ← entry point: app.lambda_handler
│   ├── handlers/
│   │   ├── login.py
│   │   ├── otp_verify.py
│   │   ├── refresh_token.py
│   │   └── logout.py
│   ├── services/
│   │   └── cognito_service.py
│   ├── tests/
│   │   ├── test_login.py
│   │   └── conftest.py
│   ├── requirements.txt
│   └── README.md
├── notification_lambda/              ← /api/v1/notifications/* — list, mark-read, push
│   ├── app.py
│   ├── handlers/
│   │   ├── list_notifications.py
│   │   ├── mark_read.py
│   │   └── push_email.py
│   ├── services/
│   │   ├── ses_service.py
│   │   └── notification_repository.py
│   ├── tests/
│   ├── requirements.txt
│   └── README.md
├── upload_lambda/                    ← /api/v1/uploads/* — request presigned URL S3
│   ├── app.py
│   ├── handlers/
│   │   ├── request_presigned_upload.py
│   │   └── confirm_upload.py
│   └── ...
├── compression_lambda/               ← SQS-triggered worker, gọi MediaConvert
│   ├── app.py                        ← KHÔNG phải API, là SQS event source
│   ├── handlers/
│   │   └── process_compression_job.py
│   └── ...
├── job_status_lambda/                ← /api/v1/jobs/{id} — query status
│   ├── app.py
│   └── ...
└── docs/
    ├── lambda-conventions.md
    └── adding-new-lambda.md
```

### Convention quan trọng

| Convention | Mô tả |
|---|---|
| `app.py` ← entry point | Mọi lambda đều có `app.lambda_handler(event, context)` |
| `handlers/` per route | 1 file = 1 endpoint, dễ test isolated |
| `services/` cho I/O | Wrap Cognito/DynamoDB/SES — mock được trong test |
| `shared/` ← symlink hay copy | Shared code copy bằng Makefile khi build, KHÔNG dùng symlink (Lambda zip không hiểu) |
| `requirements.txt` per lambda | Pin version, không dùng dev deps |
| `tests/` per lambda | pytest, coverage > 70% target |

### Lambda Layer (chung)

Tách 1 layer `videopress-common-layer` chứa: `aws-lambda-powertools`, `pydantic`, `boto3` (đã có trong runtime nhưng pin version mới nhất). Layer này build từ repo `videopress-backend/layer/` và publish qua Jenkins riêng — KHÔNG đóng cùng từng lambda.

---

## 🏗️ Repo 2 — `videopress-infrastructure` (Terraform IaC)

> **Owner**: SRE/DevOps team. **Tech**: Terraform >= 1.11, AWS provider 5.x, S3 native locking.

### Cấu trúc folder (folder-per-env pattern)

```
videopress-infrastructure/
├── README.md
├── ARCHITECTURE.md                   ← sơ đồ kiến trúc + decision records
├── .gitignore
├── .tflint.hcl
├── .pre-commit-config.yaml
├── Jenkinsfile.plan                  ← chạy trên PR (mọi env)
├── Jenkinsfile.deploy                ← chạy khi merge main / tag (theo env)
├── Jenkinsfile.rollback              ← emergency rollback
├── Makefile                          ← make plan-uat | make apply-prod | ...
│
├── modules/                          ← module tái dùng (không gọi backend service nào)
│   ├── api-gateway-private/          ← REST API + VPC Endpoint policy + Cognito authorizer wiring
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
│   │   └── README.md
│   ├── vpc-network/                  ← VPC + subnets + NAT + IGW + route tables + VPC endpoints + flow log
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
│   │   └── README.md
│   ├── lambda-function/              ← Lambda + IAM role + log group + permission
│   │   ├── main.tf
│   │   ├── variables.tf              ← include policies map (per-lambda)
│   │   └── ...
│   ├── lambda-layer/                 ← AWS::Lambda::LayerVersion
│   ├── cognito-user-pool/            ← user pool + client + domain + groups
│   ├── dynamodb-table/               ← table với PITR + encryption + tags
│   ├── s3-bucket-secure/             ← S3 + KMS + versioning + lifecycle + block public
│   ├── sqs-queue/                    ← queue + DLQ + alarm
│   ├── sns-topic-email/              ← topic + email subscription
│   ├── secrets-manager-secret/       ← secret + rotation Lambda placeholder
│   └── monitoring-stack/             ← CloudWatch dashboards + alarms + SNS
│
├── envs/
│   ├── uat/
│   │   ├── main.tf                   ← gọi tất cả module với input UAT
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
│   │   ├── backend.tf                ← key = envs/uat/terraform.tfstate
│   │   ├── terraform.tfvars.example  ← KHÔNG commit file thật
│   │   ├── lambdas.auto.tfvars       ← list lambda + path code (commit OK)
│   │   └── README.md
│   ├── staging/
│   │   └── (giống uat, key + tfvars khác)
│   └── prod/
│       ├── main.tf
│       ├── ...
│       ├── terraform.tfvars.example  ← cùng convention UAT/Staging; thêm comment "PROD: bật MFA Delete + deletion_protection"
│       └── README.md
│
├── bootstrap/                        ← chạy 1 lần per account — tạo S3 backend bucket + state archive bucket
│   ├── main.tf                       ← S3 state backend + S3 state archive + KMS key + block public
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
│
└── policies/                         ← IAM policy JSON tách riêng (review dễ)
    ├── lambda-execution-base.json
    ├── lambda-dynamodb-rw-scoped.json
    ├── lambda-s3-rw-scoped.json
    └── terraform-runner-prod.json    ← least privilege cho Jenkins runner ở Prod (UAT/Staging dùng AdministratorAccess đỡ phiền — convention enterprise)
```

> 📌 **Vì sao chỉ có `terraform-runner-prod.json`, KHÔNG có cho UAT/Staging?**
> Ở UAT/Staging Jenkins runner dùng IAM Role `AdministratorAccess` — không có data thật, được phép xoá đi tạo lại. Ở Prod runner phải dùng policy least privilege thật vì leak key = thảm hoạ. Đây là pattern enterprise: chấp nhận trade-off "dev nhanh, prod chặt".

### Resource list (lấy từ tham khảo SAM, đã generic hoá)

| Resource | Module | Số lượng |
|---|---|---|
| **VPC** + subnets + NAT + IGW + route tables | `vpc-network` | 1 per env (CIDR riêng: 10.10/10.20/10.30) |
| **VPC Endpoints** (S3, DynamoDB Gateway + 7 Interface) | trong `vpc-network` | ~9 per env |
| **VPC Flow Log** → CloudWatch Logs | trong `vpc-network` | 1 per env |
| **API Gateway REST** (PRIVATE endpoint) | `api-gateway-private` | 1 per env |
| **Cognito User Pool** + App Client + Domain | `cognito-user-pool` | 1 per env |
| **Cognito Authorizer** (gắn vào API GW) | trong `api-gateway-private` | 1 per env |
| **Lambda Functions** | `lambda-function` | 5 per env (auth/notification/upload/compression/job_status) |
| **Lambda Layer** `videopress-common` | `lambda-layer` | 1 per env |
| **DynamoDB tables** | `dynamodb-table` | 3 per env (`Users-<env>`, `Jobs-<env>`, `Notifications-<env>`) |
| **S3 buckets** | `s3-bucket-secure` | 2 per env (`videopress-input-<env>`, `videopress-output-<env>`) |
| **SQS queue** + DLQ | `sqs-queue` | 1 per env (compression jobs) |
| **SNS topic** | `sns-topic-email` | 1 per env (alerts/notifications) |
| **Secrets Manager** | `secrets-manager-secret` | 1 per env (3rd party API key, sau này có thể thêm DB password) |
| **CloudWatch Log Groups** | trong `lambda-function` | 5 per env (retention 7d UAT / 30d staging / 90d prod) |
| **CloudWatch Alarms** | `monitoring-stack` | ~10 per env |
| **State archive S3 bucket** `videopress-state-archive-<account>` | trong `bootstrap/` | 1 per **account** (không phải per env) — lưu state backup từ Jenkins trước mỗi apply prod |

### Cấu hình per-env (`*.auto.tfvars`)

| Tham số | UAT | Staging | Prod |
|---|---|---|---|
| **VPC CIDR** | `10.10.0.0/16` | `10.20.0.0/16` | `10.30.0.0/16` |
| **Số AZ** | 2 | 2 | 3 (Multi-AZ HA) |
| **NAT Gateway** | 1 (single, cost-saving) | 1 (single) | 3 (per AZ) |
| **VPC Flow Log retention** | 30 ngày | 30 ngày | 90 ngày |
| Lambda memory | 256 MB | 512 MB | 1024 MB |
| Lambda timeout | 30s | 60s | 60s |
| DynamoDB billing | PAY_PER_REQUEST | PAY_PER_REQUEST | PAY_PER_REQUEST |
| DynamoDB PITR | ✅ | ✅ | ✅ |
| DynamoDB `deletion_protection` | ❌ | ✅ | ✅ + `prevent_destroy` |
| S3 versioning | ✅ | ✅ | ✅ + MFA Delete |
| Log retention | 7 ngày | 30 ngày | 90 ngày |
| API GW Stage | `uat` | `staging` | `prod` |
| Cognito MFA | OPTIONAL | REQUIRED | REQUIRED + advanced security |
| VPC Peering với env khác | ❌ KHÔNG | ❌ KHÔNG | ❌ KHÔNG |
| Backup plan | ❌ | ✅ daily | ✅ daily + cross-region |

> 💡 Cấu hình tách bạch giữa env giúp UAT/Staging giảm cost (single NAT, less retention), Prod tăng độ bền (Multi-AZ, MFA Delete, cross-region backup). Xem section [Account model](#%EF%B8%8F-account-model--quyết-định-trước-khi-scaffold) cho cách tách AWS account.

---

## 🤖 Repo 3 — `videopress-cicd` (Jenkins Shared Library)

> **Owner**: SRE/DevOps team. **Tech**: Jenkins 2.x, Groovy DSL, Jenkins Shared Library.
> Repo này là "thư viện chung" cho mọi pipeline; bản thân nó cũng có Jenkinsfile riêng để test library.

### Cấu trúc

```
videopress-cicd/
├── README.md
├── Jenkinsfile                       ← test chính shared library — chạy `./gradlew test` (Spock spec dưới `test/groovy/`) khi PR mở/push lên repo này, đảm bảo library không break trước khi repo khác consume
├── vars/                             ← global pipeline DSL functions
│   ├── pythonLambdaPipeline.groovy   ← pipeline cho repo backend (lint + test + package + publish artifact)
│   ├── terraformPlanPipeline.groovy  ← pipeline plan trên PR
│   ├── terraformDeployPipeline.groovy ← pipeline apply theo env, có approval
│   ├── terraformRollbackPipeline.groovy ← rollback từ S3 state versioning
│   └── smokeTestPipeline.groovy      ← chạy curl/Postman test sau deploy
├── src/
│   └── com/
│       └── videopress/
│           ├── aws/
│           │   ├── AssumeRole.groovy ← OIDC / STS assume role per env
│           │   └── S3StateBackup.groovy
│           ├── notify/
│           │   ├── Slack.groovy
│           │   └── Teams.groovy      ← incoming webhook gửi notification deploy/rollback vào channel Microsoft Teams
│           └── terraform/
│               ├── PlanRunner.groovy
│               ├── ApplyRunner.groovy
│               └── PlanReviewBot.groovy ← parse plan JSON, comment GitHub PR
├── resources/
│   ├── templates/
│   │   ├── plan-comment.md.tpl
│   │   └── slack-deploy.json.tpl
│   └── scripts/
│       ├── tfsec-wrapper.sh
│       └── infracost-diff.sh
├── pipelines/                        ← Jenkinsfile MẪU để repo khác copy
│   ├── Jenkinsfile.backend.ci.sample
│   ├── Jenkinsfile.iac.plan.sample
│   ├── Jenkinsfile.iac.deploy.sample
│   └── Jenkinsfile.iac.rollback.sample
└── docs/
    ├── pipeline-design.md
    ├── secrets-management.md
    └── on-call-runbook.md
```

---

## 🛡️ Phân tích CI/CD cho DynamoDB nhạy cảm

> Đây là phần **trọng tâm** vì user yêu cầu phân tích sâu.

### Vì sao DynamoDB nhạy cảm hơn các resource khác?

| Resource | Sửa nhầm gây gì? | Reversible? |
|---|---|---|
| Lambda function | Code lỗi → 500 error, alarm bắn | ✅ rollback nhanh |
| API GW route | API trả 404 → user kêu | ✅ rollback nhanh |
| **DynamoDB schema/table** | **Mất data** nếu table bị replace; lỗi key schema → app fail toàn cục | ⚠️ **Rất khó** — restore từ PITR (nếu có) tốn 1-30 phút và mất delta |
| S3 bucket | Bucket trống thì OK; có data → mất | ⚠️ Restore qua versioning |
| Cognito | Đổi user pool ID → mọi user logout, mất session | ⚠️ Khôi phục qua re-init |

DynamoDB ở đây lưu **customer data**: `Users` (PII), `Jobs` (metadata video user), `Notifications` (history). Sửa nhầm ở prod = sự cố compliance (GDPR, ISO 27001).

### 7 nguyên tắc an toàn cho pipeline đụng DynamoDB

1. **`prevent_destroy = true`** ở Terraform lifecycle cho mọi DynamoDB table prod.
2. **`deletion_protection_enabled = true`** ở AWS API layer (chặn ngay cả khi user vào Console).
3. **PITR (Point-In-Time Recovery)** bật toàn thời gian — restore tới bất kỳ thời điểm nào trong 35 ngày qua.
4. **Plan review bắt buộc 2 mắt** cho mọi PR đụng `aws_dynamodb_table` — bot Jenkins parse plan, comment vào PR ❗ nếu thấy:
   - `~ hash_key` / `~ range_key` → forces replacement, **CHẶN merge**.
   - `~ attribute` block đổi type → cũng chặn.
   - `- resource` (destroy) → đòi 2 reviewer + manual approval.
5. **Snapshot trước apply prod**: pipeline tự gọi `aws dynamodb create-backup` trước khi `terraform apply`, lưu trong 30 ngày.
6. **Tách IAM Role per env**: runner UAT KHÔNG có quyền chạm DynamoDB prod (qua condition `aws:RequestedRegion` + tag-based access).
7. **Backup state file**: trước mỗi apply prod, tự upload `terraform.tfstate` lên S3 bucket riêng `videopress-state-archive` với timestamp.

### 4 Jenkinsfile theo concern

**Có. Tách 4 Jenkinsfile** thay vì gộp 1 file lớn nhiều `if`:

| Jenkinsfile | Trigger | Stage chính | Approval gate? |
|---|---|---|---|
| **`Jenkinsfile.ci`** (backend) | PR mở/push | lint + test + coverage + build zip + push artifact | ❌ Không cần |
| **`Jenkinsfile.plan`** (IaC) | PR mở/push | `init`+`fmt`+`validate`+`tflint`+`tfsec`+`plan` → comment vào PR | ❌ Không cần |
| **`Jenkinsfile.deploy`** (IaC) | Merge main / tag | Plan + **apply theo env** | ✅ Manual approval cho **staging + prod** |
| **`Jenkinsfile.rollback`** (IaC) | Manual trigger | Backup state hiện tại + restore version cũ + plan + apply | ✅ Manual approval BẮT BUỘC |

**Vì sao tách 4 Jenkinsfile thay vì 1 file lớn nhiều stage `if`?**

| Lý do | Giải thích |
|---|---|
| **Permission Jenkins khác nhau** | Job rollback chỉ SRE on-call có quyền trigger. Job plan thì mọi dev được. |
| **History tách bạch** | Khi soi build history, "deploy" và "rollback" tách thành 2 job riêng → audit log dễ đọc. |
| **Concurrency control rõ** | `Jenkinsfile.deploy` có `lock('prod-deploy')` chặn 2 deploy song song. `Jenkinsfile.plan` không cần lock. |
| **Reusable** | Mỗi Jenkinsfile gọi shared library (`pythonLambdaPipeline()`, `terraformDeployPipeline()`) → repo khác chỉ paste 5 dòng là dùng được. |
| **Test riêng** | Mỗi pipeline test được bằng `replay` ở Jenkins UI mà không ảnh hưởng pipeline khác. |

### 📋 Chi tiết từng pipeline (Input / Output / Success criteria)

#### 1️⃣ `Jenkinsfile.ci` — Backend CI

| Mục | Mô tả |
|---|---|
| **Mục đích** | Đảm bảo code Python Lambda chạy đúng + đóng gói thành zip artifact, sẵn sàng cho IaC pull về deploy. |
| **Trigger** | Mọi PR mở/push, mọi nhánh. |
| **Input** | Code source backend (commit SHA), `requirements.txt`, `pyproject.toml`. |
| **Stages** | 1. Checkout code · 2. Setup Python 3.11 · 3. `pip install -r requirements.txt` · 4. `pylint` + `black --check` · 5. `pytest` + coverage · 6. `mypy` type check · 7. Build zip per lambda · 8. Push artifact lên Nexus/S3 với tag `<repo>-<sha>.zip` · 9. Trigger downstream `Jenkinsfile.deploy` UAT (chỉ khi merge main). |
| **Output** | Artifact `.zip` có version, coverage report HTML, lint report. |
| **Success criteria** | Lint pass + Tests pass (coverage ≥ 70%) + zip < 50MB + artifact uploaded với SHA tag. |
| **Failure handling** | Block merge PR; gửi notification Teams cho author. |
| **Approval** | ❌ Không cần (CI chỉ build, không deploy). |
| **Concurrency** | Có thể chạy song song nhiều branch. |

#### 2️⃣ `Jenkinsfile.plan` — IaC Plan-Only (gate review)

| Mục | Mô tả |
|---|---|
| **Mục đích** | "Khám sức khoẻ" PR Terraform: format/lint/security scan/plan, comment plan vào PR để reviewer đọc TRƯỚC khi merge. **Chặn merge** nếu phát hiện thay đổi nguy hiểm (DynamoDB schema). |
| **Trigger** | PR mở/push lên `videopress-infrastructure`. |
| **Input** | PR diff, **target env** xác định bởi label PR (`env:uat` / `env:staging` / `env:prod`). Default `env:uat` nếu không có label. |
| **Stages** | 1. Checkout · 2. `terraform fmt -check` · 3. `terraform init` (backend đúng env) · 4. `terraform validate` · 5. `tflint --recursive` · 6. `tfsec --soft-fail=false` · 7. `terraform plan -out=tfplan.bin` · 8. `terraform show -json tfplan.bin > plan.json` · 9. Phân tích `plan.json` (custom Groovy) · 10. Comment plan summary vào PR · 11. **`infracost diff`** so với base branch · 12. Block PR nếu phát hiện DynamoDB schema change. |
| **Output** | Comment markdown trên PR với: plan summary (X to add / Y to change / Z to destroy), cost diff, danh sách resource bị `replace`/`destroy`. |
| **Success criteria** | `fmt`/`validate`/`tflint`/`tfsec` pass + plan generate được + KHÔNG có DynamoDB schema change. |
| **Failure handling** | PR check fail → tự động chặn merge (GitHub branch protection require check). |
| **Approval** | ❌ Không cần (chỉ plan, không apply). |
| **Concurrency** | Mỗi PR 1 build, build mới abort build cũ trên cùng PR. |

#### 3️⃣ `Jenkinsfile.deploy` — IaC Deploy theo môi trường

| Mục | Mô tả |
|---|---|
| **Mục đích** | Apply Terraform xuống AWS theo env, có gate phù hợp với mức nhạy cảm của env. |
| **Trigger** | (a) Merge `main` → auto deploy **UAT**. (b) Tag `vX.Y.Z-staging` → deploy **Staging**. (c) Tag `vX.Y.Z` (semver pure) → deploy **Prod**. |
| **Input** | Commit SHA / tag, env (suy ra từ tag), `target_env` parameter (manual override khi rerun). |
| **Stages — UAT auto** | 1. Plan UAT · 2. Apply UAT auto · 3. Smoke test (curl các endpoint chính). |
| **Stages — Staging** | 1. Plan Staging · 2. **Approval (1 reviewer)** · 3. Backup state to S3 archive · 4. Apply Staging · 5. Smoke test. |
| **Stages — Prod** | 1. Plan Prod · 2. **Phân tích plan** — chặn nếu DynamoDB schema/destroy · 3. **Backup DynamoDB** (`create-backup` tất cả table) · 4. **Backup state file** lên S3 archive · 5. **Approval (2 reviewer + RFC link)** · 6. `lock('prod-deploy')` · 7. Apply Prod · 8. Smoke test · 9. Notify Teams thành công/thất bại. |
| **Output** | Resource đã apply trên AWS, plan artifact lưu Jenkins, log apply lưu CloudWatch Logs Jenkins agent. |
| **Success criteria** | Apply không lỗi + smoke test pass + DynamoDB backup tồn tại trước khi apply. |
| **Failure handling** | (1) Apply lỗi giữa chừng → KHÔNG auto rollback (có thể tệ thêm); chỉ thông báo on-call. (2) Smoke test fail sau apply → chạy `Jenkinsfile.rollback` thủ công. |
| **Approval** | UAT: ❌. Staging: ✅ 1 reviewer. **Prod: ✅ 2 reviewer + 30 phút cooldown**. |
| **Concurrency** | `lock('${env}-deploy')` — 1 deploy/env tại 1 thời điểm. |

#### 4️⃣ `Jenkinsfile.rollback` — Emergency Rollback

| Mục | Mô tả |
|---|---|
| **Mục đích** | Cứu hoả khi prod hỏng. Khôi phục state Terraform về version cũ + apply lại để đưa infra về thời điểm tốt. |
| **Trigger** | **Chỉ manual** từ Jenkins UI. KHÔNG trigger tự động. |
| **Input** | `target_env` (uat/staging/prod), `target_state_version_id` (S3 versionId), `reason` (text bắt buộc — vào audit log), `incident_ticket` (link Jira). |
| **Stages** | 1. **Approval bắt buộc** (SRE on-call + Engineering Manager) · 2. List các state version có sẵn từ S3 (max 10 cái gần nhất) · 3. Backup state HIỆN TẠI lên S3 archive với timestamp · 4. Tải state version cũ về `terraform.tfstate` local · 5. `terraform init -reconfigure` · 6. `terraform plan` — verify diff · 7. **Approval lần 2** (đọc plan rồi quyết) · 8. `terraform apply` · 9. **Restore DynamoDB từ PITR** nếu cần (manual flag input). · 10. Smoke test · 11. Notify Teams + ghi audit log. |
| **Output** | State đã rollback, ghi chú vào audit S3 bucket `videopress-audit-trail/`. |
| **Success criteria** | Plan của state cũ ra "No changes" hoặc thay đổi nhỏ kỳ vọng + smoke test pass. |
| **Failure handling** | Nếu fail giữa chừng — KHÔNG try retry tự động. SRE phải vào AWS Console kiểm tra thủ công. |
| **Approval** | ✅ **2 lần**: trước khi tải state cũ, và trước khi apply. |
| **Concurrency** | `lock('${env}-rollback')` — block cả `Jenkinsfile.deploy` cùng env. |

> 💡 **Bonus pipeline (optional, không bắt buộc)**:
> - `Jenkinsfile.smoke-test` — chạy Postman collection / curl test sau mỗi deploy. **Sẽ DÙNG** ở project này (gọi từ `Jenkinsfile.deploy` stage cuối). Tạo riêng để rerun độc lập khi debug.
> - `Jenkinsfile.layer-build` — build Lambda Layer `videopress-common` riêng (publish version mới khi `requirements-layer.txt` thay đổi). Trigger khi merge PR có path `layer/`.
> - `Jenkinsfile.drift-detect` — chạy nightly, `terraform plan -refresh-only` để phát hiện drift, comment vào Slack/Teams.
> - `Jenkinsfile.cost-report` — chạy weekly, gửi `infracost` report cho team finance.
>
> **Tổng cộng**: 4 Jenkinsfile chính + 4 bonus = 8 file. Trong scaffold Phase 4 sẽ làm 4 chính + `smoke-test` + `layer-build` (6 file). Drift-detect + cost-report optional.

### Sơ đồ flow CI/CD

```
┌──────────────────────────────────────────────────────────────────┐
│  Developer push code (backend repo)                              │
│  ├─► PR mở   → Jenkinsfile.ci (backend)                          │
│  │            │ lint + pytest + build zip                        │
│  │            └─► artifact .zip lưu Nexus/S3                     │
│  └─► merge main → tag v1.2.3                                     │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│  DevOps push code (IaC repo)                                     │
│  ├─► PR mở   → Jenkinsfile.plan                                  │
│  │            │ tflint + tfsec + terraform plan (uat)            │
│  │            ├─► bot comment plan vào PR                        │
│  │            └─► CHẶN merge nếu DynamoDB schema change          │
│  ├─► merge main → Jenkinsfile.deploy                             │
│  │            │ stage: deploy uat (auto)                         │
│  │            │ stage: deploy staging (✅ approval 1 reviewer)   │
│  │            │ stage: deploy prod    (✅ approval 2 reviewer +  │
│  │            │                          backup DynamoDB +       │
│  │            │                          backup state)           │
│  │            └─► smoke test (curl)                              │
│  └─► (sự cố) → Jenkinsfile.rollback                              │
│               │ list S3 state versions                           │
│               │ confirm version (manual input)                   │
│               │ restore state + apply                            │
│               └─► Slack/Teams notification                       │
└──────────────────────────────────────────────────────────────────┘
```

### Gates cụ thể cho prod deploy

```groovy
// Pseudo-code Jenkins shared library
stage('Plan prod') {
  sh 'terraform plan -out=tfplan.bin'
  sh 'terraform show -json tfplan.bin > plan.json'

  // Phân tích plan, chặn nếu có DynamoDB destroy
  def critical = analyzePlan('plan.json')
  if (critical.dynamoDestroy || critical.dynamoSchemaChange) {
    error("BLOCKED: Plan có thay đổi schema DynamoDB. Cần PR riêng + 2 reviewer + RFC.")
  }
}

stage('Backup before apply') {
  sh '''
    aws dynamodb create-backup --table-name Users-prod --backup-name pre-deploy-$BUILD_ID
    aws dynamodb create-backup --table-name Jobs-prod --backup-name pre-deploy-$BUILD_ID
    terraform state pull > state-pre-apply-$BUILD_ID.tfstate
    aws s3 cp state-pre-apply-$BUILD_ID.tfstate s3://videopress-state-archive/prod/
  '''
}

stage('Approval') {
  input message: 'Apply to PROD?',
        submitter: 'devops-leads,sre-oncall',
        submitterParameter: 'APPROVED_BY'
}

stage('Apply prod') {
  lock(resource: 'prod-deploy', inversePrecedence: true) {
    sh 'terraform apply tfplan.bin'
  }
}

stage('Smoke test') {
  build job: 'videopress-smoke-test-prod', wait: true
}

post {
  failure {
    teams.send("❌ Prod deploy FAILED. Initiate rollback runbook.")
  }
  success {
    teams.send("✅ Prod deploy OK by ${env.APPROVED_BY}")
  }
}
```

---

## 🔐 Security & Secrets

| Loại secret | Cách quản lý |
|---|---|
| Cognito App Client Secret | AWS Secrets Manager, lambda đọc qua role |
| 3rd party API key | Secrets Manager, **CHỖ này KHÔNG để env var** trong Terraform (giá trị plain text vào state) |
| DB password (nếu có RDS sau này) | `random_password` + Secrets Manager rotation |
| Jenkins credentials | Jenkins Credential Store + folder-level scope |
| AWS credentials cho Jenkins runner | **OIDC** (nếu Jenkins có plugin) hoặc IAM Role assume từ EC2 instance Jenkins agent — KHÔNG access key tĩnh |
| GitHub token | Jenkins Credential Store, scope chỉ repo cần thiết |

---

## 📄 Repo 4 — `videopress-platform-docs` (optional, khuyến nghị)

> 📌 **Scaffold timing**: Repo này KHÔNG nằm trong 4 phase chính. Tạo sau khi đã có Phase 4 chạy ổn (~tuần 5+). Lúc đó các diagram + ADR đã có nhiều thông tin thực tế để viết.

```
videopress-platform-docs/
├── README.md
├── ARCHITECTURE.md                   ← high-level diagram (drawio + png)
├── adr/                              ← Architecture Decision Records
│   ├── 0001-multi-repo-vs-monorepo.md
│   ├── 0002-private-api-via-vpce.md
│   ├── 0003-cognito-vs-custom-auth.md
│   ├── 0004-jenkins-vs-github-actions.md
│   └── 0005-dynamodb-billing-mode.md
├── runbook/
│   ├── deploy-prod.md
│   ├── rollback-procedure.md
│   ├── on-call-handover.md
│   └── incident-template.md
├── api/
│   └── openapi.yaml                  ← OpenAPI 3.1 spec (sinh từ code)
└── diagrams/
    ├── architecture-overall.drawio
    ├── data-flow-compression.drawio
    └── network-vpc-endpoint.drawio
```

> Repo này có ích khi team > 5 người. Nếu nhỏ, nhúng vào `videopress-platform/` meta repo cũng được.

---

## 📖 Glossary — Thuật ngữ trong tài liệu

> 📌 Section này đã được di chuyển lên đầu file (entry số 2 trong Mục lục) để bạn đọc trước.

---

## 🚀 Lộ trình triển khai (4 phases, ~3-4 tuần)

| Phase | Thời gian | Output |
|---|---|---|
| **Phase 1 — Bootstrap** | 3 ngày | `videopress-infrastructure/bootstrap/` apply xong; có S3 state backend bucket + S3 state archive bucket + KMS key cho mã hoá. (VPC + Cognito sẽ làm ở Phase 3, KHÔNG ở bootstrap.) |
| **Phase 2 — Backend skeleton** | 5 ngày | `videopress-backend/` có 5 lambda với endpoint trả mock data; pytest pass; Jenkinsfile.ci chạy được local. |
| **Phase 3 — IaC + Deploy UAT** | 7 ngày | Terraform module hoàn chỉnh; deploy UAT thành công; smoke test pass. |
| **Phase 4 — Staging + Prod + CI/CD đầy đủ** | 7 ngày | Jenkins shared library xong, deploy staging + prod (manual approval), rollback playbook test thành công. |

---

## ✅ Tiêu chí "khả thi" cho sample project này

- [x] **Quy mô vừa phải**: 5 Lambda + 3 DynamoDB + 2 S3 → đủ phong phú nhưng demo được trong 1 buổi.
- [x] **Phản ánh enterprise**: Private API + VPC Endpoint + Cognito + Secrets Manager — giống template gốc.
- [x] **Có data nhạy cảm**: DynamoDB customer data → minh hoạ được pattern an toàn.
- [x] **Multi-env**: 3 môi trường UAT/Staging/Prod — đủ để dạy promote pipeline.
- [x] **Multi-repo professional**: 3-4 repo theo bounded context, mỗi repo có Jenkinsfile riêng.
- [x] **CI/CD thật**: Jenkins shared library + 4 Jenkinsfile theo concern.
- [x] **Có rollback strategy**: PITR DynamoDB + S3 state versioning + Jenkinsfile riêng.
- [x] **Đủ rộng để mở rộng**: thêm MediaConvert, Step Functions, Cognito groups… nếu muốn.
- [x] **KHÔNG dính ID nhạy cảm**: chỉ tham khảo cấu trúc SAM gốc, mọi ARN/account ID được parameterize.

---

## 💰 Estimated monthly cost (3 env)

> Ước tính cost cố định (chưa tính traffic / DynamoDB write throughput / video data lớn). Đơn vị USD/tháng.

### Per env — fixed cost

| Resource | UAT | Staging | Prod |
|---|---|---|---|
| **NAT Gateway** | $32 (1 NAT) | $32 (1 NAT) | $96 (3 NAT) |
| **VPC Interface Endpoints** (7 cái × ~$7.5/AZ) | $105 (2 AZ) | $105 (2 AZ) | $157 (3 AZ) |
| **API Gateway PRIVATE** (idle) | ~$1 | ~$1 | ~$1 |
| **Lambda** (light usage <100K req/tháng) | ~$0 (free tier) | ~$0 | ~$5 |
| **DynamoDB** (PAY_PER_REQUEST, light) | ~$0 (free tier) | ~$1 | ~$5 |
| **S3** (storage 10GB + request) | ~$1 | ~$1 | ~$3 |
| **CloudWatch Logs** | ~$1 | ~$3 | ~$10 |
| **CloudWatch Alarms** (~10 alarm) | $1 | $1 | $1 |
| **Secrets Manager** (1 secret) | $0.40 | $0.40 | $0.40 |
| **SNS** (light) | ~$0 | ~$0 | ~$1 |
| **SQS** (light) | ~$0 | ~$0 | ~$1 |
| **Cognito User Pool** (free tier 50K MAU) | $0 | $0 | $0 |
| **AWS Backup** (DynamoDB daily snapshot) | — | $1 | $5 |
| **Tổng (idle / light traffic)** | **~$142** | **~$146** | **~$285** |

### Tổng platform (idle)

| Phương án | UAT | Staging | Prod | **Tổng tháng** |
|---|---|---|---|---|
| **A — 1 account** | ~$142 | ~$146 | ~$285 | **~$573** |
| **B — 2 account** ⭐ | ~$142 | ~$146 | ~$285 | **~$573** (giống) |
| **C — 3 account** | ~$142 | ~$146 | ~$285 | **~$573** + chi phí AWS Organizations consolidated billing (~$0) |

> 🎯 **VPC Interface Endpoints chiếm ~70% cost** ở UAT/Staging idle. Nếu muốn cắt cost, **bỏ Private API** và dùng Public API + Cognito (giảm ~$100/env). Trade-off: kém bảo mật hơn nhưng phù hợp dev environment.

### Chi phí phụ thuộc workload (chưa tính)

- **MediaConvert**: $0.0075/phút SD, $0.015/phút HD, $0.045/phút 4K → 1000 phút HD/tháng = ~$15.
- **Lambda execution**: $0.20/M request + $0.0000133/GB-second.
- **DynamoDB read/write**: $1.25/M write request + $0.25/M read request (on-demand).
- **S3 data transfer out**: $0.09/GB internet (giảm rất nhiều khi download qua VPC Endpoint).
- **Jenkins runner**: 1 EC2 t3.medium 24/7 ~$30/tháng (nếu tự host).

> 💡 **Khuyến nghị**: Set AWS Budget Alert **$50** cho UAT, **$100** cho Staging, **$500** cho Prod ngay từ đầu — phát hiện sớm nếu có lỗi (vd Lambda chạy infinite loop, S3 leak public).

### Cách giảm cost mạnh

| Tactic | Cắt được bao nhiêu |
|---|---|
| Bỏ Private API → dùng Public API + Cognito + WAF | ~$100/env (bỏ VPC Interface endpoints) |
| Bỏ Lambda VpcConfig → Lambda chạy ngoài VPC | ~$30/env (bỏ NAT) |
| Gộp UAT + Staging vào 1 VPC chung | ~$140 (bỏ 1 set Endpoint) |
| Tắt UAT ngoài giờ (cron destroy + apply) | ~50% UAT cost |

---

## 📌 Câu hỏi cần xác nhận trước khi scaffold code

Sau khi bạn duyệt + trả lời, mình sẽ scaffold theo lộ trình 4 phases ở trên.

1. **Account AWS**: đã chốt mặc định **Phương án B (2 account: non-prod + prod)**. Nếu muốn A (1 account) hoặc C (3 account), confirm trước.
2. **CIDR planning**: dải `10.10/10.20/10.30/16` đề xuất có conflict với corp network không? Nếu có dùng `10.50/10.60/10.70` hoặc `172.16.x/16`.
3. **Tên project**: dùng `videopress-platform` hay tên khác?
4. **Repo 4 docs**: tạo ngay hay làm sau Phase 4?
5. **Use case mở rộng**: nén video thuần, hay thêm watermark/thumbnail/transcode format?
6. **Jenkins**: tự host (EC2/EKS) hay Jenkins Cloud? Có plugin OIDC AWS chưa? Có sẵn shared library setup chưa?
7. **Compliance**: chuẩn cụ thể nào (PCI-DSS, ISO 27001, SOC2)? Ảnh hưởng KMS, log retention, flow log retention.
8. **Lambda runtime**: Python 3.11 (giống SAM gốc) hay 3.12?
9. **Truy cập API Private từ corp**: có sẵn Site-to-Site VPN / Direct Connect chưa, hay cần dựng mới?

> 💡 **Reply "OK scaffold"** để mình bắt đầu Phase 1, hoặc trả lời 9 câu trên trước nếu có ràng buộc cụ thể.
