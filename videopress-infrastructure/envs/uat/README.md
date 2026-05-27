# 🟢 Env UAT

> Stack Terraform cho môi trường **UAT** (User Acceptance Testing). VPC `10.10.0.0/16`, 2 AZ, single NAT Gateway, MFA Cognito `OPTIONAL`.

---

## 📋 Tóm tắt config

| Tham số | Giá trị UAT |
|---|---|
| AWS Account | `videopress-nonprod` (Phương án B) |
| Region | `ap-southeast-1` |
| VPC CIDR | `10.10.0.0/16` |
| Số AZ | 2 |
| NAT Gateway | 1 (single, cost-saving) |
| Lambda memory | 256 MB |
| Lambda timeout | 30s |
| Cognito MFA | OPTIONAL |
| DynamoDB PITR | ✅ |
| DynamoDB deletion_protection | ❌ |
| Log retention | 7 ngày |
| VPC Flow Log retention | 30 ngày |
| Idle cost | ~$142/tháng |

---

## 🔗 Bootstrap output cần copy

Trước khi apply, đảm bảo bootstrap stack ở account `nonprod` đã chạy. Mở `bootstrap/` ở account đó, lấy 2 output sau:

```
state_bucket_name = "videopress-tfstate-nonprod-<account-id>"
kms_key_arn       = "arn:aws:kms:ap-southeast-1:<account-id>:key/<key-id>"
```

Paste vào [`backend.tf`](./backend.tf) đúng 2 chỗ `<state-bucket-from-bootstrap>` và `<kms-key-arn-from-bootstrap>`.

---

## 🚀 Lệnh apply

```bash
cd envs/uat

# 1. Copy biến mẫu
cp terraform.tfvars.example terraform.tfvars

# 2. Set AWS profile/credentials (account nonprod)
export AWS_PROFILE=videopress-nonprod

# 3. Init + plan + apply
terraform init
terraform plan -out=tfplan.bin
terraform apply tfplan.bin
```

Hoặc dùng Make từ root repo:

```bash
make init-uat
make plan-uat
make apply-uat
```

---

## 🧪 Smoke test

Sau khi apply xong:

```bash
# Lấy URL invoke API
terraform output -raw api_invoke_url
# https://abc123.execute-api.ap-southeast-1.amazonaws.com/uat

# Endpoint healthz (chỉ gọi được qua VPN tới VPCE)
curl -H "Authorization: Bearer <token>" \
  $(terraform output -raw api_invoke_url)/healthz
```

> ⚠️ API là **PRIVATE** — không thể curl từ máy local nếu chưa connect VPN tới VPC UAT (qua Site-to-Site VPN hoặc Direct Connect).

---

## 📤 Outputs

| Output | Dùng để |
|---|---|
| `vpc_id` | Reference từ stack khác hoặc debug. |
| `api_invoke_url` | URL gọi API qua VPN. |
| `cognito_user_pool_id` | FE app config. |
| `cognito_client_id` | FE app config. |
| `s3_input_bucket` / `s3_output_bucket` | Tên bucket video. |
| `compression_queue_url` | Producer gửi SQS. |
| `alerts_sns_topic_arn` | Subscribe nhận alarm. |

---

## 💣 Destroy (test cleanup)

```bash
make destroy-uat
```

> UAT có `force_destroy = true` cho S3 + `deletion_protection = false` cho DynamoDB, nên destroy không bị block. **Đừng làm điều này ở Staging/Prod**.

---

## 🔗 Liên kết

- [`README.md` root](../../README.md) — tổng quan repo
- [`bootstrap/README.md`](../../bootstrap/README.md) — bootstrap state backend
- [`envs/staging/README.md`](../staging/README.md) — promote sang Staging
- [`IDEA.md`](../../../IDEA.md) — design tổng platform
