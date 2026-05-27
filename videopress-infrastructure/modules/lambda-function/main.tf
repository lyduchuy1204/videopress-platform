# =============================================================================
# Module lambda-function — Skeleton
# =============================================================================
# 1 Lambda function + IAM role + CloudWatch Log Group + permissions map.
# =============================================================================

# data "aws_iam_policy_document" "trust" {
#   statement {
#     actions = ["sts:AssumeRole"]
#     principals {
#       type        = "Service"
#       identifiers = ["lambda.amazonaws.com"]
#     }
#   }
# }
#
# resource "aws_iam_role" "this" {
#   name               = "${var.function_name}-role"
#   assume_role_policy = data.aws_iam_policy_document.trust.json
#   tags               = var.tags
# }
#
# resource "aws_iam_role_policy_attachment" "basic" {
#   role       = aws_iam_role.this.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
# }
#
# resource "aws_iam_role_policy_attachment" "vpc" {
#   count      = var.vpc_config != null ? 1 : 0
#   role       = aws_iam_role.this.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
# }
#
# resource "aws_iam_role_policy" "extra" {
#   for_each = { for i, p in var.policies : i => p }
#   role     = aws_iam_role.this.id
#   policy   = each.value
# }
#
# resource "aws_cloudwatch_log_group" "this" {
#   name              = "/aws/lambda/${var.function_name}"
#   retention_in_days = var.log_retention_days
#   tags              = var.tags
# }
#
# resource "aws_lambda_function" "this" {
#   function_name = var.function_name
#   role          = aws_iam_role.this.arn
#   handler       = var.handler
#   runtime       = var.runtime
#   memory_size   = var.memory
#   timeout       = var.timeout
#
#   s3_bucket = var.s3_bucket
#   s3_key    = var.s3_key
#
#   layers = var.layers
#
#   dynamic "vpc_config" {
#     for_each = var.vpc_config != null ? [var.vpc_config] : []
#     content {
#       subnet_ids         = vpc_config.value.subnet_ids
#       security_group_ids = vpc_config.value.security_group_ids
#     }
#   }
#
#   dynamic "environment" {
#     for_each = length(var.environment) > 0 ? [1] : []
#     content {
#       variables = var.environment
#     }
#   }
#
#   tracing_config {
#     mode = "Active" # X-Ray
#   }
#
#   tags = var.tags
#
#   depends_on = [aws_cloudwatch_log_group.this]
# }
