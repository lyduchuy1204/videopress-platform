# =============================================================================
# Module vpc-network — Skeleton
# =============================================================================
# 1 VPC + 6 subnet (2 public + 2 private + 2 VPCE) + IGW + NAT (single hoặc per-AZ)
# + Route tables + 9 VPC Endpoints (2 Gateway free + 7 Interface) + Flow Log.
#
# CIDR /16 chia nhỏ:
#   public  : .1.0/24, .2.0/24      (NAT, ALB nếu có)
#   private : .11.0/24, .12.0/24    (Lambda VpcConfig)
#   vpce    : .21.0/24, .22.0/24    (ENI cho Interface Endpoint)
# =============================================================================

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # Tính subnet CIDR từ var.cidr_block (giả định /16). Tách thành 3 nhóm:
  # public: .1-.2, private: .11-.12, vpce: .21-.22
  public_subnets = [
    for i in range(var.az_count) : cidrsubnet(var.cidr_block, 8, i + 1)
  ]
  private_subnets = [
    for i in range(var.az_count) : cidrsubnet(var.cidr_block, 8, i + 11)
  ]
  vpce_subnets = [
    for i in range(var.az_count) : cidrsubnet(var.cidr_block, 8, i + 21)
  ]

  # Phân loại endpoint Gateway vs Interface
  gateway_endpoints   = [for s in var.vpc_endpoints : s if contains(["s3", "dynamodb"], s)]
  interface_endpoints = [for s in var.vpc_endpoints : s if !contains(["s3", "dynamodb"], s)]
}

# -----------------------------------------------------------------------------
# VPC + IGW
# -----------------------------------------------------------------------------
# resource "aws_vpc" "this" {
#   cidr_block           = var.cidr_block
#   enable_dns_support   = true
#   enable_dns_hostnames = true
#   tags                 = merge(var.tags, { Name = var.name })
# }
#
# resource "aws_internet_gateway" "this" {
#   vpc_id = aws_vpc.this.id
#   tags   = merge(var.tags, { Name = "${var.name}-igw" })
# }

# -----------------------------------------------------------------------------
# Subnets
# -----------------------------------------------------------------------------
# resource "aws_subnet" "public" {
#   count                   = var.az_count
#   vpc_id                  = aws_vpc.this.id
#   cidr_block              = local.public_subnets[count.index]
#   availability_zone       = local.azs[count.index]
#   map_public_ip_on_launch = false
#   tags = merge(var.tags, { Name = "${var.name}-public-${count.index + 1}" })
# }
#
# resource "aws_subnet" "private" { ... }
# resource "aws_subnet" "vpce"    { ... }

# -----------------------------------------------------------------------------
# NAT Gateway — single hoặc per-AZ
# -----------------------------------------------------------------------------
# resource "aws_eip" "nat" {
#   count  = var.single_nat ? 1 : var.az_count
#   domain = "vpc"
#   tags   = var.tags
# }
#
# resource "aws_nat_gateway" "this" {
#   count         = var.single_nat ? 1 : var.az_count
#   allocation_id = aws_eip.nat[count.index].id
#   subnet_id     = aws_subnet.public[count.index].id
#   tags          = merge(var.tags, { Name = "${var.name}-nat-${count.index + 1}" })
#   depends_on    = [aws_internet_gateway.this]
# }

# -----------------------------------------------------------------------------
# Route tables
# -----------------------------------------------------------------------------
# resource "aws_route_table" "public"  { ... 0.0.0.0/0 -> IGW ... }
# resource "aws_route_table" "private" { ... 0.0.0.0/0 -> NAT (per AZ hoặc single) ... }
# resource "aws_route_table" "vpce"    { ... chỉ local route ... }
# + aws_route_table_association cho từng subnet

# -----------------------------------------------------------------------------
# Security Group cho Interface Endpoint
# -----------------------------------------------------------------------------
# resource "aws_security_group" "vpce" {
#   name   = "${var.name}-vpce"
#   vpc_id = aws_vpc.this.id
#   ingress {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = [var.cidr_block]
#   }
#   tags = merge(var.tags, { Name = "${var.name}-vpce" })
# }

# -----------------------------------------------------------------------------
# VPC Endpoints — Gateway (s3, dynamodb) — FREE
# -----------------------------------------------------------------------------
# resource "aws_vpc_endpoint" "gateway" {
#   for_each          = toset(local.gateway_endpoints)
#   vpc_id            = aws_vpc.this.id
#   service_name      = "com.amazonaws.${data.aws_region.current.name}.${each.key}"
#   vpc_endpoint_type = "Gateway"
#   route_table_ids   = aws_route_table.private[*].id
#   tags              = merge(var.tags, { Name = "${var.name}-vpce-${each.key}" })
# }

# -----------------------------------------------------------------------------
# VPC Endpoints — Interface (execute-api, secrets, logs, sqs, sns, kms, cognito-idp)
# -----------------------------------------------------------------------------
# resource "aws_vpc_endpoint" "interface" {
#   for_each            = toset(local.interface_endpoints)
#   vpc_id              = aws_vpc.this.id
#   service_name        = "com.amazonaws.${data.aws_region.current.name}.${each.key}"
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = aws_subnet.vpce[*].id
#   security_group_ids  = [aws_security_group.vpce.id]
#   private_dns_enabled = true
#   tags                = merge(var.tags, { Name = "${var.name}-vpce-${each.key}" })
# }

# -----------------------------------------------------------------------------
# Flow Log → CloudWatch
# -----------------------------------------------------------------------------
# resource "aws_cloudwatch_log_group" "flow_log" {
#   count             = var.enable_flow_log ? 1 : 0
#   name              = "/aws/vpc/flow-log/${var.name}"
#   retention_in_days = var.flow_log_retention_days
#   tags              = var.tags
# }
#
# resource "aws_iam_role" "flow_log" { ... trust vpc-flow-logs.amazonaws.com ... }
# resource "aws_iam_role_policy" "flow_log" { ... CloudWatch logs:CreateLogStream/PutLogEvents ... }
#
# resource "aws_flow_log" "this" {
#   count           = var.enable_flow_log ? 1 : 0
#   iam_role_arn    = aws_iam_role.flow_log[0].arn
#   log_destination = aws_cloudwatch_log_group.flow_log[0].arn
#   traffic_type    = "ALL"
#   vpc_id          = aws_vpc.this.id
#   tags            = var.tags
# }

# data "aws_region" "current" {}
