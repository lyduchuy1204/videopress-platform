variable "name" {
  description = "Prefix tên (vd 'videopress-uat')."
  type        = string
}

variable "api_name" {
  description = "Tên API Gateway để filter metric."
  type        = string
}

variable "stage_name" {
  description = "Stage API GW (uat/staging/prod)."
  type        = string
}

variable "lambda_function_names" {
  description = "List Lambda function name để alarm Errors/Throttles/Duration."
  type        = list(string)
  default     = []
}

variable "dynamodb_table_names" {
  description = "List DynamoDB table cần alarm Throttle."
  type        = list(string)
  default     = []
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic gửi alarm."
  type        = string
}

variable "thresholds" {
  description = "Threshold các alarm."
  type = object({
    api_5xx          = number
    api_latency_p99  = number
    lambda_errors    = number
    lambda_throttles = number
    lambda_duration  = number
  })
  default = {
    api_5xx          = 5
    api_latency_p99  = 3000
    lambda_errors    = 1
    lambda_throttles = 1
    lambda_duration  = 25000
  }
}

variable "tags" {
  description = "Tag chuẩn."
  type        = map(string)
}
