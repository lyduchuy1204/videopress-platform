# =============================================================================
# Module monitoring-stack — Skeleton
# =============================================================================
# CloudWatch dashboards + alarms (5xx, latency, throttle) + SNS alert.
# =============================================================================

# resource "aws_cloudwatch_dashboard" "this" {
#   dashboard_name = "${var.name}-dashboard"
#   dashboard_body = jsonencode({
#     widgets = [
#       # API GW 5xx rate
#       # Lambda Errors / Duration / Throttles
#       # DynamoDB ThrottledRequests
#       # SQS DLQ depth
#     ]
#   })
# }
#
# # ----- API GW 5xx alarm -----
# resource "aws_cloudwatch_metric_alarm" "api_5xx" {
#   alarm_name          = "${var.name}-api-5xx"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = 2
#   metric_name         = "5XXError"
#   namespace           = "AWS/ApiGateway"
#   period              = 300
#   statistic           = "Sum"
#   threshold           = var.thresholds.api_5xx
#   alarm_actions       = [var.alarm_sns_topic_arn]
#   dimensions          = { ApiName = var.api_name, Stage = var.stage_name }
#   tags                = var.tags
# }
#
# # ----- Lambda errors alarm (cho từng function) -----
# resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
#   for_each = toset(var.lambda_function_names)
#
#   alarm_name          = "${each.value}-errors"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = 1
#   metric_name         = "Errors"
#   namespace           = "AWS/Lambda"
#   period              = 300
#   statistic           = "Sum"
#   threshold           = var.thresholds.lambda_errors
#   alarm_actions       = [var.alarm_sns_topic_arn]
#   dimensions          = { FunctionName = each.value }
#   tags                = var.tags
# }
#
# # ----- Lambda throttles + duration p99 -----
# # ----- DynamoDB ThrottledRequests, ThrottledPutItemRequests -----
