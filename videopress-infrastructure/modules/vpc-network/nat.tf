# =============================================================================
# nat.tf — Elastic IP + NAT Gateway
# =============================================================================
# Số lượng = `local.nat_count`:
#   - UAT / Staging  → 1 NAT (cost-saving, ~$32/tháng).
#   - Prod           → mỗi AZ 1 NAT (HA, ~$96/tháng cho 3 AZ).
# =============================================================================

resource "aws_eip" "nat" {
  count = local.nat_count

  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name}-nat-eip-${count.index + 1}"
  })
}

resource "aws_nat_gateway" "this" {
  count = local.nat_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.tags, {
    Name = "${var.name}-nat-${count.index + 1}"
  })

  # NAT Gateway phải đợi IGW attach xong mới có route ra Internet.
  depends_on = [aws_internet_gateway.this]
}
