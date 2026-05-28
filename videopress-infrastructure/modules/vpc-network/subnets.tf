# =============================================================================
# subnets.tf — 3 nhóm subnet (public / private / vpce), 1 cái mỗi AZ
# =============================================================================
# Mỗi nhóm có vai trò khác nhau (xem locals.tf), tách 3 resource cho rõ — KHÔNG
# gộp vào 1 resource chung với for_each lồng.
# =============================================================================

# -----------------------------------------------------------------------------
# Public subnet — chứa NAT Gateway, ALB (sau này nếu có).
# `map_public_ip_on_launch = false` vì chúng ta KHÔNG launch EC2 ở đây.
# -----------------------------------------------------------------------------
resource "aws_subnet" "public" {
  count = var.az_count

  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.public_subnets[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "${var.name}-public-${count.index + 1}"
    Tier = "public"
  })
}

# -----------------------------------------------------------------------------
# Private subnet — Lambda VpcConfig sẽ gắn vào đây.
# Outbound (gọi API ngoài) đi qua NAT Gateway ở public subnet.
# -----------------------------------------------------------------------------
resource "aws_subnet" "private" {
  count = var.az_count

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.private_subnets[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(var.tags, {
    Name = "${var.name}-private-${count.index + 1}"
    Tier = "private"
  })
}

# -----------------------------------------------------------------------------
# VPCE subnet — chỉ chứa ENI của Interface Endpoint.
# Tách riêng (không nhét chung private subnet) để:
#   1. Dễ đọc Flow Log: thấy IP trong .21-.23 = traffic AWS service, không phải app.
#   2. Áp Security Group hẹp (chỉ port 443 từ private subnet).
#   3. Không phải đếm IP ENI khi tính IP usable cho Lambda concurrent.
# -----------------------------------------------------------------------------
resource "aws_subnet" "vpce" {
  count = var.az_count

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.vpce_subnets[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(var.tags, {
    Name = "${var.name}-vpce-${count.index + 1}"
    Tier = "vpce"
  })
}
