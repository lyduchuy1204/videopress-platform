output "rest_api_id" {
  description = "REST API id."
  value       = null # aws_api_gateway_rest_api.this.id
}

output "rest_api_arn" {
  description = "REST API ARN (dùng cho IAM policy execute-api:Invoke)."
  value       = null
}

output "stage_invoke_url" {
  description = "Invoke URL kèm stage (vd https://abc.execute-api.<region>.amazonaws.com/uat)."
  value       = null
}

output "authorizer_id" {
  description = "Cognito authorizer id (gắn vào method)."
  value       = null
}

output "execution_arn" {
  description = "execution_arn để gắn lambda permission (api-gateway -> lambda invoke)."
  value       = null
}
