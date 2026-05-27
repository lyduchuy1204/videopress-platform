output "layer_arn" {
  description = "ARN layer kèm version (gắn vào Lambda)."
  value       = null # aws_lambda_layer_version.this.arn
}

output "layer_version" {
  description = "Số version layer."
  value       = null
}
