# =============================================================================
# vpc.tf — VPC + Internet Gateway
# =============================================================================

resource "aws_vpc" "this" {
  cidr_block = var.cidr_block

  # Cần `enable_dns_hostnames = true` để VPC Endpoint Interface
  # giải DNS đúng (vd `dynamodb.ap-southeast-1.amazonaws.com` → IP nội bộ VPCE).
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, { Name = var.name })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name}-igw" })
}
