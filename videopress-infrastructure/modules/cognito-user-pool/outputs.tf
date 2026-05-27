output "user_pool_id" {
  description = "User pool id."
  value       = null # aws_cognito_user_pool.this.id
}

output "user_pool_arn" {
  description = "User pool ARN — cấp cho API Gateway authorizer."
  value       = null
}

output "client_id" {
  description = "App client id."
  value       = null
}

output "client_secret" {
  description = "App client secret — lưu Secrets Manager, KHÔNG in ra log."
  value       = null
  sensitive   = true
}

output "domain" {
  description = "Cognito hosted UI domain."
  value       = null
}
