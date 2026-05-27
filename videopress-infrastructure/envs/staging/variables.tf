# =============================================================================
# Variables — env Staging
# =============================================================================

variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "ap-southeast-1"
}

variable "environment" {
  description = "Tên env — cố định 'staging'."
  type        = string
  default     = "staging"
}

variable "project" {
  description = "Tên project."
  type        = string
  default     = "videopress"
}

variable "owner_team" {
  description = "Team owner."
  type        = string
  default     = "devops-team"
}

variable "cost_center" {
  description = "Mã chi phí team."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR /16 cho VPC Staging."
  type        = string
  default     = "10.20.0.0/16"
}

variable "az_count" {
  description = "Số AZ cho Staging (2)."
  type        = number
  default     = 2
}

variable "single_nat_gateway" {
  description = "Single NAT cho Staging — vẫn cost-saving vì không phải prod."
  type        = bool
  default     = true
}

variable "artifact_bucket" {
  description = "S3 bucket chứa zip Lambda từ CI backend."
  type        = string
}

variable "artifact_version" {
  description = "Version artifact."
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
  description = "Email nhận alarm."
  type        = list(string)
  default     = []
}

variable "cognito_callback_urls" {
  description = "OAuth callback URL."
  type        = list(string)
  default     = []
}
