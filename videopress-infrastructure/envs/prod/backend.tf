# =============================================================================
# Backend — env Prod (account `prod` riêng)
# =============================================================================
# Account khác Non-prod — bootstrap stack phải chạy trên account prod trước.
# =============================================================================

terraform {
  backend "s3" {
    bucket = "<state-bucket-from-bootstrap>" # videopress-tfstate-prod-<acct>

    key    = "envs/prod/terraform.tfstate"
    region = "ap-southeast-1"

    encrypt    = true
    kms_key_id = "<kms-key-arn-from-bootstrap>"

    use_lockfile = true
  }
}
