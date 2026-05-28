# =============================================================================
# endpoints.tf — VPC Endpoints (Gateway + Interface)
# =============================================================================
# 2 loại:
#   - Gateway   : free. Gắn vào route table của private subnet → boto3 gọi
#                 S3/DynamoDB sẽ tự đi qua endpoint thay vì NAT (giảm cost).
#   - Interface : ~$7.5/AZ/tháng. Tạo ENI trong vpce subnet, có DNS riêng.
#                 `private_dns_enabled = true` để code dùng tên DNS chuẩn AWS
#                 (vd `secretsmanager.ap-southeast-1.amazonaws.com`) tự resolve
#                 về ENI nội bộ.
# =============================================================================

# -----------------------------------------------------------------------------
# Gateway Endpoint — S3, DynamoDB
# -----------------------------------------------------------------------------
resource "aws_vpc_endpoint" "gateway" {
  for_each = toset(local.gateway_endpoints)

  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.${each.key}"
  vpc_endpoint_type = "Gateway"

  # Gắn vào TẤT CẢ private route table (mỗi AZ 1 cái) để Lambda từ AZ nào
  # cũng đi qua endpoint.
  route_table_ids = aws_route_table.private[*].id

  tags = merge(var.tags, {
    Name = "${var.name}-vpce-${each.key}"
    Type = "Gateway"
  })
}

# -----------------------------------------------------------------------------
# Interface Endpoint — execute-api, secretsmanager, logs, sqs, sns, kms,
# cognito-idp (tuỳ `var.vpc_endpoints`).
# -----------------------------------------------------------------------------
resource "aws_vpc_endpoint" "interface" {
  for_each = toset(local.interface_endpoints)

  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.${each.key}"
  vpc_endpoint_type = "Interface"

  subnet_ids          = aws_subnet.vpce[*].id
  security_group_ids  = [aws_security_group.vpce.id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.name}-vpce-${each.key}"
    Type = "Interface"
  })
}
