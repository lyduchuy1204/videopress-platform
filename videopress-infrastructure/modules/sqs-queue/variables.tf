variable "queue_name" {
  description = "Tên queue (vd 'videopress-uat-compression-jobs')."
  type        = string
}

variable "visibility_timeout" {
  description = "Visibility timeout giây (>= Lambda timeout × 6)."
  type        = number
  default     = 360
}

variable "message_retention_seconds" {
  description = "Retention queue chính (giây). Mặc định 4 ngày."
  type        = number
  default     = 345600
}

variable "max_receive_count" {
  description = "Số lần message bị retry trước khi vào DLQ."
  type        = number
  default     = 3
}

variable "dlq_alarm_threshold" {
  description = "Số message DLQ vượt qua mới bắn alarm."
  type        = number
  default     = 0
}

variable "kms_key_arn" {
  description = "KMS CMK ARN (null = AWS-managed alias/aws/sqs)."
  type        = string
  default     = null
}

variable "alarm_sns_topic_arns" {
  description = "List SNS topic nhận alarm."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tag chuẩn."
  type        = map(string)
}
