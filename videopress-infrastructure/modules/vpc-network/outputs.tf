# =============================================================================
# outputs.tf — Output module
# =============================================================================
# Các module/env stack khác consume các giá trị này (qua module reference).
# =============================================================================

output "vpc_id" {
  description = "ID của VPC vừa tạo."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "CIDR block của VPC."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "ID list các public subnet (chứa NAT Gateway)."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "ID list các private subnet (gắn vào Lambda VpcConfig)."
  value       = aws_subnet.private[*].id
}

output "vpce_subnet_ids" {
  description = "ID list các VPCE subnet (chứa ENI Interface Endpoint)."
  value       = aws_subnet.vpce[*].id
}

output "vpce_security_group_id" {
  description = "Security Group ID gắn vào ENI Interface Endpoint."
  value       = aws_security_group.vpce.id
}

output "nat_gateway_ids" {
  description = "ID list NAT Gateway (1 nếu single, N nếu per-AZ)."
  value       = aws_nat_gateway.this[*].id
}

output "vpc_endpoint_ids" {
  description = "Map service_name → VPC Endpoint ID. Module api-gateway-private dùng `vpc_endpoint_ids[\"execute-api\"]` để áp resource policy chỉ accept traffic từ VPCE này."
  value = merge(
    { for k, v in aws_vpc_endpoint.gateway : k => v.id },
    { for k, v in aws_vpc_endpoint.interface : k => v.id },
  )
}

output "azs" {
  description = "Danh sách AZ đang dùng (ví dụ ['ap-southeast-1a', 'ap-southeast-1b'])."
  value       = local.azs
}

output "flow_log_group_name" {
  description = "Tên CloudWatch Log Group chứa VPC Flow Log (null nếu disabled)."
  value       = var.enable_flow_log ? aws_cloudwatch_log_group.flow_log[0].name : null
}
