# =============================================================================
# Variables — env Prod
# =============================================================================

variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "ap-southeast-1"
}

variable "environment" {
  description = "Tên env — cố định 'prod'."
  type        = string
  default     = "prod"
}

variable "project" {
  description = "Tên project."
  type        = string
  default     = "videopress"
}

variable "owner_team" {
  description = "Team owner."
  type        = string
  default     = "sre-oncall"
}

variable "cost_center" {
  description = "Mã chi phí team."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR /16 cho VPC Prod."
  type        = string
  default     = "10.30.0.0/16"
}

variable "az_count" {
  description = "Số AZ cho Prod (3 — Multi-AZ HA)."
  type        = number
  default     = 3
}

variable "single_nat_gateway" {
  description = "Prod = false (NAT mỗi AZ — HA)."
  type        = bool
  default     = false
}

variable "artifact_bucket" {
  description = "S3 bucket chứa zip Lambda từ CI backend (account Prod)."
  type        = string
}

variable "artifact_version" {
  description = "Version artifact (semver tag)."
  type        = string
}

variable "layer_version" {
  description = "Version layer videopress-common."
  type        = string
}

variable "lambdas" {
  description = "Map config 5 Lambda."
  type = map(object({
    runtime = string
    handler = string
    memory  = number
    timeout = number
    vpc     = bool
  }))
}

variable "alert_email_recipients" {
  description = "Email on-call nhận alarm."
  type        = list(string)
}

variable "cognito_callback_urls" {
  description = "OAuth callback URL Prod."
  type        = list(string)
}
