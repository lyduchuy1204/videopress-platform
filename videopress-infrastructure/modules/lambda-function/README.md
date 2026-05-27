# Module — `lambda-function`

> 1 Lambda function + IAM execution role + CloudWatch Log Group + permissions map. Hỗ trợ `vpc_config` (đặt Lambda trong VPC) cho project pattern enterprise.

## 📋 Inputs

| Tên | Type | Default | Mô tả |
|---|---|---|---|
| `function_name` | `string` | — | Tên Lambda (vd `videopress-uat-authentication`). |
| `handler` | `string` | `app.lambda_handler` | Entry point. |
| `runtime` | `string` | `python3.11` | Runtime. |
| `memory` | `number` | `256` | Memory MB. |
| `timeout` | `number` | `30` | Timeout giây. |
| `s3_bucket` | `string` | — | S3 bucket chứa zip artifact. |
| `s3_key` | `string` | — | Object key zip. |
| `vpc_config` | `object` | `null` | `{ subnet_ids = [...], security_group_ids = [...] }`. `null` = chạy ngoài VPC. |
| `environment` | `map(string)` | `{}` | Env var. |
| `policies` | `list(string)` | `[]` | List IAM policy ARN/JSON gắn thêm vào role. |
| `layers` | `list(string)` | `[]` | List Lambda layer ARN. |
| `log_retention_days` | `number` | `30` | Log retention. |
| `tags` | `map(string)` | — | Tag chuẩn. |

## 📤 Outputs

| Tên | Mô tả |
|---|---|
| `function_arn` | ARN Lambda. |
| `function_name` | Tên function (hữu ích để gắn alarm). |
| `invoke_arn` | Invoke ARN dùng cho API GW integration. |
| `role_arn` | ARN execution role (để attach extra policy từ caller). |
| `log_group_name` | Tên CloudWatch Log Group. |

## 💡 Example usage

```hcl
module "lambda_authentication" {
  source = "../../modules/lambda-function"

  function_name = "videopress-${var.environment}-authentication"
  handler       = "app.lambda_handler"
  runtime       = "python3.11"
  memory        = var.lambdas.authentication.memory
  timeout       = var.lambdas.authentication.timeout

  s3_bucket = var.artifact_bucket
  s3_key    = "authentication/${var.artifact_version}.zip"

  vpc_config = var.lambdas.authentication.vpc ? {
    subnet_ids         = module.vpc.private_subnet_ids
    security_group_ids = [module.vpc.lambda_sg_id]
  } : null

  environment = {
    USER_POOL_ID = module.cognito.user_pool_id
    JOBS_TABLE   = module.dynamodb_jobs.table_name
  }

  policies = [
    file("${path.root}/../../policies/lambda-execution-base.json"),
    file("${path.root}/../../policies/lambda-dynamodb-rw-scoped.json"),
  ]

  layers             = [module.lambda_layer.layer_arn]
  log_retention_days = var.environment == "prod" ? 90 : 30

  tags = local.common_tags
}
```

## 🔗 Dependencies

- VPC module (nếu bật `vpc_config`).
- `lambda-layer` module nếu dùng layer chung.
- S3 bucket artifact (do CI backend đẩy `.zip` lên).

## 📝 Notes

- IAM execution role mặc định attach `AWSLambdaBasicExecutionRole` + `AWSLambdaVPCAccessExecutionRole` (nếu vpc_config != null).
- KMS key cho log group: dùng `aws:kms` mặc định AWS-managed; bật `var.kms_key_arn` nếu cần CMK riêng.
- Lambda permission cho API Gateway invoke nên tạo BÊN NGOÀI module này (caller biết cụ thể `source_arn`).
- KHÔNG để secret value trong `var.environment` (vào state plain text) — luôn dùng Secrets Manager + IAM policy.
- Cold start trong VPC ~200ms (đã cải thiện từ 2019). Chấp nhận trade-off cho pattern enterprise.
