# Module — `dynamodb-table`

> 1 DynamoDB table với PITR + encryption + `deletion_protection`. Áp dụng 7 nguyên tắc an toàn theo `IDEA.md`.

## 📋 Inputs

| Tên | Type | Default | Mô tả |
|---|---|---|---|
| `table_name` | `string` | — | Tên (vd `Users-uat`). |
| `billing_mode` | `string` | `PAY_PER_REQUEST` | hoặc `PROVISIONED`. |
| `hash_key` | `string` | — | Hash key. |
| `range_key` | `string` | `null` | Range key. |
| `attributes` | `list(object)` | — | Chỉ key + GSI/LSI keys. |
| `enable_pitr` | `bool` | `true` | PITR 35 ngày. |
| `deletion_protection_enabled` | `bool` | `false` | API-layer block delete. Staging/Prod = `true`. |
| `prevent_destroy` | `bool` | `false` | TF lifecycle. Prod = `true`. |
| `kms_key_arn` | `string` | `null` | CMK; null = AWS-owned. |
| `global_secondary_indexes` | `list(object)` | `[]` | GSI list. |
| `ttl_attribute` | `string` | `null` | TTL attribute name. |
| `tags` | `map(string)` | — | Tag chuẩn. |

## 📤 Outputs

| Tên | Mô tả |
|---|---|
| `table_name` | Tên bảng. |
| `table_arn` | ARN (cấp cho IAM scope). |
| `stream_arn` | Stream ARN (nếu bật streams). |

## 💡 Example usage

```hcl
module "dynamodb_jobs" {
  source = "../../modules/dynamodb-table"

  table_name   = "Jobs-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "job_id"

  attributes = [
    { name = "job_id",  type = "S" },
    { name = "user_id", type = "S" },
  ]

  global_secondary_indexes = [
    {
      name            = "by-user-id"
      hash_key        = "user_id"
      projection_type = "ALL"
    }
  ]

  enable_pitr                 = true
  deletion_protection_enabled = var.environment != "uat"
  prevent_destroy             = var.environment == "prod"

  tags = local.common_tags
}
```

## 🔗 Dependencies

- KMS key (optional).

## 📝 Notes

- ⚠️ **Sửa `hash_key` / `range_key` / `attribute.type`** = forces replacement = MẤT DATA. PR đụng các trường này sẽ bị `Jenkinsfile.plan` chặn merge.
- Lifecycle `prevent_destroy = true` HARDCODED ở env prod (Terraform 1.11 chưa cho phép var).
- PITR bật miễn phí (chỉ tính phí khi restore). KHÔNG có lý do gì để tắt.
- Dùng `PAY_PER_REQUEST` cho project size vừa, traffic spike — không cần capacity planning.
- DynamoDB Stream nên bật ở `Jobs` table để `notification_lambda` đọc thay đổi status.
