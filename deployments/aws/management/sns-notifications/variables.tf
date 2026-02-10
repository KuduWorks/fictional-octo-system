variable "aws_region" {
  description = "AWS region for SNS topics (must be us-east-1 for AWS Budgets integration)"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = var.aws_region == "us-east-1"
    error_message = "SNS topics for AWS Budgets must be in us-east-1 region"
  }
}

variable "environment" {
  description = "Environment name (e.g., prod, dev, staging)"
  type        = string
  default     = "prod"
}

variable "org_alert_email" {
  description = "Email address for organization-wide budget alerts"
  type        = string
  default     = "finance@example.com"

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.org_alert_email))
    error_message = "Must be a valid email address"
  }
}

variable "member_alert_email" {
  description = "Email address for member account budget alerts"
  type        = string
  default     = "devops@example.com"

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.member_alert_email))
    error_message = "Must be a valid email address"
  }
}

variable "security_alert_email" {
  description = "Email address for security compliance alerts (AWS Config non-compliance notifications)"
  type        = string
  default     = "security@example.com"

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.security_alert_email))
    error_message = "Must be a valid email address"
  }
}
