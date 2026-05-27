# =============================================================================
# Module sqs-queue — Skeleton
# =============================================================================
# Queue chính + DLQ + alarm CloudWatch khi DLQ có message > threshold (stuck).
# =============================================================================

# resource "aws_sqs_queue" "dlq" {
#   name                       = "${var.queue_name}-dlq"
#   message_retention_seconds  = 1209600 # 14 ngày
#   kms_master_key_id          = var.kms_key_arn
#   tags                       = var.tags
# }
#
# resource "aws_sqs_queue" "this" {
#   name                       = var.queue_name
#   visibility_timeout_seconds = var.visibility_timeout
#   message_retention_seconds  = var.message_retention_seconds
#   kms_master_key_id          = var.kms_key_arn
#
#   redrive_policy = jsonencode({
#     deadLetterTargetArn = aws_sqs_queue.dlq.arn
#     maxReceiveCount     = var.max_receive_count
#   })
#
#   tags = var.tags
# }
#
# resource "aws_cloudwatch_metric_alarm" "dlq_stuck" {
#   alarm_name          = "${var.queue_name}-dlq-has-messages"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = 1
#   metric_name         = "ApproximateNumberOfMessagesVisible"
#   namespace           = "AWS/SQS"
#   period              = 300
#   statistic           = "Maximum"
#   threshold           = var.dlq_alarm_threshold
#   alarm_description   = "DLQ có message stuck — cần xem log compression Lambda"
#   treat_missing_data  = "notBreaching"
#   alarm_actions       = var.alarm_sns_topic_arns
#
#   dimensions = {
#     QueueName = aws_sqs_queue.dlq.name
#   }
#
#   tags = var.tags
# }
