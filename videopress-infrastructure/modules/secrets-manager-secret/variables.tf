variable "secret_name" {
  description = "Tên secret (vd 'videopress/uat/3rd-party-api-key')."
  type        = string
}

variable "description" {
  description = "Mô tả secret."
  type        = string
  default     = ""
}

variable "kms_key_id" {
  description = "KMS key id. null = AWS-managed."
  type        = string
  default     = null
}

variable "recovery_window_in_days" {
  description = "Số ngày recovery sau khi delete. Set 0 cho UAT (xoá ngay), 30 cho Prod."
  type        = number
  default     = 7
}

variable "create_placeholder_value" {
  description = "Có tạo placeholder version không. False = caller tự PutSecretValue qua CLI."
  type        = bool
  default     = false
}

variable "rotation_lambda_arn" {
  description = "ARN Lambda rotation (optional)."
  type        = string
  default     = null
}

variable "rotation_days" {
  description = "Số ngày giữa 2 lần rotate."
  type        = number
  default     = 90
}

variable "tags" {
  description = "Tag chuẩn."
  type        = map(string)
}
