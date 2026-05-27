# =============================================================================
# Module secrets-manager-secret — Skeleton
# =============================================================================
# 1 Secrets Manager secret + (optional) rotation Lambda placeholder.
# =============================================================================

# resource "aws_secretsmanager_secret" "this" {
#   name        = var.secret_name
#   description = var.description
#   kms_key_id  = var.kms_key_id
#
#   recovery_window_in_days = var.recovery_window_in_days
#
#   tags = var.tags
# }
#
# # KHÔNG để giá trị thật vào Terraform — chỉ tạo "shell" secret, giá trị sẽ
# # được publish qua AWS CLI / Vault hoặc rotation lambda.
# # Nếu cần placeholder: dùng aws_secretsmanager_secret_version với jsonencode("<change-me>")
#
# resource "aws_secretsmanager_secret_version" "placeholder" {
#   count         = var.create_placeholder_value ? 1 : 0
#   secret_id     = aws_secretsmanager_secret.this.id
#   secret_string = jsonencode({ placeholder = "set-via-cli-or-rotation" })
#
#   lifecycle {
#     ignore_changes = [secret_string] # rotation sẽ thay đổi, đừng plan diff
#   }
# }
#
# # Optional rotation:
# # resource "aws_secretsmanager_secret_rotation" "this" {
# #   count               = var.rotation_lambda_arn != null ? 1 : 0
# #   secret_id           = aws_secretsmanager_secret.this.id
# #   rotation_lambda_arn = var.rotation_lambda_arn
# #   rotation_rules { automatically_after_days = var.rotation_days }
# # }
