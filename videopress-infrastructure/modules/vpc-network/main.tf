# =============================================================================
# Module vpc-network — Index file
# =============================================================================
# Module này tách thành nhiều file theo concern để dễ đọc:
#
#   locals.tf            ← AZ list, chia subnet CIDR, phân loại endpoint
#   vpc.tf               ← VPC + Internet Gateway
#   subnets.tf           ← 3 nhóm subnet (public / private / vpce)
#   nat.tf               ← Elastic IP + NAT Gateway
#   routes.tf            ← 3 route table + association
#   security-groups.tf   ← SG cho Interface Endpoint
#   endpoints.tf         ← Gateway + Interface VPC Endpoints
#   flow-log.tf          ← VPC Flow Log → CloudWatch
#
# Đọc theo thứ tự trên để hiểu module từ trong ra ngoài.
#
# Sơ đồ tổng (cho 1 env):
#
#                ┌──────────────┐
#                │  Internet    │
#                └──────┬───────┘
#                       │
#                ┌──────▼───────┐
#                │  IGW         │
#                └──────┬───────┘
#                       │
#                       ▼ (route public RT)
#       ┌─────────────────────────────────┐
#       │ Public subnet (.1.0/24, ...)    │  ← NAT Gateway ở đây
#       └────────────────┬────────────────┘
#                        │
#                        ▼ (route private RT, 0.0.0.0/0 → NAT)
#       ┌─────────────────────────────────┐
#       │ Private subnet (.11.0/24, ...)  │  ← Lambda VpcConfig
#       └────────────────┬────────────────┘
#                        │
#                        │ HTTPS qua DNS riêng
#                        ▼
#       ┌─────────────────────────────────┐
#       │ VPCE subnet (.21.0/24, ...)     │  ← ENI Interface Endpoint
#       │  (execute-api / secrets / ...)  │
#       └─────────────────────────────────┘
#
# (S3 + DynamoDB đi qua Gateway Endpoint = entry trong route table private,
#  KHÔNG qua VPCE subnet, KHÔNG tốn $7.5/AZ.)
# =============================================================================
