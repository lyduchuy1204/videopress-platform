# =============================================================================
# Module api-gateway-private — Skeleton
# =============================================================================
# REST API endpoint type PRIVATE — chỉ truy cập qua VPC Endpoint execute-api.
# Wiring với Cognito User Pool authorizer + resource policy chỉ cho phép VPCE
# trong list var.allowed_vpce_ids gọi vào.
# =============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# -----------------------------------------------------------------------------
# REST API
# -----------------------------------------------------------------------------
# resource "aws_api_gateway_rest_api" "this" {
#   name        = var.name
#   description = "Private REST API cho VideoPress (${var.environment})"
#
#   endpoint_configuration {
#     types            = ["PRIVATE"]
#     vpc_endpoint_ids = var.allowed_vpce_ids
#   }
#
#   # Resource policy — chỉ accept traffic từ VPCE list
#   policy = data.aws_iam_policy_document.resource_policy.json
#
#   tags = var.tags
# }
#
# data "aws_iam_policy_document" "resource_policy" {
#   statement {
#     effect    = "Deny"
#     principals { type = "*", identifiers = ["*"] }
#     actions   = ["execute-api:Invoke"]
#     resources = ["execute-api:/*"]
#     condition {
#       test     = "StringNotEquals"
#       variable = "aws:SourceVpce"
#       values   = var.allowed_vpce_ids
#     }
#   }
#   statement {
#     effect    = "Allow"
#     principals { type = "*", identifiers = ["*"] }
#     actions   = ["execute-api:Invoke"]
#     resources = ["execute-api:/*"]
#   }
# }

# -----------------------------------------------------------------------------
# Cognito Authorizer
# -----------------------------------------------------------------------------
# resource "aws_api_gateway_authorizer" "cognito" {
#   name            = "${var.name}-cognito"
#   rest_api_id     = aws_api_gateway_rest_api.this.id
#   type            = "COGNITO_USER_POOLS"
#   provider_arns   = [var.cognito_user_pool_arn]
#   identity_source = "method.request.header.Authorization"
# }

# -----------------------------------------------------------------------------
# Stage + Deployment + Logging
# -----------------------------------------------------------------------------
# resource "aws_api_gateway_deployment" "this" { ... }
# resource "aws_api_gateway_stage" "this" {
#   rest_api_id   = aws_api_gateway_rest_api.this.id
#   stage_name    = var.stage_name
#   xray_tracing_enabled = var.environment == "prod"
#   access_log_settings { ... }
#   tags = var.tags
# }

# Routes/methods/integrations cụ thể được cấu hình ở env (gọi qua module hoặc
# OpenAPI body) — module này chỉ đảm nhận PRIVATE + authorizer + resource policy.
