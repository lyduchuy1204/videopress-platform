variable "bucket_name" {
  description = "Tên bucket (globally unique)."
  type        = string
}

variable "force_destroy" {
  description = "Cho phép xoá bucket có data. KHÔNG bật ở Prod."
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "KMS CMK ARN cho mã hoá. null = dùng AES256 AWS-managed."
  type        = string
  default     = null
}

variable "lifecycle_rules" {
  description = "List rule transition + expiration."
  type = list(object({
    id              = string
    transition_days = number
    storage_class   = string
    expiration_days = number
  }))
  default = []
}

variable "tags" {
  description = "Tag chuẩn."
  type        = map(string)
}
