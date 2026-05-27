# 🟡 Env Staging

> Stack Terraform cho môi trường **Staging** (pre-prod). VPC `10.20.0.0/16`, 2 AZ, single NAT, Cognito MFA `ON`, DynamoDB `deletion_protection = true`.

---

## 📋 Tóm tắt config

| Tham số | Giá trị Staging |
|---|---|
| AWS Account | `videopress-nonprod` (cùng UAT) |
| Region | `ap-southeast-1` |
| VPC CIDR | `10.20.0.0/16` |
| Số AZ | 2 |
| NAT Gateway | 1 (single) |
| Lambda memory | 512 MB |
| Lambda timeout | 60s |
| Cognito MFA | ON |
| DynamoDB PITR | ✅ |
| DynamoDB deletion_protection | ✅ |
| S3 force_destroy | ❌ |
| Log retention | 30 ngày |
| VPC Flow Log retention | 30 ngày |
| Backup plan | Daily |
| Idle cost | ~$146/tháng |

---

## 🔗 Bootstrap output cần copy

Cùng account `nonprod` với UAT — dùng chung state bucket. Paste vào [`backend.tf`](./backend.tf):

```
state_bucket_name = "videopress-tfstate-nonprod-<account-id>"
kms_key_arn       = "arn:aws:kms:..."
```

> Key path khác: `envs/staging/terraform.tfstate`.

---

## 🚀 Lệnh apply

Staging trigger qua tag `vX.Y.Z-staging` (Jenkins) — nhưng có thể chạy local nếu cần debug:

```bash
cd envs/staging
cp terraform.tfvars.example terraform.tfvars
export AWS_PROFILE=videopress-nonprod

terraform init
terraform plan -out=tfplan.bin
terraform apply tfplan.bin
```

Hoặc Make:

```bash
make init-staging
make plan-staging
make apply-staging
```

> ⚠️ Trên Jenkins, deploy Staging cần **1 reviewer approval** trước khi apply.

---

## 🧪 Smoke test

```bash
terraform output -raw api_invoke_url
# https://xyz.execute-api.ap-southeast-1.amazonaws.com/staging

curl -H "Authorization: Bearer <token>" \
  $(terraform output -raw api_invoke_url)/healthz
```

Cần connect VPN tới VPC Staging.

---

## 📤 Outputs

Giống UAT — xem `outputs.tf`.

---

## 💣 Destroy

```bash
make destroy-staging
```

> ⚠️ Staging có `deletion_protection = true` cho DynamoDB. Phải tắt thủ công qua AWS Console hoặc đổi `deletion_protection_enabled = false` rồi apply trước khi destroy.

---

## 🔗 Liên kết

- [`README.md` root](../../README.md)
- [`envs/uat/README.md`](../uat/README.md)
- [`envs/prod/README.md`](../prod/README.md)
