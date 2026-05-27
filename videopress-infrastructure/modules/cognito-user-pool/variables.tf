variable "name" {
  description = "Tên user pool."
  type        = string
}

variable "environment" {
  description = "uat / staging / prod."
  type        = string
}

variable "mfa_configuration" {
  description = "OFF / OPTIONAL / ON."
  type        = string
  default     = "OPTIONAL"
}

variable "password_minimum_length" {
  description = "Độ dài tối thiểu password."
  type        = number
  default     = 12
}

variable "domain_prefix" {
  description = "Subdomain Cognito hosted UI."
  type        = string
}

variable "client_callback_urls" {
  description = "List OAuth callback URL."
  type        = list(string)
  default     = []
}

variable "groups" {
  description = "List group mặc định tạo trong pool."
  type        = list(string)
  default     = ["admins", "users"]
}

variable "advanced_security_mode" {
  description = "OFF / AUDIT / ENFORCED. Prod khuyến nghị ENFORCED."
  type        = string
  default     = "OFF"
}

variable "tags" {
  description = "Tag chuẩn."
  type        = map(string)
}
