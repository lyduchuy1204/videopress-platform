output "dashboard_name" {
  description = "Tên dashboard CloudWatch."
  value       = "${var.name}-dashboard"
}

output "alarm_arns" {
  description = "List ARN của tất cả alarm tạo ra."
  value       = []
}
