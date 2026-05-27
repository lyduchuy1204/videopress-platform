variable "topic_name" {
  description = "Tên topic (vd 'videopress-uat-alerts')."
  type        = string
}

variable "email_endpoints" {
  description = "List email subscription. User phải confirm qua link AWS gửi."
  type        = list(string)
  default     = []
}

variable "kms_key_id" {
  description = "KMS key id mã hoá topic. null = AWS-managed."
  type        = string
  default     = null
}

variable "allowed_publish_services" {
  description = "List AWS service principal được phép publish (vd 'cloudwatch.amazonaws.com')."
  type        = list(string)
  default     = ["cloudwatch.amazonaws.com"]
}

variable "tags" {
  description = "Tag chuẩn."
  type        = map(string)
}
