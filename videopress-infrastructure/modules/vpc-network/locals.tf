# =============================================================================
# locals.tf — Tính toán đầu vào dùng chung cho cả module
# =============================================================================
# Đặt riêng để: (1) các file resource bên dưới gọn, (2) dễ đọc logic chia
# subnet, (3) sửa logic 1 chỗ thay vì sửa rải rác.
# =============================================================================

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # ---------------------------------------------------------------------------
  # Lấy `var.az_count` AZ đầu tiên trong region (vd ap-southeast-1a, 1b, 1c).
  # ---------------------------------------------------------------------------
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # ---------------------------------------------------------------------------
  # Chia VPC /16 thành 3 nhóm subnet /24 — đặt offset cách xa nhau để
  # dễ phân biệt khi đọc IP trong CloudWatch / VPC Flow Log:
  #
  #   public  : .1.0/24, .2.0/24[, .3.0/24]      ← NAT GW, ALB nếu có
  #   private : .11.0/24, .12.0/24[, .13.0/24]   ← Lambda VpcConfig
  #   vpce    : .21.0/24, .22.0/24[, .23.0/24]   ← ENI cho Interface Endpoint
  #
  # Hàm `cidrsubnet("10.10.0.0/16", 8, N)` = "10.10.N.0/24"
  #   - newbits = 8  → /16 + 8 = /24
  #   - netnum  = N  → octet thứ 3
  # ---------------------------------------------------------------------------
  public_subnets  = [for i in range(var.az_count) : cidrsubnet(var.cidr_block, 8, i + 1)]
  private_subnets = [for i in range(var.az_count) : cidrsubnet(var.cidr_block, 8, i + 11)]
  vpce_subnets    = [for i in range(var.az_count) : cidrsubnet(var.cidr_block, 8, i + 21)]

  # ---------------------------------------------------------------------------
  # NAT Gateway: 1 cái (single, dùng chung) hay 1 cái mỗi AZ (HA).
  # ---------------------------------------------------------------------------
  nat_count = var.single_nat ? 1 : var.az_count

  # ---------------------------------------------------------------------------
  # Phân loại endpoint:
  #   - Gateway (free, gắn vào route table): chỉ S3 + DynamoDB.
  #   - Interface (~$7.5/AZ/tháng): còn lại.
  # ---------------------------------------------------------------------------
  gateway_services   = ["s3", "dynamodb"]
  gateway_endpoints  = [for s in var.vpc_endpoints : s if contains(local.gateway_services, s)]
  interface_endpoints = [for s in var.vpc_endpoints : s if !contains(local.gateway_services, s)]
}
