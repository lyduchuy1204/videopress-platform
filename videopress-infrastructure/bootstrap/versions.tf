# =============================================================================
# Versions — bootstrap stack
# =============================================================================
terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Provider mặc định — region lấy từ var.region.
# Account khác nhau (nonprod / prod) chạy stack này 1 lần per account, dùng
# AWS profile / OIDC khác nhau khi `terraform apply`.
provider "aws" {
  region = var.region

  default_tags {
    tags = var.tags
  }
}
