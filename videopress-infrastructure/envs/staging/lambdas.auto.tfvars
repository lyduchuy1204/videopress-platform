# =============================================================================
# Lambda config — Staging
# =============================================================================

lambdas = {
  authentication = {
    runtime = "python3.11"
    handler = "app.lambda_handler"
    memory  = 512
    timeout = 60
    vpc     = true
  }
  notification = {
    runtime = "python3.11"
    handler = "app.lambda_handler"
    memory  = 512
    timeout = 60
    vpc     = true
  }
  upload = {
    runtime = "python3.11"
    handler = "app.lambda_handler"
    memory  = 512
    timeout = 60
    vpc     = true
  }
  compression = {
    runtime = "python3.11"
    handler = "app.lambda_handler"
    memory  = 512
    timeout = 60
    vpc     = true
  }
  job_status = {
    runtime = "python3.11"
    handler = "app.lambda_handler"
    memory  = 512
    timeout = 60
    vpc     = true
  }
}
