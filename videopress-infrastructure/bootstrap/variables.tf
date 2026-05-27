# =============================================================================
# Variables — bootstrap stack
# =============================================================================

variable "account_alias" {
  description = "Alias của AWS account đang bootstrap. Hợp lệ: 'nonprod' (UAT+Staging) hoặc 'prod'."
  type        = string

  validation {
    condition     = contains(["nonprod", "prod"], var.account_alias)
    error_message = "account_alias phải là 'nonprod' hoặc 'prod'."
  }
}

variable "region" {
  description = "AWS region để tạo bucket state. Mặc định ap-southeast-1 (Singapore)."
  type        = string
  default     = "ap-southeast-1"
}

variable "tags" {
  description = "Tag chuẩn áp dụng cho mọi resource bootstrap."
  type        = map(string)
  default = {
    Project     = "videopress"
    Environment = "shared"
    Owner       = "devops-team"
    ManagedBy   = "terraform"
    CostCenter  = "platform"
    Stack       = "bootstrap"
  }
}

variable "force_destroy_archive" {
  description = "Cho phép xoá bucket state-archive khi destroy. KHÔNG bật ở prod."
  type        = bool
  default     = false
}
