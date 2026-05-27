# =============================================================================
# vpc-network — Outputs
# =============================================================================

output "vpc_id" {
  description = "ID của VPC vừa tạo."
  value       = null # aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "CIDR block của VPC."
  value       = var.cidr_block
}

output "public_subnet_ids" {
  description = "ID list các public subnet (NAT, ALB)."
  value       = [] # aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "ID list các private subnet (Lambda VpcConfig)."
  value       = [] # aws_subnet.private[*].id
}

output "vpce_subnet_ids" {
  description = "ID list các VPCE subnet (ENI Interface Endpoint)."
  value       = [] # aws_subnet.vpce[*].id
}

output "vpce_security_group_id" {
  description = "Security group cho Interface Endpoint."
  value       = null # aws_security_group.vpce.id
}

output "vpc_endpoint_ids" {
  description = "Map service_name → VPCE id (cho execute-api để gắn API Gateway PRIVATE)."
  value       = {} # merge gateway + interface endpoint
}

output "nat_gateway_ids" {
  description = "ID list NAT Gateway."
  value       = [] # aws_nat_gateway.this[*].id
}
