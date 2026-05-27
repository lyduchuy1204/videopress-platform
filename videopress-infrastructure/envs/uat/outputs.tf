# =============================================================================
# Outputs — env UAT
# =============================================================================

output "vpc_id" {
  description = "ID VPC UAT."
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Subnet private — Lambda VpcConfig."
  value       = module.vpc.private_subnet_ids
}

output "api_invoke_url" {
  description = "URL invoke API Gateway (chỉ truy cập qua VPN tới VPCE)."
  value       = module.api_gw.stage_invoke_url
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool id."
  value       = module.cognito.user_pool_id
}

output "cognito_client_id" {
  description = "Cognito App Client id."
  value       = module.cognito.client_id
}

output "s3_input_bucket" {
  description = "Bucket nhận video upload từ user."
  value       = module.s3_input.bucket_id
}

output "s3_output_bucket" {
  description = "Bucket lưu video sau nén."
  value       = module.s3_output.bucket_id
}

output "compression_queue_url" {
  description = "URL SQS queue cho compression jobs."
  value       = module.sqs_compression.queue_url
}

output "alerts_sns_topic_arn" {
  description = "SNS topic nhận alarm."
  value       = module.sns_alerts.topic_arn
}
