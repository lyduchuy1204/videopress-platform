# =============================================================================
# flow-log.tf — VPC Flow Log → CloudWatch Logs
# =============================================================================
# Bật optional qua `var.enable_flow_log`. Mục đích: audit traffic, điều tra
# incident (vd phát hiện Lambda gọi IP lạ ngoài AWS).
#
# Cấu trúc:
#   1. CloudWatch Log Group (retention theo env: 30/30/90 ngày).
#   2. IAM Role để VPC Flow Log service publish vào log group.
#   3. Resource aws_flow_log gắn vào VPC.
# =============================================================================

resource "aws_cloudwatch_log_group" "flow_log" {
  count = var.enable_flow_log ? 1 : 0

  name              = "/aws/vpc/flow-log/${var.name}"
  retention_in_days = var.flow_log_retention_days

  tags = merge(var.tags, { Name = "${var.name}-flow-log" })
}

# -----------------------------------------------------------------------------
# IAM Role — service vpc-flow-logs assume role này để write log
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "flow_log_assume" {
  count = var.enable_flow_log ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "flow_log_publish" {
  count = var.enable_flow_log ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
    ]
    resources = ["${aws_cloudwatch_log_group.flow_log[0].arn}:*"]
  }
}

resource "aws_iam_role" "flow_log" {
  count = var.enable_flow_log ? 1 : 0

  name               = "${var.name}-flow-log-role"
  assume_role_policy = data.aws_iam_policy_document.flow_log_assume[0].json
  tags               = var.tags
}

resource "aws_iam_role_policy" "flow_log" {
  count = var.enable_flow_log ? 1 : 0

  name   = "${var.name}-flow-log-publish"
  role   = aws_iam_role.flow_log[0].id
  policy = data.aws_iam_policy_document.flow_log_publish[0].json
}

# -----------------------------------------------------------------------------
# Flow Log entry — gắn vào toàn bộ VPC, capture ALL traffic
# -----------------------------------------------------------------------------
resource "aws_flow_log" "this" {
  count = var.enable_flow_log ? 1 : 0

  iam_role_arn    = aws_iam_role.flow_log[0].arn
  log_destination = aws_cloudwatch_log_group.flow_log[0].arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name}-flow-log" })
}
