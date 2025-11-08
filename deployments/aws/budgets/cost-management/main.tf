terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Optional: Configure backend for state storage
  # backend "s3" {
  #   bucket         = "fictional-octo-system-tfstate-YOUR-ACCOUNT-ID"
  #   key            = "aws/budgets/cost-management/terraform.tfstate"
  #   region         = "eu-north-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-locks"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Module      = "cost-management"
      Purpose     = "Budget-Tracking"
    }
  }
}

# Data source to get current AWS account
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

# SNS Topic for Budget Alerts
resource "aws_sns_topic" "budget_alerts" {
  name         = "aws-budget-alerts-${var.environment}"
  display_name = "AWS Budget Alerts (${var.environment})"

  tags = {
    Name        = "Budget Alert Notifications"
    Environment = var.environment
  }
}

# SNS Topic Policy to allow AWS Budgets to publish
resource "aws_sns_topic_policy" "budget_alerts_policy" {
  arn = aws_sns_topic.budget_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSBudgets-notification-1"
        Effect = "Allow"
        Principal = {
          Service = "budgets.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.budget_alerts.arn
      }
    ]
  })
}

# Email Subscription for Budget Alerts
resource "aws_sns_topic_subscription" "budget_email_alerts" {
  for_each = toset(var.alert_email_addresses)

  topic_arn = aws_sns_topic.budget_alerts.arn
  protocol  = "email"
  endpoint  = each.value
}

# Monthly Budget
resource "aws_budgets_budget" "monthly_budget" {
  name              = "monthly-budget-${var.environment}"
  budget_type       = "COST"
  limit_amount      = var.monthly_budget_limit
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = var.budget_start_date

  cost_filter {
    name = "LinkedAccount"
    values = [
      local.account_id,
    ]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = var.alert_threshold_actual_80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_sns_topic_arns  = [aws_sns_topic.budget_alerts.arn]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = var.alert_threshold_actual_100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_sns_topic_arns  = [aws_sns_topic.budget_alerts.arn]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = var.alert_threshold_forecasted_100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_sns_topic_arns  = [aws_sns_topic.budget_alerts.arn]
  }

  depends_on = [aws_sns_topic_policy.budget_alerts_policy]
}

# Quarterly Budget (Optional)
resource "aws_budgets_budget" "quarterly_budget" {
  count = var.enable_quarterly_budget ? 1 : 0

  name              = "quarterly-budget-${var.environment}"
  budget_type       = "COST"
  limit_amount      = var.quarterly_budget_limit
  limit_unit        = "USD"
  time_unit         = "QUARTERLY"
  time_period_start = var.budget_start_date

  cost_filter {
    name = "LinkedAccount"
    values = [
      local.account_id,
    ]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = var.alert_threshold_actual_80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_sns_topic_arns  = [aws_sns_topic.budget_alerts.arn]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = var.alert_threshold_actual_100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_sns_topic_arns  = [aws_sns_topic.budget_alerts.arn]
  }

  depends_on = [aws_sns_topic_policy.budget_alerts_policy]
}

# Service-Specific Budget (EC2)
resource "aws_budgets_budget" "ec2_budget" {
  count = var.enable_service_budgets ? 1 : 0

  name              = "ec2-budget-${var.environment}"
  budget_type       = "COST"
  limit_amount      = var.ec2_budget_limit
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = var.budget_start_date

  cost_filter {
    name = "Service"
    values = [
      "Amazon Elastic Compute Cloud - Compute",
    ]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = var.alert_threshold_actual_80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_sns_topic_arns  = [aws_sns_topic.budget_alerts.arn]
  }

  depends_on = [aws_sns_topic_policy.budget_alerts_policy]
}

# Service-Specific Budget (S3)
resource "aws_budgets_budget" "s3_budget" {
  count = var.enable_service_budgets ? 1 : 0

  name              = "s3-budget-${var.environment}"
  budget_type       = "COST"
  limit_amount      = var.s3_budget_limit
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = var.budget_start_date

  cost_filter {
    name = "Service"
    values = [
      "Amazon Simple Storage Service",
    ]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = var.alert_threshold_actual_80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_sns_topic_arns  = [aws_sns_topic.budget_alerts.arn]
  }

  depends_on = [aws_sns_topic_policy.budget_alerts_policy]
}

# Tag-Based Budget (Optional)
resource "aws_budgets_budget" "tag_based_budget" {
  for_each = var.tag_based_budgets

  name              = "tag-${each.key}-${var.environment}"
  budget_type       = "COST"
  limit_amount      = each.value.limit
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = var.budget_start_date

  cost_filter {
    name   = "TagKeyValue"
    values = ["${each.value.tag_key}$${each.value.tag_value}"]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = var.alert_threshold_actual_80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_sns_topic_arns  = [aws_sns_topic.budget_alerts.arn]
  }

  depends_on = [aws_sns_topic_policy.budget_alerts_policy]
}

# CloudWatch Alarm for high billing (additional layer)
resource "aws_cloudwatch_metric_alarm" "billing_alarm" {
  count = var.enable_cloudwatch_billing_alarm ? 1 : 0

  alarm_name          = "high-billing-alarm-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = "21600" # 6 hours
  statistic           = "Maximum"
  threshold           = var.cloudwatch_billing_threshold
  alarm_description   = "Alert when estimated charges exceed ${var.cloudwatch_billing_threshold} USD"
  alarm_actions       = [aws_sns_topic.budget_alerts.arn]

  dimensions = {
    Currency = "USD"
  }

  treat_missing_data = "notBreaching"
}
