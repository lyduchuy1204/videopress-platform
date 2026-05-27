# =============================================================================
# Module dynamodb-table — Skeleton
# =============================================================================
# DynamoDB table với PITR + encryption + tags + deletion protection (parameterizable).
# Tham chiếu IDEA.md "7 nguyên tắc an toàn DynamoDB":
#   1. prevent_destroy lifecycle (Prod)
#   2. deletion_protection_enabled (Staging + Prod)
#   3. PITR bật toàn thời gian
# =============================================================================

# resource "aws_dynamodb_table" "this" {
#   name         = var.table_name
#   billing_mode = var.billing_mode
#   hash_key     = var.hash_key
#   range_key    = var.range_key
#
#   deletion_protection_enabled = var.deletion_protection_enabled
#
#   dynamic "attribute" {
#     for_each = var.attributes
#     content {
#       name = attribute.value.name
#       type = attribute.value.type
#     }
#   }
#
#   point_in_time_recovery {
#     enabled = var.enable_pitr
#   }
#
#   server_side_encryption {
#     enabled     = var.kms_key_arn != null
#     kms_key_arn = var.kms_key_arn
#   }
#
#   dynamic "ttl" {
#     for_each = var.ttl_attribute != null ? [1] : []
#     content {
#       attribute_name = var.ttl_attribute
#       enabled        = true
#     }
#   }
#
#   dynamic "global_secondary_index" {
#     for_each = var.global_secondary_indexes
#     content {
#       name            = global_secondary_index.value.name
#       hash_key        = global_secondary_index.value.hash_key
#       range_key       = global_secondary_index.value.range_key
#       projection_type = global_secondary_index.value.projection_type
#     }
#   }
#
#   tags = var.tags
#
#   # CHÚ Ý: prevent_destroy phải set static — không thể dùng var trực tiếp ở 1.11.
#   # Workaround: tách 2 resource (with/without prevent_destroy) hoặc dùng module wrapper.
#   # Ở scaffold này để hardcoded comment cho rõ; thực tế caller (env prod) sẽ
#   # dùng module wrapper riêng nếu cần.
#   # lifecycle {
#   #   prevent_destroy = true     # set true cho Prod
#   # }
# }
