variable "aws_region" {
  description = "AWS region for budget resources (must be us-east-1 for AWS Budgets)"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = var.aws_region == "us-east-1"
    error_message = "AWS Budgets must be deployed in us-east-1 region"
  }
}

variable "environment" {
  description = "Environment name (e.g., prod, dev, staging)"
  type        = string
  default     = "prod"
}

variable "org_budget_limit" {
  description = "Organization-wide monthly budget limit in USD"
  type        = string
  default     = "100"

  validation {
    condition     = can(tonumber(var.org_budget_limit)) && tonumber(var.org_budget_limit) > 0
    error_message = "Budget limit must be a positive number"
  }
}

variable "member_budget_limit" {
  description = "Member account monthly budget limit in USD"
  type        = string
  default     = "90"

  validation {
    condition     = can(tonumber(var.member_budget_limit)) && tonumber(var.member_budget_limit) > 0
    error_message = "Budget limit must be a positive number"
  }
}

variable "member_account_id" {
  description = "AWS Member Account ID to track separately (leave empty to skip member budget)"
  type        = string
  default     = ""

  validation {
    condition     = var.member_account_id == "" || can(regex("^[0-9]{12}$", var.member_account_id))
    error_message = "Member account ID must be empty or a 12-digit number"
  }
}

variable "org_sns_topic_arn" {
  description = "ARN of SNS topic for organization budget alerts"
  type        = string

  validation {
    condition     = can(regex("^arn:aws:sns:", var.org_sns_topic_arn))
    error_message = "Must be a valid SNS topic ARN"
  }
}

variable "member_sns_topic_arn" {
  description = "ARN of SNS topic for member account budget alerts"
  type        = string

  validation {
    condition     = can(regex("^arn:aws:sns:", var.member_sns_topic_arn))
    error_message = "Must be a valid SNS topic ARN"
  }
}

variable "budget_start_date" {
  description = "Budget start date in YYYY-MM-DD format (defaults to current month)"
  type        = string
  default     = ""

  validation {
    condition     = var.budget_start_date == "" || can(regex("^[0-9]{4}-[0-9]{2}-01$", var.budget_start_date))
    error_message = "Budget start date must be in YYYY-MM-01 format (first day of month)"
  }
}
