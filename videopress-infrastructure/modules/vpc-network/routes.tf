# =============================================================================
# routes.tf — 3 route table cho 3 nhóm subnet
# =============================================================================
# Logic định tuyến:
#   - public  : 0.0.0.0/0 → IGW                     (1 route table dùng chung)
#   - private : 0.0.0.0/0 → NAT (cùng AZ nếu HA)    (1 route table mỗi AZ)
#   - vpce    : chỉ local route (mặc định)          (1 route table dùng chung)
# =============================================================================

# -----------------------------------------------------------------------------
# Public — 1 route table dùng chung cho mọi public subnet
# -----------------------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.tags, { Name = "${var.name}-rt-public" })
}

resource "aws_route_table_association" "public" {
  count = var.az_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# -----------------------------------------------------------------------------
# Private — 1 route table MỖI AZ vì NAT có thể ở AZ khác nhau (Prod HA).
# Single NAT  → cả 2-3 RT cùng trỏ về NAT[0].
# Per-AZ NAT  → mỗi RT trỏ về NAT cùng AZ (giảm cross-AZ data transfer).
# -----------------------------------------------------------------------------
resource "aws_route_table" "private" {
  count = var.az_count

  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = (
      var.single_nat
      ? aws_nat_gateway.this[0].id                  # mọi AZ dùng chung NAT[0]
      : aws_nat_gateway.this[count.index].id        # NAT cùng AZ
    )
  }

  tags = merge(var.tags, {
    Name = "${var.name}-rt-private-${count.index + 1}"
  })
}

resource "aws_route_table_association" "private" {
  count = var.az_count

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# -----------------------------------------------------------------------------
# VPCE — chỉ local route (mặc định trong route table mới).
# KHÔNG có route ra IGW/NAT vì ENI Interface Endpoint chỉ phục vụ traffic
# nội bộ VPC → AWS service.
# -----------------------------------------------------------------------------
resource "aws_route_table" "vpce" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name}-rt-vpce" })
}

resource "aws_route_table_association" "vpce" {
  count = var.az_count

  subnet_id      = aws_subnet.vpce[count.index].id
  route_table_id = aws_route_table.vpce.id
}
