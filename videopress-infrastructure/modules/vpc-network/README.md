# Module — `vpc-network`

> Tạo 1 VPC đầy đủ kèm 6 subnet (2 public + 2 private + 2 VPCE), IGW, NAT Gateway (single hoặc per-AZ), 9 VPC Endpoints (2 Gateway + 7 Interface) và Flow Log.

## 📋 Inputs

| Tên | Type | Default | Mô tả |
|---|---|---|---|
| `name` | `string` | — | Prefix tên (vd `videopress-uat`). |
| `cidr_block` | `string` | — | CIDR /16 của VPC (`10.10.0.0/16`, ...). |
| `az_count` | `number` | `2` | 2 cho UAT/Staging, 3 cho Prod. |
| `single_nat` | `bool` | `true` | `true` = 1 NAT (cost-saving), `false` = NAT mỗi AZ (HA). |
| `enable_flow_log` | `bool` | `true` | Bật VPC Flow Log. |
| `flow_log_retention_days` | `number` | `30` | UAT/Staging 30, Prod 90. |
| `vpc_endpoints` | `list(string)` | 9 service | s3, dynamodb (Gateway) + execute-api, secretsmanager, logs, sqs, sns, kms, cognito-idp (Interface). |
| `tags` | `map(string)` | — | Tag chuẩn. |

## 📤 Outputs

| Tên | Mô tả |
|---|---|
| `vpc_id` | ID VPC. |
| `vpc_cidr_block` | CIDR block. |
| `public_subnet_ids` | ID list public subnet. |
| `private_subnet_ids` | ID list private subnet (gắn Lambda VpcConfig). |
| `vpce_subnet_ids` | ID list VPCE subnet. |
| `vpce_security_group_id` | SG cho Interface Endpoint. |
| `vpc_endpoint_ids` | Map service → VPCE id (`execute-api` dùng cho API GW PRIVATE). |
| `nat_gateway_ids` | ID list NAT Gateway. |

## 💡 Example usage

```hcl
module "vpc" {
  source = "../../modules/vpc-network"

  name                    = "videopress-${var.environment}"
  cidr_block              = var.vpc_cidr           # 10.10.0.0/16 / 10.20 / 10.30
  az_count                = var.az_count           # 2 / 2 / 3
  single_nat              = var.single_nat_gateway # true / true / false
  enable_flow_log         = true
  flow_log_retention_days = var.environment == "prod" ? 90 : 30

  vpc_endpoints = [
    "s3", "dynamodb",                                # Gateway (free)
    "execute-api", "secretsmanager", "logs",         # Interface
    "sqs", "sns", "kms", "cognito-idp",
  ]

  tags = local.common_tags
}
```

## 🔗 Dependencies

- KHÔNG phụ thuộc module nào khác (đây là layer 1).
- Cần data source `aws_availability_zones` (cùng region với provider).

## 📝 Notes

- **CIDR planning**: chia /16 thành /24 — xem `IDEA.md` Network Architecture.
- **Cost**: Interface Endpoint ~$7.5/AZ/tháng × 7 service. Prod 3 AZ ≈ $157/tháng.
- **Gateway endpoint** miễn phí, gắn vào route table — dùng cho S3 + DynamoDB.
- **VPCE subnet TÁCH RIÊNG** với private subnet để dễ debug Flow Log + giới hạn SG.
- Khi Lambda chạy trong VPC, mỗi concurrent execution = 1 ENI = 1 IP private subnet → chọn `/24` (251 IP usable) cho project size vừa.
- Endpoint `execute-api` PHẢI bật `private_dns_enabled = true` để API GW PRIVATE giải DNS đúng VPCE.
