# =============================================================================
# security-groups.tf — SG cho Interface Endpoint (VPCE)
# =============================================================================
# 1 SG duy nhất gắn vào tất cả ENI Interface Endpoint, cho phép port 443
# từ trong VPC. KHÔNG cần SG khác cho Gateway Endpoint (vì Gateway Endpoint
# không có ENI, chỉ là route table entry).
# =============================================================================

resource "aws_security_group" "vpce" {
  name        = "${var.name}-vpce"
  description = "Allow HTTPS from inside VPC to Interface Endpoint ENIs"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTPS from VPC CIDR (Lambda private subnet → VPCE)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.cidr_block]
  }

  # Outbound mặc định allow all (ENI VPCE chỉ trả lời, không tự gọi ra).
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-vpce" })
}
