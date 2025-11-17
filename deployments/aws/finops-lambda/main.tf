# FinOps Lambda Function for Cost Anomaly Detection and Alerting
resource "aws_lambda_function" "finops_cost_anomaly" {
  filename         = "${path.module}/lambda.zip"
  function_name    = "finops-cost-anomaly"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = filebase64sha256("${path.module}/lambda.zip")

  environment {
    variables = {
      ALERT_EMAIL       = var.alert_email
      ANOMALY_THRESHOLD = var.anomaly_threshold
    }
  }
}
# IAM Role for Lambda Execution
resource "aws_iam_role" "lambda_exec" {
  name = "finops-lambda-exec"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}
# IAM Policy for Lambda to access Cost Explorer and SES
resource "aws_iam_role_policy" "lambda_policy" {
  name = "finops-lambda-policy"
  role = aws_iam_role.lambda_exec.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ce:GetCostAndUsage",
          "ses:SendEmail"
        ]
        Resource = "*"
      }
    ]
  })
}
# CloudWatch Event Rule to trigger Lambda daily
resource "aws_cloudwatch_event_rule" "schedule" {
  name                = "finops-cost-anomaly-schedule"
  # Runs once per day at 1pm EET (11:00 UTC)
  schedule_expression = "cron(0 11 * * ? *)"
}
# CloudWatch Event Target to link rule to Lambda
resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  target_id = "finops-cost-anomaly"
  arn       = aws_lambda_function.finops_cost_anomaly.arn
}
# Permission for CloudWatch to invoke Lambda
resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.finops_cost_anomaly.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule.arn
}