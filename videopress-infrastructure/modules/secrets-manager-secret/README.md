# Module — `secrets-manager-secret`

> Secrets Manager secret + (optional) rotation Lambda placeholder. Module tạo "shell" secret; giá trị thật **KHÔNG** đi qua Terraform state.

## 📋 Inputs

| Tên | Type | Default | Mô tả |
|---|---|---|---|
| `secret_name` | `string` | — | Tên (vd `videopress/uat/3rd-party-api-key`). |
| `description` | `string` | `""` | Mô tả. |
| `kms_key_id` | `string` | `null` | KMS; null = AWS-managed. |
| `recovery_window_in_days` | `number` | `7` | UAT 0, Prod 30. |
| `create_placeholder_value` | `bool` | `false` | Tạo bản version placeholder hay không. |
| `rotation_lambda_arn` | `string` | `null` | ARN rotation Lambda. |
| `rotation_days` | `number` | `90` | Chu kỳ rotate. |
| `tags` | `map(string)` | — | Tag chuẩn. |

## 📤 Outputs

| Tên | Mô tả |
|---|---|
| `secret_arn` | ARN (cấp cho Lambda). |
| `secret_name` | Tên. |

## 💡 Example usage

```hcl
module "secret_thirdparty" {
  source = "../../modules/secrets-manager-secret"

  secret_name              = "videopress/${var.environment}/3rd-party-api-key"
  description              = "API key cho dịch vụ thumbnail bên thứ 3"
  recovery_window_in_days  = var.environment == "prod" ? 30 : 7
  create_placeholder_value = true

  tags = local.common_tags
}
```

## 🔗 Dependencies

- KMS key (optional).
- Rotation Lambda (optional, dùng `module.lambda-function` riêng).

## 📝 Notes

- ⚠️ KHÔNG để giá trị thật vào `aws_secretsmanager_secret_version.secret_string` — sẽ vào state plain text.
- Pattern: tạo shell, sau đó `aws secretsmanager put-secret-value` qua CLI (chạy 1 lần thủ công, hoặc CI có `--profile sealed`).
- `lifecycle.ignore_changes = [secret_string]` để rotation Lambda đổi value mà Terraform không plan diff.
