# =============================================================================
# Backend — env Staging (cùng account `nonprod` với UAT)
# =============================================================================
terraform {
  backend "s3" {
    bucket = "<state-bucket-from-bootstrap>" # videopress-tfstate-nonprod-<acct>

    key    = "envs/staging/terraform.tfstate"
    region = "ap-southeast-1"

    encrypt    = true
    kms_key_id = "<kms-key-arn-from-bootstrap>"

    use_lockfile = true
  }
}
