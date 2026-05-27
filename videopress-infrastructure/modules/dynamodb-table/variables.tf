variable "table_name" {
  description = "Tên bảng (vd 'Users-uat', 'Jobs-prod')."
  type        = string
}

variable "billing_mode" {
  description = "PAY_PER_REQUEST hoặc PROVISIONED."
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "hash_key" {
  description = "Tên thuộc tính làm hash key."
  type        = string
}

variable "range_key" {
  description = "Tên thuộc tính làm range key (optional)."
  type        = string
  default     = null
}

variable "attributes" {
  description = "List attribute (chỉ key + GSI/LSI keys)."
  type = list(object({
    name = string
    type = string # S / N / B
  }))
}

variable "enable_pitr" {
  description = "Bật Point-In-Time Recovery (35 ngày). NÊN bật mọi env."
  type        = bool
  default     = true
}

variable "deletion_protection_enabled" {
  description = "Chặn xoá ở AWS API layer. Bật ở Staging + Prod."
  type        = bool
  default     = false
}

variable "prevent_destroy" {
  description = "Lifecycle prevent_destroy ở Terraform layer. Bật ở Prod."
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "KMS key ARN mã hoá at-rest. null = AWS-owned."
  type        = string
  default     = null
}

variable "global_secondary_indexes" {
  description = "List GSI (optional)."
  type = list(object({
    name            = string
    hash_key        = string
    range_key       = optional(string)
    projection_type = string
  }))
  default = []
}

variable "ttl_attribute" {
  description = "Tên attribute TTL (optional)."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tag chuẩn."
  type        = map(string)
}
