# Module — `api-gateway-private`

> REST API endpoint type **PRIVATE** — chỉ truy cập qua VPC Endpoint `execute-api`. Bao gồm Cognito User Pool authorizer + resource policy chặn mọi VPCE không thuộc whitelist.

## 📋 Inputs

| Tên | Type | Default | Mô tả |
|---|---|---|---|
| `name` | `string` | — | Tên REST API. |
| `environment` | `string` | — | `uat` / `staging` / `prod`. |
| `stage_name` | `string` | — | Stage name (thường = environment). |
| `allowed_vpce_ids` | `list(string)` | — | VPCE id (execute-api) được phép gọi. Resource policy chặn các VPCE khác. |
| `cognito_user_pool_arn` | `string` | — | ARN Cognito User Pool authorizer. |
| `log_retention_days` | `number` | `30` | Retention access log. |
| `tags` | `map(string)` | — | Tag chuẩn. |

## 📤 Outputs

| Tên | Mô tả |
|---|---|
| `rest_api_id` | REST API id. |
| `rest_api_arn` | REST API ARN. |
| `stage_invoke_url` | Invoke URL kèm stage. |
| `authorizer_id` | ID Cognito authorizer. |
| `execution_arn` | Execution ARN để cấp permission cho Lambda. |

## 💡 Example usage

```hcl
module "api_gw" {
  source = "../../modules/api-gateway-private"

  name                  = "videopress-${var.environment}"
  environment           = var.environment
  stage_name            = var.environment
  allowed_vpce_ids      = [module.vpc.vpc_endpoint_ids["execute-api"]]
  cognito_user_pool_arn = module.cognito.user_pool_arn
  log_retention_days    = var.environment == "prod" ? 90 : 30

  tags = local.common_tags
}
```

## 🔗 Dependencies

- `module.vpc` — cần `execute-api` Interface Endpoint trước.
- `module.cognito` — cần User Pool ARN.

## 📝 Notes

- **Resource policy** dùng pattern `Deny if SourceVpce != allowed` + `Allow *` — đảm bảo chỉ VPCE whitelist gọi được.
- Cognito authorizer trả `401` nếu thiếu/sai token, `403` nếu token hết hạn.
- Routes/methods cụ thể nên cấu hình **bên ngoài module** (ở env `main.tf` hoặc OpenAPI body) — module chỉ lo phần "shell" PRIVATE + authorizer.
- Bật X-Ray ở Prod để trace latency.
- Access log → CloudWatch JSON format, retention theo env.
