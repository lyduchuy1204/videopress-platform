# 🥾 Bootstrap stack

> **Stack chỉ chạy 1 lần per AWS account.** Tạo S3 backend bucket + KMS key để các env (`uat` / `staging` / `prod`) dùng làm remote state backend.

---

## 🎯 Mục đích

Trước khi apply bất kỳ env nào (`envs/uat`, `envs/staging`, `envs/prod`), cần có sẵn:

1. **S3 bucket** lưu state file (`videopress-tfstate-<alias>-<account-id>`).
2. **KMS key** mã hoá state.
3. **S3 bucket archive** (`videopress-state-archive-<account-id>`) — Jenkins backup state pre-apply prod.

Stack này tạo ra cả 3 thứ trên trong 1 lần apply.

---

## 🏛️ Account model

> Tham chiếu [`IDEA.md` — Account model](../../IDEA.md#%EF%B8%8F-account-model--quyết-định-trước-khi-scaffold). Mặc định **Phương án B (2 account)**:

| Lần chạy | `account_alias` | Account thật | Bucket sinh ra |
|---|---|---|---|
| **#1** | `nonprod` | `videopress-nonprod` | `videopress-tfstate-nonprod-<acct>` (dùng cho UAT + Staging) |
| **#2** | `prod` | `videopress-prod` | `videopress-tfstate-prod-<acct>` (dùng cho Prod) |

Mỗi lần chạy, bạn cần **đổi AWS profile / OIDC role** trỏ đúng account.

---

## 🚀 Cách chạy (per account)

```bash
cd bootstrap

# 1. Copy file biến mẫu
cp terraform.tfvars.example terraform.tfvars

# 2. Sửa account_alias = "nonprod" hoặc "prod"
#    (KHÔNG commit file terraform.tfvars)

# 3. Set AWS credentials trỏ đúng account
export AWS_PROFILE=videopress-nonprod   # hoặc videopress-prod

# 4. Init (lần đầu, backend local)
terraform init

# 5. Apply
terraform apply
```

> ⚠️ Stack này dùng **backend "local"** — state file `terraform.tfstate` sinh ra ngay trong folder `bootstrap/`. Lưu lại file này ở nơi an toàn (Vault / 1Password / S3 mã hoá riêng) — KHÔNG commit lên git.

---

## 📤 Output sau apply

```
state_bucket_name           = "videopress-tfstate-nonprod-123456789012"
state_archive_bucket_name   = "videopress-state-archive-123456789012"
kms_key_arn                 = "arn:aws:kms:ap-southeast-1:123456789012:key/abc-123-..."
kms_key_alias               = "alias/videopress-tfstate-nonprod"
```

**Copy 3 giá trị này sang `envs/<env>/backend.tf`** của mỗi env tương ứng:

```hcl
# envs/uat/backend.tf
terraform {
  backend "s3" {
    bucket       = "videopress-tfstate-nonprod-123456789012"   # ← từ output state_bucket_name
    key          = "envs/uat/terraform.tfstate"
    region       = "ap-southeast-1"
    encrypt      = true
    kms_key_id   = "arn:aws:kms:ap-southeast-1:123456789012:key/abc-123-..."   # ← từ output kms_key_arn
    use_lockfile = true
  }
}
```

---

## ⚠️ KHÔNG xoá bucket sau khi xong

| Hành động | Hậu quả |
|---|---|
| Xoá `aws_s3_bucket.tfstate` | **MẤT TOÀN BỘ STATE** của 3 env. Coi như chưa từng có hạ tầng. |
| Xoá KMS key | Không decrypt được state cũ → hệt như mất state. |
| Xoá `aws_s3_bucket.state_archive` | Mất khả năng rollback từ snapshot. |

Bucket `tfstate` đã có `lifecycle { prevent_destroy = true }` để tránh nhầm.

Nếu thực sự cần xoá (vd cleanup project), phải:

1. Bỏ `prevent_destroy` thủ công.
2. Empty bucket trước (`aws s3 rm --recursive`).
3. `terraform destroy`.
4. Xác nhận đã backup state ra ngoài.

---

## 🔄 Khi nào re-apply bootstrap?

- ✅ Tag thay đổi → re-apply OK (idempotent).
- ✅ Thêm bucket mới (vd `audit-trail`) → mở rộng `main.tf` rồi apply.
- ❌ Đổi `account_alias` → KHÔNG, sẽ tạo bucket mới khác account, state cũ vẫn còn ở bucket cũ.

---

## 🔗 Liên kết

- [`README.md` root](../README.md) — quick start cho dev
- [`envs/uat/README.md`](../envs/uat/README.md) — sau khi bootstrap xong, apply UAT thế nào
- [`IDEA.md`](../../IDEA.md) — design tổng platform
