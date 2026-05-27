output "bucket_id" {
  description = "Bucket id (= name)."
  value       = var.bucket_name
}

output "bucket_arn" {
  description = "Bucket ARN."
  value       = null # aws_s3_bucket.this.arn
}

output "bucket_regional_domain_name" {
  description = "Regional domain name (cho VPC Endpoint)."
  value       = null
}
