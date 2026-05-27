# =============================================================================
# Variables — env UAT
# =============================================================================

variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "ap-southeast-1"
}

variable "environment" {
  description = "Tên env — cố định 'uat'."
  type        = string
  default     = "uat"
}

variable "project" {
  description = "Tên project (dùng cho tag + naming)."
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

# -----------------------------------------------------------------------------
# Network
# -----------------------------------------------------------------------------
variable "vpc_cidr" {
  description = "CIDR /16 cho VPC UAT."
  type        = string
  default     = "10.10.0.0/16"
}

variable "az_count" {
  description = "Số AZ cho UAT (2 để tiết kiệm cost)."
  type        = number
  default     = 2
}

variable "single_nat_gateway" {
  description = "true ở UAT để giảm cost (1 NAT chung 2 AZ)."
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Lambda
# -----------------------------------------------------------------------------
variable "artifact_bucket" {
  description = "S3 bucket chứa zip Lambda từ CI backend."
  type        = string
}

variable "artifact_version" {
  description = "Version artifact (commit SHA hoặc tag)."
  type        = string
}

variable "layer_version" {
  description = "Version layer videopress-common."
  type        = string
}

variable "lambdas" {
  description = "Map config cho 5 Lambda — đọc từ lambdas.auto.tfvars."
  type = map(object({
    runtime = string
    handler = string
    memory  = number
    timeout = number
    vpc     = bool
  }))
}

# -----------------------------------------------------------------------------
# Notification
# -----------------------------------------------------------------------------
variable "alert_email_recipients" {
  description = "Email nhận alarm CloudWatch."
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Cognito
# -----------------------------------------------------------------------------
variable "cognito_callback_urls" {
  description = "OAuth callback URL cho Cognito hosted UI."
  type        = list(string)
  default     = []
}
