variable "aws_region" {
  description = "AWS region for CloudTrail resources (should match your primary region)"
  type        = string
  default     = "eu-north-1"
}

variable "environment" {
  description = "Environment name (e.g., prod, dev, staging)"
  type        = string
  default     = "prod"
}

variable "member_account_id" {
  description = "Member account ID that should have read access to CloudTrail logs"
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.member_account_id))
    error_message = "Member account ID must be a 12-digit number"
  }
}

variable "log_retention_days" {
  description = "Number of days to retain CloudTrail logs in S3"
  type        = number
  default     = 30

  validation {
    condition     = var.log_retention_days >= 1 && var.log_retention_days <= 3650
    error_message = "Log retention must be between 1 and 3650 days"
  }
}
