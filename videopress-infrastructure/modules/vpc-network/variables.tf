# =============================================================================
# vpc-network — Variables
# =============================================================================

variable "name" {
  description = "Prefix tên VPC (vd 'videopress-uat')."
  type        = string
}

variable "cidr_block" {
  description = "CIDR /16 của VPC (vd '10.10.0.0/16' cho UAT)."
  type        = string
}

variable "az_count" {
  description = "Số AZ. UAT/Staging = 2, Prod = 3."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "az_count phải là 2 hoặc 3."
  }
}

variable "single_nat" {
  description = "true = 1 NAT Gateway dùng chung (cost-saving, UAT/Staging). false = NAT mỗi AZ (HA, Prod)."
  type        = bool
  default     = true
}

variable "enable_flow_log" {
  description = "Bật VPC Flow Log → CloudWatch Logs."
  type        = bool
  default     = true
}

variable "flow_log_retention_days" {
  description = "Số ngày giữ Flow Log. UAT/Staging = 30, Prod = 90."
  type        = number
  default     = 30
}

variable "vpc_endpoints" {
  description = "Danh sách AWS service cần VPC Endpoint. Service Gateway (s3, dynamodb) miễn phí; còn lại Interface Endpoint."
  type        = list(string)
  default = [
    "s3",
    "dynamodb",
    "execute-api",
    "secretsmanager",
    "logs",
    "sqs",
    "sns",
    "kms",
    "cognito-idp",
  ]
}

variable "tags" {
  description = "Tag chuẩn áp dụng cho mọi resource."
  type        = map(string)
}
