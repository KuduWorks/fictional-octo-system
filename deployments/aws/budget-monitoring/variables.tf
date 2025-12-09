variable "aws_region" {
  description = "AWS region for budget resources (must be us-east-1 for AWS Budgets)"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = var.aws_region == "us-east-1"
    error_message = "AWS Budgets must be created in us-east-1 region"
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
  description = "AWS member account ID to track budget for"
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.member_account_id))
    error_message = "Member account ID must be a 12-digit number"
  }
}

variable "org_sns_topic_arn" {
  description = "SNS topic ARN for organization budget alerts"
  type        = string

  validation {
    condition     = can(regex("^arn:aws:sns:", var.org_sns_topic_arn))
    error_message = "Must be a valid SNS topic ARN"
  }
}

variable "member_sns_topic_arn" {
  description = "SNS topic ARN for member account budget alerts"
  type        = string

  validation {
    condition     = can(regex("^arn:aws:sns:", var.member_sns_topic_arn))
    error_message = "Must be a valid SNS topic ARN"
  }
}

variable "budget_start_date" {
  description = "Budget period start date in YYYY-MM-DD format. If null, starts from current month."
  type        = string
  default     = null  # Changed from empty string to null

  validation {
    condition     = var.budget_start_date == null || can(regex("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", var.budget_start_date))
    error_message = "Budget start date must be in YYYY-MM-DD format or null"
  }
}

variable "alert_emails" {
  description = "List of email addresses to receive budget alerts"
  type        = list(string)

  validation {
    condition     = length(var.alert_emails) > 0 && alltrue([for email in var.alert_emails : can(regex("^[^@]+@[^@]+\\.[^@]+$", email))])
    error_message = "Must provide at least one valid email address"
  }
}
