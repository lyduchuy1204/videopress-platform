# =============================================================================
# Env Prod — main.tf
# =============================================================================
# Layer 1 Network → 2 Identity → 3 Security → 4 Storage → 5 App → 6 Monitoring
# Khác Staging chính ở:
#   - 3 AZ + NAT mỗi AZ (HA)
#   - Cognito advanced_security_mode = ENFORCED
#   - DynamoDB prevent_destroy = true (lifecycle Terraform)
#   - S3 KHÔNG force_destroy
#   - log retention 90, flow_log 90
#   - Lambda memory 1024
# ⚠️ MFA Delete cho S3 phải bật BÊN NGOÀI Terraform (yêu cầu root user).
# =============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    Owner       = var.owner_team
    ManagedBy   = "terraform"
    CostCenter  = var.cost_center
  }
}

# -----------------------------------------------------------------------------
# Layer 1 — Network (3 AZ + NAT per AZ)
# -----------------------------------------------------------------------------
module "vpc" {
  source = "../../modules/vpc-network"

  name                    = "${var.project}-${var.environment}"
  cidr_block              = var.vpc_cidr
  az_count                = var.az_count
  single_nat              = var.single_nat_gateway
  enable_flow_log         = true
  flow_log_retention_days = 90 # Prod

  vpc_endpoints = [
    "s3", "dynamodb",
    "execute-api", "secretsmanager", "logs",
    "sqs", "sns", "kms", "cognito-idp",
  ]

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Layer 2 — Identity
# -----------------------------------------------------------------------------
module "cognito" {
  source = "../../modules/cognito-user-pool"

  name                   = "${var.project}-${var.environment}"
  environment            = var.environment
  mfa_configuration      = "ON"
  domain_prefix          = "${var.project}-${var.environment}"
  client_callback_urls   = var.cognito_callback_urls
  advanced_security_mode = "ENFORCED" # Prod — adaptive auth

  tags = local.common_tags

  depends_on = [module.vpc]
}

# -----------------------------------------------------------------------------
# Layer 3 — Security
# -----------------------------------------------------------------------------
module "secret_thirdparty" {
  source = "../../modules/secrets-manager-secret"

  secret_name              = "${var.project}/${var.environment}/3rd-party-api-key"
  description              = "API key cho dịch vụ thumbnail bên thứ 3 (Prod)"
  recovery_window_in_days  = 30 # Prod — buffer 30 ngày
  create_placeholder_value = true

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Layer 4 — Storage
# -----------------------------------------------------------------------------
module "s3_input" {
  source = "../../modules/s3-bucket-secure"

  bucket_name   = "${var.project}-input-${var.environment}-${data.aws_caller_identity.current.account_id}"
  force_destroy = false # PROD — KHÔNG xoá data

  lifecycle_rules = [{
    id              = "expire-raw-uploads"
    transition_days = 30
    storage_class   = "STANDARD_IA"
    expiration_days = 365
  }]

  tags = local.common_tags
}

module "s3_output" {
  source = "../../modules/s3-bucket-secure"

  bucket_name   = "${var.project}-output-${var.environment}-${data.aws_caller_identity.current.account_id}"
  force_destroy = false

  tags = local.common_tags
}

module "dynamodb_users" {
  source = "../../modules/dynamodb-table"

  table_name                  = "Users-${var.environment}"
  hash_key                    = "user_id"
  attributes                  = [{ name = "user_id", type = "S" }]
  enable_pitr                 = true
  deletion_protection_enabled = true
  prevent_destroy             = true # PROD — TF lifecycle

  tags = local.common_tags
}

module "dynamodb_jobs" {
  source = "../../modules/dynamodb-table"

  table_name = "Jobs-${var.environment}"
  hash_key   = "job_id"

  attributes = [
    { name = "job_id", type = "S" },
    { name = "user_id", type = "S" },
  ]

  global_secondary_indexes = [{
    name            = "by-user-id"
    hash_key        = "user_id"
    range_key       = null
    projection_type = "ALL"
  }]

  enable_pitr                 = true
  deletion_protection_enabled = true
  prevent_destroy             = true
  ttl_attribute               = "expires_at"

  tags = local.common_tags
}

module "dynamodb_notifications" {
  source = "../../modules/dynamodb-table"

  table_name = "Notifications-${var.environment}"
  hash_key   = "user_id"
  range_key  = "created_at"
  attributes = [
    { name = "user_id", type = "S" },
    { name = "created_at", type = "S" },
  ]
  enable_pitr                 = true
  deletion_protection_enabled = true
  prevent_destroy             = true

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Layer 5 — App
# -----------------------------------------------------------------------------
module "lambda_layer" {
  source = "../../modules/lambda-layer"

  layer_name          = "${var.project}-common-${var.environment}"
  description         = "Shared deps: powertools + pydantic + boto3 (Prod)"
  s3_bucket           = var.artifact_bucket
  s3_key              = "layer/${var.project}-common-${var.layer_version}.zip"
  compatible_runtimes = ["python3.11"]

  tags = local.common_tags
}

module "sns_alerts" {
  source = "../../modules/sns-topic-email"

  topic_name      = "${var.project}-${var.environment}-alerts"
  email_endpoints = var.alert_email_recipients

  tags = local.common_tags
}

module "sqs_compression" {
  source = "../../modules/sqs-queue"

  queue_name           = "${var.project}-${var.environment}-compression-jobs"
  visibility_timeout   = 720
  max_receive_count    = 5 # Prod — retry nhiều hơn trước vào DLQ
  alarm_sns_topic_arns = [module.sns_alerts.topic_arn]

  tags = local.common_tags
}

module "lambda" {
  source   = "../../modules/lambda-function"
  for_each = var.lambdas

  function_name = "${var.project}-${var.environment}-${each.key}"
  handler       = each.value.handler
  runtime       = each.value.runtime
  memory        = each.value.memory
  timeout       = each.value.timeout

  s3_bucket = var.artifact_bucket
  s3_key    = "${each.key}/${var.artifact_version}.zip"

  vpc_config = each.value.vpc ? {
    subnet_ids         = module.vpc.private_subnet_ids
    security_group_ids = [module.vpc.vpce_security_group_id]
  } : null

  environment = {
    USER_POOL_ID          = module.cognito.user_pool_id
    USERS_TABLE           = module.dynamodb_users.table_name
    JOBS_TABLE            = module.dynamodb_jobs.table_name
    NOTIF_TABLE           = module.dynamodb_notifications.table_name
    INPUT_BUCKET          = module.s3_input.bucket_id
    OUTPUT_BUCKET         = module.s3_output.bucket_id
    COMPRESSION_QUEUE_URL = module.sqs_compression.queue_url
    SECRET_3RD_PARTY      = module.secret_thirdparty.secret_name
    ALERT_TOPIC_ARN       = module.sns_alerts.topic_arn
  }

  layers             = [module.lambda_layer.layer_arn]
  log_retention_days = 90 # Prod

  policies = [
    file("${path.root}/../../policies/lambda-execution-base.json"),
    file("${path.root}/../../policies/lambda-dynamodb-rw-scoped.json"),
    file("${path.root}/../../policies/lambda-s3-rw-scoped.json"),
  ]

  tags = local.common_tags

  depends_on = [
    module.dynamodb_users, module.dynamodb_jobs, module.dynamodb_notifications,
    module.s3_input, module.s3_output, module.sqs_compression, module.sns_alerts,
  ]
}

module "api_gw" {
  source = "../../modules/api-gateway-private"

  name                  = "${var.project}-${var.environment}-api"
  environment           = var.environment
  stage_name            = var.environment
  allowed_vpce_ids      = [module.vpc.vpc_endpoint_ids["execute-api"]]
  cognito_user_pool_arn = module.cognito.user_pool_arn
  log_retention_days    = 90

  tags = local.common_tags

  depends_on = [module.lambda]
}

# -----------------------------------------------------------------------------
# Layer 6 — Monitoring (threshold siết hơn)
# -----------------------------------------------------------------------------
module "monitoring" {
  source = "../../modules/monitoring-stack"

  name       = "${var.project}-${var.environment}"
  api_name   = module.api_gw.rest_api_id
  stage_name = var.environment

  lambda_function_names = [for k, v in module.lambda : v.function_name]
  dynamodb_table_names = [
    module.dynamodb_users.table_name,
    module.dynamodb_jobs.table_name,
    module.dynamodb_notifications.table_name,
  ]

  alarm_sns_topic_arn = module.sns_alerts.topic_arn

  thresholds = {
    api_5xx          = 1     # Prod siết hơn
    api_latency_p99  = 2000  # 2s
    lambda_errors    = 1
    lambda_throttles = 1
    lambda_duration  = 50000 # 50s (Lambda timeout 60)
  }

  tags = local.common_tags

  depends_on = [module.api_gw, module.lambda]
}
