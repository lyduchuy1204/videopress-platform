# =============================================================================
# Module s3-bucket-secure — Skeleton
# =============================================================================
# Bucket S3 chuẩn enterprise:
#   - KMS at-rest (CMK hoặc AWS-managed)
#   - Versioning bật
#   - Lifecycle (transition Glacier + expire)
#   - Block public access full
#   - (optional) MFA Delete — note: phải bật bằng root user, KHÔNG quản qua TF
# =============================================================================

# resource "aws_s3_bucket" "this" {
#   bucket        = var.bucket_name
#   force_destroy = var.force_destroy   # KHÔNG bật ở Prod
#   tags          = var.tags
# }
#
# resource "aws_s3_bucket_versioning" "this" {
#   bucket = aws_s3_bucket.this.id
#   versioning_configuration {
#     status = "Enabled"
#   }
# }
#
# resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
#   bucket = aws_s3_bucket.this.id
#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm     = var.kms_key_arn != null ? "aws:kms" : "AES256"
#       kms_master_key_id = var.kms_key_arn
#     }
#     bucket_key_enabled = true
#   }
# }
#
# resource "aws_s3_bucket_public_access_block" "this" {
#   bucket                  = aws_s3_bucket.this.id
#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }
#
# resource "aws_s3_bucket_lifecycle_configuration" "this" {
#   bucket = aws_s3_bucket.this.id
#
#   dynamic "rule" {
#     for_each = var.lifecycle_rules
#     content {
#       id     = rule.value.id
#       status = "Enabled"
#       filter {}
#       transition {
#         days          = rule.value.transition_days
#         storage_class = rule.value.storage_class
#       }
#       expiration {
#         days = rule.value.expiration_days
#       }
#     }
#   }
# }

# Note MFA Delete: dùng AWS CLI ngoài Terraform (yêu cầu root user + serial MFA).
# aws s3api put-bucket-versioning --bucket <name> --versioning-configuration Status=Enabled,MFADelete=Enabled \
#   --mfa "<MFA-serial> <code>" --profile <root>
