variable "layer_name" {
  description = "Tên Lambda layer."
  type        = string
}

variable "description" {
  description = "Mô tả layer."
  type        = string
  default     = ""
}

variable "s3_bucket" {
  description = "Bucket chứa zip layer."
  type        = string
}

variable "s3_key" {
  description = "Object key zip layer."
  type        = string
}

variable "compatible_runtimes" {
  description = "Runtime tương thích."
  type        = list(string)
  default     = ["python3.11"]
}

variable "compatible_architectures" {
  description = "Architecture tương thích."
  type        = list(string)
  default     = ["x86_64"]
}

variable "tags" {
  description = "Tag chuẩn (lambda layer không nhận tag native, dùng cho data lookup)."
  type        = map(string)
  default     = {}
}
