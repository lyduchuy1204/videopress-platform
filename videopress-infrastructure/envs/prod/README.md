# 🔴 Env Prod

> Stack Terraform cho môi trường **Production**. VPC `10.30.0.0/16`, 3 AZ Multi-AZ HA, NAT mỗi AZ, Cognito MFA `ON` + Advanced Security `ENFORCED`, DynamoDB `prevent_destroy + deletion_protection`, S3 MFA Delete bật ngoài Terraform.

> ⚠️ **Đây là production**. Mọi thay đổi đi qua Jenkins (`Jenkinsfile.deploy`) — apply local chỉ khi sự cố và có 2 reviewer.

---

## 📋 Tóm tắt config

| Tham số | Giá trị Prod |
|---|---|
| AWS Account | `videopress-prod` (riêng — Phương án B) |
| Region | `ap-southeast-1` (+ cross-region backup) |
| VPC CIDR | `10.30.0.0/16` |
| Số AZ | 3 (Multi-AZ HA) |
| NAT Gateway | 3 (per AZ) |
| Lambda memory | 1024 MB |
| Lambda timeout | 60s |
| Cognito MFA | ON + Advanced Security `ENFORCED` |
| DynamoDB PITR | ✅ |
| DynamoDB deletion_protection | ✅ |
| DynamoDB prevent_destroy (TF) | ✅ |
| S3 versioning | ✅ + **MFA Delete** (bật ngoài TF) |
| Log retention | 90 ngày |
| VPC Flow Log retention | 90 ngày |
| Backup plan | Daily + cross-region |
| Idle cost | ~$285/tháng |

---

## 🔗 Bootstrap output cần copy

Bootstrap phải chạy trước trên account `videopress-prod` (KHÔNG dùng chung non-prod). Output:

```
state_bucket_name = "videopress-tfstate-prod-<account-id>"
kms_key_arn       = "arn:aws:kms:..."
```

Paste vào [`backend.tf`](./backend.tf).

---

## 🚀 Lệnh apply (qua Jenkins)

Prod chỉ deploy được khi push tag semver pure (vd `v1.0.0`):

```bash
git tag v1.0.0
git push origin v1.0.0
# → Jenkins trigger Jenkinsfile.deploy stage prod
# → 2 reviewer approval + 30 phút cooldown + DynamoDB backup + state archive
```

Hoặc **trong tình huống khẩn cấp** (KHÔNG khuyến khích, cần 2 reviewer ngồi cạnh):

```bash
cd envs/prod
cp terraform.tfvars.example terraform.tfvars
export AWS_PROFILE=videopress-prod

terraform init
terraform plan -out=tfplan.bin
# REVIEW KỸ. Nếu có DynamoDB schema change → DỪNG, dùng PR thường + RFC.
terraform apply tfplan.bin
```

---

## 🛡️ Sau khi apply LẦN ĐẦU phải làm thủ công

1. **Bật MFA Delete cho S3 bucket** (chỉ root user + serial MFA):

   ```bash
   aws s3api put-bucket-versioning \
     --bucket videopress-input-prod-<acct> \
     --versioning-configuration Status=Enabled,MFADelete=Enabled \
     --mfa "<MFA-arn> <code>" --profile <root>

   aws s3api put-bucket-versioning \
     --bucket videopress-output-prod-<acct> \
     --versioning-configuration Status=Enabled,MFADelete=Enabled \
     --mfa "<MFA-arn> <code>" --profile <root>
   ```

2. **Verify** `deletion_protection_enabled = true` cho 3 table DynamoDB.
3. **Setup AWS Backup** plan daily + cross-region copy (tham chiếu IDEA.md).
4. **Setup AWS Budget Alert** $500/tháng cho account `videopress-prod`.
5. **Subscribe SNS alerts topic** cho team on-call.
6. **Setup CloudWatch dashboard** đường link short Slack/Teams cho war room.

---

## 🧪 Smoke test

Cần connect VPN tới VPC Prod (qua corp Direct Connect):

```bash
terraform output -raw api_invoke_url
curl -H "Authorization: Bearer <token>" \
  $(terraform output -raw api_invoke_url)/healthz
```

---

## 💣 Destroy

> 🚫 **KHÔNG có `make destroy-prod`**. Cố tình bỏ để tránh thao tác nhầm.

Nếu thực sự cần xoá Prod (vd cleanup project):

1. Tắt MFA Delete cho S3 bucket (root user).
2. `aws s3 rm --recursive` 2 bucket.
3. Sửa `prevent_destroy = false` trong `dynamodb-table` module + `deletion_protection_enabled = false` rồi apply.
4. Disable AWS Backup plan.
5. Empty state archive bucket.
6. Cuối cùng: `terraform destroy` qua console với 2 reviewer ngồi cạnh.

---

## 🚨 Rollback

Khi sự cố Prod, dùng [`Jenkinsfile.rollback`](../../Jenkinsfile.rollback) — KHÔNG `terraform apply` thủ công các state cũ. Quy trình:

1. Tạo incident ticket.
2. Trigger `Jenkinsfile.rollback` từ Jenkins UI.
3. 2 lần approval (trước tải state + trước apply).
4. (Nếu cần) Restore DynamoDB từ PITR.

Chi tiết checklist: [`README.md` root § Rollback procedure](../../README.md#-rollback-procedure).

---

## 🔗 Liên kết

- [`README.md` root](../../README.md)
- [`envs/staging/README.md`](../staging/README.md) — promote từ Staging → Prod
- [`Jenkinsfile.deploy`](../../Jenkinsfile.deploy) — pipeline deploy
- [`Jenkinsfile.rollback`](../../Jenkinsfile.rollback) — rollback emergency
- [`IDEA.md`](../../../IDEA.md) — design tổng platform
