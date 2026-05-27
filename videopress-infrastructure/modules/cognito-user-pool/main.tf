# =============================================================================
# Module cognito-user-pool — Skeleton
# =============================================================================

# resource "aws_cognito_user_pool" "this" {
#   name = var.name
#
#   password_policy {
#     minimum_length    = var.password_minimum_length
#     require_lowercase = true
#     require_uppercase = true
#     require_numbers   = true
#     require_symbols   = true
#   }
#
#   mfa_configuration = var.mfa_configuration
#
#   software_token_mfa_configuration {
#     enabled = var.mfa_configuration != "OFF"
#   }
#
#   user_pool_add_ons {
#     advanced_security_mode = var.advanced_security_mode
#   }
#
#   schema {
#     name                = "email"
#     attribute_data_type = "String"
#     required            = true
#     mutable             = true
#   }
#
#   tags = var.tags
# }
#
# resource "aws_cognito_user_pool_client" "this" {
#   name         = "${var.name}-client"
#   user_pool_id = aws_cognito_user_pool.this.id
#
#   generate_secret               = true
#   refresh_token_validity        = 30
#   allowed_oauth_flows_user_pool_client = true
#   allowed_oauth_flows           = ["code"]
#   allowed_oauth_scopes          = ["openid", "email", "profile"]
#   callback_urls                 = var.client_callback_urls
#   supported_identity_providers  = ["COGNITO"]
# }
#
# resource "aws_cognito_user_pool_domain" "this" {
#   domain       = var.domain_prefix
#   user_pool_id = aws_cognito_user_pool.this.id
# }
#
# resource "aws_cognito_user_group" "groups" {
#   for_each     = toset(var.groups)
#   name         = each.value
#   user_pool_id = aws_cognito_user_pool.this.id
# }
