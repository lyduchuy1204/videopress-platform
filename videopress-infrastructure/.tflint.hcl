# =============================================================================
# TFLint — config root
# =============================================================================
# Doc: https://github.com/terraform-linters/tflint
# Doc plugin AWS: https://github.com/terraform-linters/tflint-ruleset-aws
# =============================================================================

config {
  # Bật phần lõi (preset recommended) — bao gồm convention check, deprecated, ...
  call_module_type = "all"
  force            = false
}

# Preset rule built-in cho Terraform core
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# Plugin AWS — quét convention/security của AWS resource
plugin "aws" {
  enabled = true
  version = "0.32.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"

  # Preset deep-check cần AWS credentials (chỉ chạy ở CI nếu cần),
  # local pre-commit dùng plain để khỏi cần creds.
  deep_check = false
}

# =============================================================================
# Rule bắt buộc 5 tag chuẩn cho mọi resource AWS taggable
# =============================================================================
rule "aws_resource_missing_tags" {
  enabled = true
  tags = [
    "Project",      # videopress
    "Environment",  # uat / staging / prod
    "Owner",        # devops-team / sre-leads / ...
    "ManagedBy",    # terraform
    "CostCenter",   # mã chi phí team
  ]
}

# =============================================================================
# Rule cảnh báo dùng resource đã deprecated / pattern xấu
# =============================================================================
rule "terraform_deprecated_interpolation" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_naming_convention" {
  enabled = true
  format  = "snake_case"
}

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}
