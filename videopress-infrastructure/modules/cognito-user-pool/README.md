# Module — `cognito-user-pool`

> Cognito User Pool + App Client + Domain + Groups + MFA config. Dùng làm authorizer cho API Gateway PRIVATE.

## 📋 Inputs

| Tên | Type | Default | Mô tả |
|---|---|---|---|
| `name` | `string` | — | Tên user pool. |
| `environment` | `string` | — | uat/staging/prod. |
| `mfa_configuration` | `string` | `"OPTIONAL"` | UAT `OPTIONAL`, Staging/Prod `ON`. |
| `password_minimum_length` | `number` | `12` | Yêu cầu password. |
| `domain_prefix` | `string` | — | Subdomain `<prefix>.auth.<region>.amazoncognito.com`. |
| `client_callback_urls` | `list(string)` | `[]` | OAuth callback. |
| `groups` | `list(string)` | `["admins","users"]` | Group mặc định. |
| `advanced_security_mode` | `string` | `"OFF"` | Prod = `ENFORCED`. |
| `tags` | `map(string)` | — | Tag chuẩn. |

## 📤 Outputs

| Tên | Mô tả |
|---|---|
| `user_pool_id` | User pool id. |
| `user_pool_arn` | ARN (cấp cho API GW authorizer). |
| `client_id` | App client id. |
| `client_secret` | App client secret (sensitive). |
| `domain` | Cognito hosted UI domain. |

## 💡 Example usage

```hcl
module "cognito" {
  source = "../../modules/cognito-user-pool"

  name              = "videopress-${var.environment}"
  environment       = var.environment
  mfa_configuration = var.environment == "uat" ? "OPTIONAL" : "ON"
  domain_prefix     = "videopress-${var.environment}"

  advanced_security_mode = var.environment == "prod" ? "ENFORCED" : "OFF"

  tags = local.common_tags
}
```

## 🔗 Dependencies

- Không có. Là layer 2 (chạy sau VPC).

## 📝 Notes

- App Client Secret KHÔNG được output sang plain text — dùng `sensitive = true` + lưu Secrets Manager để Lambda đọc.
- MFA `OPTIONAL` ở UAT (dev tiện), `ON` ở Staging/Prod.
- Advanced Security Mode (`ENFORCED`) bật adaptive auth, threat detection — chỉ Prod để tiết kiệm cost.
- Groups (admins/users) tạo qua `aws_cognito_user_group`.
