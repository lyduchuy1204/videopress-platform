variable "function_name" {
  description = "Tên Lambda (vd 'videopress-uat-authentication')."
  type        = string
}

variable "handler" {
  description = "Entry point Python (module.handler)."
  type        = string
  default     = "app.lambda_handler"
}

variable "runtime" {
  description = "Lambda runtime."
  type        = string
  default     = "python3.11"
}

variable "memory" {
  description = "Memory MB (128-10240)."
  type        = number
  default     = 256
}

variable "timeout" {
  description = "Timeout giây (1-900)."
  type        = number
  default     = 30
}

variable "s3_bucket" {
  description = "S3 bucket chứa zip artifact."
  type        = string
}

variable "s3_key" {
  description = "Object key zip (vd 'authentication/v1.2.3.zip')."
  type        = string
}

variable "vpc_config" {
  description = "VPC config; null = chạy ngoài VPC."
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "environment" {
  description = "Map env var. KHÔNG để secret plain text — dùng Secrets Manager."
  type        = map(string)
  default     = {}
}

variable "policies" {
  description = "List IAM policy JSON inline gắn thêm vào execution role."
  type        = list(string)
  default     = []
}

variable "layers" {
  description = "List Lambda layer ARN (max 5)."
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "Retention CloudWatch Log Group."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tag chuẩn."
  type        = map(string)
}
