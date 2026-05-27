# =============================================================================
# Module sns-topic-email — Skeleton
# =============================================================================
# 1 SNS topic + email subscription + access policy giới hạn publisher.
# =============================================================================

data "aws_caller_identity" "current" {}

# resource "aws_sns_topic" "this" {
#   name              = var.topic_name
#   kms_master_key_id = var.kms_key_id
#   tags              = var.tags
# }
#
# resource "aws_sns_topic_subscription" "email" {
#   for_each  = toset(var.email_endpoints)
#   topic_arn = aws_sns_topic.this.arn
#   protocol  = "email"
#   endpoint  = each.value
# }
#
# data "aws_iam_policy_document" "topic_policy" {
#   statement {
#     sid     = "AllowAccountPublish"
#     effect  = "Allow"
#     actions = ["sns:Publish"]
#     resources = [aws_sns_topic.this.arn]
#     principals {
#       type        = "AWS"
#       identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
#     }
#   }
#
#   dynamic "statement" {
#     for_each = length(var.allowed_publish_services) > 0 ? [1] : []
#     content {
#       sid     = "AllowServicePublish"
#       effect  = "Allow"
#       actions = ["sns:Publish"]
#       resources = [aws_sns_topic.this.arn]
#       principals {
#         type        = "Service"
#         identifiers = var.allowed_publish_services
#       }
#     }
#   }
# }
#
# resource "aws_sns_topic_policy" "this" {
#   arn    = aws_sns_topic.this.arn
#   policy = data.aws_iam_policy_document.topic_policy.json
# }
