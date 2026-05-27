# 🏛️ Architecture — videopress-infrastructure

> Tài liệu này tóm tắt sơ đồ kiến trúc tổng + 3 VPC tách biệt + flow data + danh sách ADR.
> Chi tiết đầy đủ ở [`IDEA.md`](../IDEA.md) repo gốc của platform.

---

## 1. Sơ đồ tổng — 1 VPC env (high-level)

```
                          ┌──────────────────────────────────┐
                          │  External Client (VPN / Direct   │
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

---

## 2. Tóm tắt 3 VPC tách biệt

| Env | VPC CIDR | Số AZ | NAT | VPC Flow Log | Endpoints | Account (Phương án B) |
|---|---|---|---|---|---|---|
| **UAT** | `10.10.0.0/16` | 2 | 1 single | 30 ngày | 9 endpoint | `videopress-nonprod` |
| **Staging** | `10.20.0.0/16` | 2 | 1 single | 30 ngày | 9 endpoint | `videopress-nonprod` |
| **Prod** | `10.30.0.0/16` | 3 | 3 per-AZ | 90 ngày | 9 endpoint | `videopress-prod` |

> ❌ **KHÔNG VPC Peering** giữa 3 env. ❌ **KHÔNG Transit Gateway chung**. Mỗi env tự quản network độc lập để giảm blast radius.

---

## 3. Flow data — Compression job

```
1. Client (qua VPN)
     │ HTTPS + Bearer token
     ▼
2. VPCE (execute-api) ──► API Gateway PRIVATE ──► Cognito Authorizer
                                                       │ token OK
                                                       ▼
3. upload_lambda  ──► trả presigned URL S3 input
4. Client PUT video ──► s3://videopress-input-<env>/...
5. Client POST /jobs ──► API GW ──► (auth lambda + DynamoDB Jobs PUT)
                                  │
                                  └──► SQS queue (compression-jobs-<env>)
                                              │
                                              ▼
6. compression_lambda (SQS-triggered)
     │ - đọc job từ SQS
     │ - gọi MediaConvert
     │ - update DynamoDB Jobs status = PROCESSING / DONE / FAILED
     ▼
7. MediaConvert ghi output ──► s3://videopress-output-<env>/...
8. notification_lambda
     │ - đọc DynamoDB stream (Jobs status thay đổi)
     │ - publish SNS topic
     ▼
9. Email user / Webhook 3rd-party
```

---

## 4. Layered structure trong `envs/<env>/main.tf`

Code Terraform mỗi env có thứ tự gọi module rõ ràng (qua `depends_on`):

```
Layer 1 — Network    : module.vpc
Layer 2 — Identity   : module.cognito
Layer 3 — Security   : module.secrets, module.kms (nếu tách)
Layer 4 — Storage    : module.s3_input, module.s3_output, module.dynamodb_*
Layer 5 — App        : module.lambda_layer, module.lambda_*, module.api_gw, module.sqs, module.sns
Layer 6 — Monitoring : module.monitoring
```

---

## 5. ADR (Architecture Decision Records)

Các ADR được lưu ở repo `videopress-platform-docs/adr/` (sẽ scaffold ở Phase 5):

| ADR | Quyết định |
|---|---|
| `0001-multi-repo-vs-monorepo.md` | Chọn multi-repo (4 repo bounded context) |
| `0002-private-api-via-vpce.md` | API Gateway PRIVATE qua VPC Endpoint, KHÔNG public |
| `0003-cognito-vs-custom-auth.md` | Cognito User Pool + JWT, KHÔNG tự build auth |
| `0004-jenkins-vs-github-actions.md` | Jenkins on-prem (yêu cầu enterprise corporate) |
| `0005-dynamodb-billing-mode.md` | PAY_PER_REQUEST cho cả 3 env (workload spike nhẹ) |
| `0006-network-isolation.md` | 3 VPC tách hoàn toàn, KHÔNG peering |
| `0007-s3-native-locking.md` | Dùng `use_lockfile = true` từ TF 1.10+, bỏ DynamoDB lock |

---

## 6. Liên kết

- [`README.md`](./README.md) — quick start, module list, CI/CD
- [`IDEA.md`](../IDEA.md) — tài liệu thiết kế gốc của platform
- [`bootstrap/README.md`](./bootstrap/README.md) — bootstrap state backend per account
- [`envs/uat/README.md`](./envs/uat/README.md) — cách deploy UAT
