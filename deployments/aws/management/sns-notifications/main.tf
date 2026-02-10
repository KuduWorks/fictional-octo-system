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
      Module      = "sns-notifications"
      Purpose     = "Budget-Alerting"
    }
  }
}

# Data source to get current AWS account
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

# ============================================================================
# SNS TOPIC: ORGANIZATION BUDGET ALERTS
# ============================================================================

resource "aws_sns_topic" "org_budget_alerts" {
  name         = "org-budget-alerts"
  display_name = "AWS Organization Budget Alerts"

  tags = {
    Name        = "org-budget-alerts"
    Description = "Organization-wide budget threshold alerts"
  }
}

resource "aws_sns_topic_subscription" "org_budget_email" {
  topic_arn = aws_sns_topic.org_budget_alerts.arn
  protocol  = "email"
  endpoint  = var.org_alert_email
}

# ============================================================================
# SNS TOPIC: MEMBER ACCOUNT BUDGET ALERTS
# ============================================================================

resource "aws_sns_topic" "member_budget_alerts" {
  name         = "member-budget-alerts"
  display_name = "Member Account Budget Alerts"

  tags = {
    Name        = "member-budget-alerts"
    Description = "Member account workload budget threshold alerts"
  }
}

resource "aws_sns_topic_subscription" "member_budget_email" {
  topic_arn = aws_sns_topic.member_budget_alerts.arn
  protocol  = "email"
  endpoint  = var.member_alert_email
}

# ============================================================================
# SNS TOPIC: SECURITY COMPLIANCE ALERTS
# ============================================================================

resource "aws_sns_topic" "security_compliance_alerts" {
  name         = "security-compliance-alerts"
  display_name = "Security Compliance Alerts"

  tags = {
    Name        = "security-compliance-alerts"
    Description = "AWS Config compliance and security policy violations"
  }
}

resource "aws_sns_topic_subscription" "security_email" {
  topic_arn = aws_sns_topic.security_compliance_alerts.arn
  protocol  = "email"
  endpoint  = var.security_alert_email
}
