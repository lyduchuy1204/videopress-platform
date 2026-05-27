# Module — `sqs-queue`

> 1 SQS queue chính + DLQ + CloudWatch alarm cho "message stuck trong DLQ". Dùng cho compression job pipeline.

## 📋 Inputs

| Tên | Type | Default | Mô tả |
|---|---|---|---|
| `queue_name` | `string` | — | Tên (vd `videopress-uat-compression-jobs`). |
| `visibility_timeout` | `number` | `360` | Phải ≥ Lambda timeout × 6. |
| `message_retention_seconds` | `number` | `345600` (4d) | Retention queue chính. |
| `max_receive_count` | `number` | `3` | Số lần retry trước vào DLQ. |
| `dlq_alarm_threshold` | `number` | `0` | Số message DLQ vượt mới alarm. |
| `kms_key_arn` | `string` | `null` | CMK; null = AWS-managed. |
| `alarm_sns_topic_arns` | `list(string)` | `[]` | SNS nhận alarm. |
| `tags` | `map(string)` | — | Tag chuẩn. |

## 📤 Outputs

| Tên | Mô tả |
|---|---|
| `queue_url` / `queue_arn` | Queue chính. |
| `dlq_url` / `dlq_arn` | DLQ. |

## 💡 Example usage

```hcl
module "sqs_compression" {
  source = "../../modules/sqs-queue"

  queue_name           = "videopress-${var.environment}-compression-jobs"
  visibility_timeout   = 360
  max_receive_count    = 3
  alarm_sns_topic_arns = [module.sns_alerts.topic_arn]

  tags = local.common_tags
}
```

## 🔗 Dependencies

- SNS topic alarm (optional, thường gắn `module.sns_alerts`).

## 📝 Notes

- **Visibility timeout**: AWS khuyến nghị ≥ 6× Lambda timeout — tránh retry sớm khi Lambda đang chạy.
- DLQ retention = 14 ngày (cứng) để có thời gian debug.
- Alarm `DLQ-has-messages` bắn ngay khi có 1 message — nghĩa là 1 job đã thất bại 3 lần.
- Compression Lambda phải có `ReceiveMessage`, `DeleteMessage`, `ChangeMessageVisibility` permission.
