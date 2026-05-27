# Module — `sns-topic-email`

> 1 SNS topic + email subscription + access policy hạn chế publisher.

## 📋 Inputs

| Tên | Type | Default | Mô tả |
|---|---|---|---|
| `topic_name` | `string` | — | Tên topic. |
| `email_endpoints` | `list(string)` | `[]` | List email subscriber (user confirm qua mail AWS gửi). |
| `kms_key_id` | `string` | `null` | KMS mã hoá topic. null = AWS-managed. |
| `allowed_publish_services` | `list(string)` | `["cloudwatch.amazonaws.com"]` | Service được publish. |
| `tags` | `map(string)` | — | Tag chuẩn. |

## 📤 Outputs

| Tên | Mô tả |
|---|---|
| `topic_arn` | ARN topic. |
| `topic_name` | Tên topic. |

## 💡 Example usage

```hcl
module "sns_alerts" {
  source = "../../modules/sns-topic-email"

  topic_name      = "videopress-${var.environment}-alerts"
  email_endpoints = var.alert_email_recipients

  tags = local.common_tags
}
```

## 🔗 Dependencies

- KMS key (optional).

## 📝 Notes

- Email subscription cần user **confirm thủ công** lần đầu (link AWS gửi qua mail). Nếu chưa confirm, message không tới.
- Access policy mặc định cho phép CloudWatch alarm publish vào topic.
- Lambda gửi notification dùng IAM permission `sns:Publish` riêng.
