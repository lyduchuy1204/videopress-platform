output "function_arn" {
  description = "ARN Lambda."
  value       = null # aws_lambda_function.this.arn
}

output "function_name" {
  description = "Tên function (gắn alarm CloudWatch)."
  value       = var.function_name
}

output "invoke_arn" {
  description = "Invoke ARN cho API Gateway integration."
  value       = null
}

output "role_arn" {
  description = "ARN execution role — caller có thể attach thêm policy."
  value       = null
}

output "log_group_name" {
  description = "Tên CloudWatch Log Group."
  value       = "/aws/lambda/${var.function_name}"
}
