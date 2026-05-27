output "table_name" {
  description = "Tên bảng."
  value       = var.table_name
}

output "table_arn" {
  description = "ARN bảng (cấp cho IAM scope)."
  value       = null # aws_dynamodb_table.this.arn
}

output "stream_arn" {
  description = "Stream ARN (nếu bật streams)."
  value       = null
}
