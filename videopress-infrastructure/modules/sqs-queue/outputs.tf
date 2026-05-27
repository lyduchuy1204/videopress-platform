output "queue_url" {
  description = "URL queue chính (Lambda gửi message)."
  value       = null
}

output "queue_arn" {
  description = "ARN queue chính (event source mapping cho compression Lambda)."
  value       = null
}

output "dlq_url" {
  description = "URL DLQ (debug)."
  value       = null
}

output "dlq_arn" {
  description = "ARN DLQ."
  value       = null
}
