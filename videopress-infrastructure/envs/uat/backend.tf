# =============================================================================
# Backend — env UAT
# =============================================================================
# State bucket sinh từ bootstrap stack chạy ở account `nonprod`.
# Sau khi `cd bootstrap && terraform apply`, copy output:
#   - state_bucket_name   →  `bucket`
#   - kms_key_arn         →  `kms_key_id`
# =============================================================================

terraform {
  backend "s3" {
    # Paste tên bucket từ output bootstrap (nonprod):
    bucket = "<state-bucket-from-bootstrap>" # vd "videopress-tfstate-nonprod-123456789012"

    key    = "envs/uat/terraform.tfstate"
    region = "ap-southeast-1"

    encrypt    = true
    kms_key_id = "<kms-key-arn-from-bootstrap>" # vd "arn:aws:kms:ap-southeast-1:123456789012:key/abc-..."

    # ✅ S3 native locking (Terraform >= 1.10) — KHÔNG cần DynamoDB lock table.
    use_lockfile = true
  }
}
