# Module — `monitoring-stack`

> CloudWatch dashboard + alarm bộ ba "5xx / latency / throttle" + SNS alert. Dùng làm layer 6 cho mỗi env.

## 📋 Inputs

| Tên | Type | Default | Mô tả |
|---|---|---|---|
| `name` | `string` | — | Prefix tên. |
| `api_name` | `string` | — | API GW name để filter. |
| `stage_name` | `string` | — | Stage API GW. |
| `lambda_function_names` | `list(string)` | `[]` | Lambda cần alarm. |
| `dynamodb_table_names` | `list(string)` | `[]` | Table cần alarm Throttle. |
| `alarm_sns_topic_arn` | `string` | — | SNS gửi alarm. |
| `thresholds` | `object` | (xem variables.tf) | Ngưỡng các alarm. |
| `tags` | `map(string)` | — | Tag chuẩn. |

## 📤 Outputs

| Tên | Mô tả |
|---|---|
| `dashboard_name` | Tên dashboard. |
| `alarm_arns` | List ARN alarm. |

## 💡 Example usage

```hcl
module "monitoring" {
  source = "../../modules/monitoring-stack"

  name       = "videopress-${var.environment}"
  api_name   = module.api_gw.rest_api_id
  stage_name = var.environment

  lambda_function_names = [
    module.lambda_authentication.function_name,
    module.lambda_notification.function_name,
    module.lambda_upload.function_name,
    module.lambda_compression.function_name,
    module.lambda_job_status.function_name,
  ]

  dynamodb_table_names = [
    module.dynamodb_users.table_name,
    module.dynamodb_jobs.table_name,
    module.dynamodb_notifications.table_name,
  ]

  alarm_sns_topic_arn = module.sns_alerts.topic_arn

  tags = local.common_tags
}
```

## 🔗 Dependencies

- Layer 5 (Lambda + API GW + DynamoDB) phải tạo trước.
- `sns-topic-email` để gửi alarm.

## 📝 Notes

- Alarm cơ bản: **API GW 5xx**, **API latency p99**, **Lambda Errors/Throttles/Duration**, **DynamoDB ThrottledRequests**, **SQS DLQ depth**.
- Ngưỡng `thresholds` parameterize theo env (Prod siết hơn).
- Dashboard widget phối hợp metric + log filter để on-call có dashboard đầy đủ.
- Có thể mở rộng: Synthetic canary, X-Ray service map.
