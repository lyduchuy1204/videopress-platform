variable "name" {
  description = "Tên REST API (vd 'videopress-uat-api')."
  type        = string
}

variable "environment" {
  description = "uat / staging / prod."
  type        = string
}

variable "stage_name" {
  description = "API GW stage (uat / staging / prod)."
  type        = string
}

variable "allowed_vpce_ids" {
  description = "List VPC Endpoint id (execute-api) được phép gọi API. Resource policy chặn tất cả VPCE khác."
  type        = list(string)
}

variable "cognito_user_pool_arn" {
  description = "ARN Cognito User Pool dùng làm authorizer."
  type        = string
}

variable "log_retention_days" {
  description = "Số ngày giữ access log CloudWatch."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tag chuẩn."
  type        = map(string)
}
