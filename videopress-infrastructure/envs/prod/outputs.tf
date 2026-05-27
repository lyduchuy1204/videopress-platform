output "vpc_id" {
  description = "VPC id Prod."
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Subnet private (Multi-AZ)."
  value       = module.vpc.private_subnet_ids
}

output "api_invoke_url" {
  description = "URL invoke API GW (qua VPN/Direct Connect)."
  value       = module.api_gw.stage_invoke_url
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool id Prod."
  value       = module.cognito.user_pool_id
}

output "cognito_client_id" {
  description = "Cognito App Client id."
  value       = module.cognito.client_id
}

output "s3_input_bucket" {
  description = "Bucket video upload (Prod, KHÔNG xoá)."
  value       = module.s3_input.bucket_id
}

output "s3_output_bucket" {
  description = "Bucket video sau nén (Prod)."
  value       = module.s3_output.bucket_id
}

output "compression_queue_url" {
  description = "URL SQS compression."
  value       = module.sqs_compression.queue_url
}

output "alerts_sns_topic_arn" {
  description = "SNS topic alarm — on-call subscribe."
  value       = module.sns_alerts.topic_arn
}
