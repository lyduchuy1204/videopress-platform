# =============================================================================
# Outputs — bootstrap stack
# Copy 3 giá trị này sang `envs/<env>/backend.tf` sau khi apply xong.
# =============================================================================

output "state_bucket_name" {
  description = "Tên S3 bucket lưu Terraform state — paste vào backend.tf của mỗi env."
  value       = aws_s3_bucket.tfstate.bucket
}

output "state_archive_bucket_name" {
  description = "Tên S3 bucket archive — Jenkins backup state pre-apply prod tới đây."
  value       = aws_s3_bucket.state_archive.bucket
}

output "kms_key_arn" {
  description = "KMS key ARN dùng để mã hoá state bucket. Paste vào backend.tf (kms_key_id)."
  value       = aws_kms_key.tfstate.arn
}

output "kms_key_alias" {
  description = "Alias KMS key (dễ nhớ hơn ARN)."
  value       = aws_kms_alias.tfstate.name
}
