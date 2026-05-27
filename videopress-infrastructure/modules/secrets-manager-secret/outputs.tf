output "secret_arn" {
  description = "ARN secret (cấp cho Lambda IAM)."
  value       = null
}

output "secret_name" {
  description = "Tên secret."
  value       = var.secret_name
}
