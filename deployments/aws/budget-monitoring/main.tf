terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Module      = "budget-monitoring"
      Purpose     = "Cost-Control"
    }
  }
}

# Data source to get current AWS account
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

# ============================================================================
# ORGANIZATION-WIDE BUDGET
# ============================================================================

resource "aws_budgets_budget" "organization" {
  name              = "organization-monthly-budget"
  budget_type       = "COST"
  limit_amount      = var.org_budget_limit
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = var.budget_start_date != "" ? "${var.budget_start_date}_00:00" : null

  # Organization-wide scope (no filters = all accounts)

  # 80% actual threshold
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_sns_topic_arns = [var.org_sns_topic_arn]
  }

  # 100% actual threshold
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_sns_topic_arns = [var.org_sns_topic_arn]
  }

  # 100% forecasted threshold
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_sns_topic_arns = [var.org_sns_topic_arn]
  }

  lifecycle {
    ignore_changes = [
      time_period_start
    ]
  }
}

# ============================================================================
# MEMBER ACCOUNT BUDGET
# ============================================================================

resource "aws_budgets_budget" "member_account" {
  count = var.member_account_id != "" ? 1 : 0

  name              = "member-account-monthly-budget"
  budget_type       = "COST"
  limit_amount      = var.member_budget_limit
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = var.budget_start_date != "" ? "${var.budget_start_date}_00:00" : null

  cost_filter {
    name = "LinkedAccount"
    values = [
      var.member_account_id
    ]
  }

  # 50% actual threshold
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 50
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_sns_topic_arns = [var.member_sns_topic_arn]
  }

  # 80% actual threshold
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_sns_topic_arns = [var.member_sns_topic_arn]
  }

  # 100% actual threshold
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_sns_topic_arns = [var.member_sns_topic_arn]
  }

  # 100% forecasted threshold
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_sns_topic_arns = [var.member_sns_topic_arn]
  }

  lifecycle {
    ignore_changes = [
      time_period_start
    ]
  }
}
