# =============================================================================
# Bootstrap — Terraform state backend stack
# =============================================================================
# Chạy 1 LẦN cho mỗi AWS account (Phương án B: 2 lần — nonprod + prod).
# Tạo:
#   - S3 bucket lưu state (versioning + encryption + block public)
#   - S3 bucket archive (Jenkins backup state pre-apply prod)
#   - KMS key + alias để mã hoá state
#
# CHÚ Ý:
#   - Stack này dùng backend "local" (state nằm trên máy chạy terraform).
#     Sau khi apply xong, copy state file vào nơi an toàn (ví dụ Vault/1Password)
#     hoặc dùng `terraform import` để self-manage qua chính bucket vừa tạo.
#   - KHÔNG xoá bucket sau khi xong — nếu xoá = mất state của tất cả env.
# =============================================================================

# -----------------------------------------------------------------------------
# Data source — lấy account ID hiện tại để tránh hardcode
# -----------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  # Bucket name globally unique — chèn account ID + alias vào suffix
  state_bucket_name   = "videopress-tfstate-${var.account_alias}-${data.aws_caller_identity.current.account_id}"
  archive_bucket_name = "videopress-state-archive-${data.aws_caller_identity.current.account_id}"
}

# -----------------------------------------------------------------------------
# KMS key cho mã hoá state file
# -----------------------------------------------------------------------------
resource "aws_kms_key" "tfstate" {
  description             = "KMS key mã hoá Terraform state cho VideoPress (${var.account_alias})"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = merge(var.tags, {
    Name = "videopress-tfstate-${var.account_alias}"
  })
}

resource "aws_kms_alias" "tfstate" {
  name          = "alias/videopress-tfstate-${var.account_alias}"
  target_key_id = aws_kms_key.tfstate.key_id
}

# -----------------------------------------------------------------------------
# S3 bucket — Terraform state
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "tfstate" {
  bucket = local.state_bucket_name

  # KHÔNG cho phép terraform destroy xoá bucket có data
  lifecycle {
    prevent_destroy = true
  }

  tags = merge(var.tags, {
    Name = local.state_bucket_name
  })
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.tfstate.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------------------------------------
# S3 bucket — State archive (Jenkins backup state pre-apply prod)
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "state_archive" {
  bucket        = local.archive_bucket_name
  force_destroy = var.force_destroy_archive

  tags = merge(var.tags, {
    Name    = local.archive_bucket_name
    Purpose = "state-pre-apply-snapshot"
  })
}

resource "aws_s3_bucket_versioning" "state_archive" {
  bucket = aws_s3_bucket.state_archive.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_archive" {
  bucket = aws_s3_bucket.state_archive.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.tfstate.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state_archive" {
  bucket = aws_s3_bucket.state_archive.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle: archive cũ > 90 ngày chuyển sang Glacier, > 365 ngày xoá
resource "aws_s3_bucket_lifecycle_configuration" "state_archive" {
  bucket = aws_s3_bucket.state_archive.id

  rule {
    id     = "archive-old-state"
    status = "Enabled"

    filter {}

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}
