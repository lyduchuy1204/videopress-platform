# Module — `s3-bucket-secure`

> S3 bucket chuẩn enterprise: KMS + versioning + lifecycle + block public access. **Note**: MFA Delete phải bật ngoài Terraform (yêu cầu root user + MFA serial).

## 📋 Inputs

| Tên | Type | Default | Mô tả |
|---|---|---|---|
| `bucket_name` | `string` | — | Tên bucket (globally unique). |
| `force_destroy` | `bool` | `false` | Cho phép destroy bucket còn data. KHÔNG bật ở Prod. |
| `kms_key_arn` | `string` | `null` | CMK ARN. null = AES256 AWS-managed. |
| `lifecycle_rules` | `list(object)` | `[]` | Rules transition + expiration. |
| `tags` | `map(string)` | — | Tag chuẩn. |

## 📤 Outputs

| Tên | Mô tả |
|---|---|
| `bucket_id` | Bucket id. |
| `bucket_arn` | ARN. |
| `bucket_regional_domain_name` | Regional domain name. |

## 💡 Example usage

```hcl
module "s3_input" {
  source = "../../modules/s3-bucket-secure"

  bucket_name = "videopress-input-${var.environment}-${data.aws_caller_identity.current.account_id}"
  kms_key_arn = aws_kms_key.s3.arn

  lifecycle_rules = [
    {
      id              = "expire-raw-uploads"
      transition_days = 30
      storage_class   = "STANDARD_IA"
      expiration_days = 90
    }
  ]

  tags = local.common_tags
}
```

## 🔗 Dependencies

- KMS key (optional).

## 📝 Notes

- **MFA Delete** ở Prod: chạy ngoài Terraform sau khi apply lần đầu. Một lần thiết lập là vĩnh viễn (chỉ tắt được bằng root user).
- `force_destroy` chỉ dùng cho test environment. Bucket Prod KHÔNG bao giờ bật.
- Versioning bật → mọi delete = soft delete (DeleteMarker), restore qua list version.
- Lifecycle chuyển object cũ sang Glacier để giảm cost; xoá hẳn sau N ngày.
- Public access block bật full 4 flag (acl + policy + ignore + restrict).
