# =============================================================================
# Lambda config — UAT
# File này COMMIT (không có secret), .auto.tfvars sẽ tự load mỗi terraform plan/apply.
# =============================================================================

lambdas = {
  authentication = {
    runtime = "python3.11"
    handler = "app.lambda_handler"
    memory  = 256
    timeout = 30
    vpc     = true
  }

  notification = {
    runtime = "python3.11"
    handler = "app.lambda_handler"
    memory  = 256
    timeout = 30
    vpc     = true
  }

  upload = {
    runtime = "python3.11"
    handler = "app.lambda_handler"
    memory  = 256
    timeout = 30
    vpc     = true
  }

  compression = {
    runtime = "python3.11"
    handler = "app.lambda_handler"
    memory  = 256 # SQS-triggered, KHÔNG nối API GW
    timeout = 30
    vpc     = true
  }

  job_status = {
    runtime = "python3.11"
    handler = "app.lambda_handler"
    memory  = 256
    timeout = 30
    vpc     = true
  }
}
