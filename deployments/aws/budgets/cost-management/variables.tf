variable "aws_region" {
  description = "AWS region for budget resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "monthly_budget_limit" {
  description = "Monthly budget limit in USD"
  type        = string
  default     = "100"
}

variable "quarterly_budget_limit" {
  description = "Quarterly budget limit in USD"
  type        = string
  default     = "300"
}

variable "enable_quarterly_budget" {
  description = "Whether to create a quarterly budget"
  type        = bool
  default     = false
}

variable "enable_service_budgets" {
  description = "Whether to create service-specific budgets (EC2, S3)"
  type        = bool
  default     = false
}

variable "ec2_budget_limit" {
  description = "Monthly EC2 budget limit in USD"
  type        = string
  default     = "50"
}

variable "s3_budget_limit" {
  description = "Monthly S3 budget limit in USD"
  type        = string
  default     = "20"
}

variable "alert_email_addresses" {
  description = "List of email addresses to receive budget alerts"
  type        = list(string)
  default     = []
}

variable "alert_threshold_actual_80" {
  description = "Alert threshold for actual spend at 80%"
  type        = number
  default     = 80
}

variable "alert_threshold_actual_100" {
  description = "Alert threshold for actual spend at 100%"
  type        = number
  default     = 100
}

variable "alert_threshold_forecasted_100" {
  description = "Alert threshold for forecasted spend at 100%"
  type        = number
  default     = 100
}

variable "budget_start_date" {
  description = "Budget start date in YYYY-MM-DD format (defaults to current month)"
  type        = string
  default     = ""
}

variable "tag_based_budgets" {
  description = "Map of tag-based budgets with tag_key, tag_value, and limit"
  type = map(object({
    tag_key   = string
    tag_value = string
    limit     = string
  }))
  default = {}
}

variable "enable_cloudwatch_billing_alarm" {
  description = "Whether to create CloudWatch billing alarm"
  type        = bool
  default     = false
}

variable "cloudwatch_billing_threshold" {
  description = "CloudWatch billing alarm threshold in USD"
  type        = number
  default     = 100
}
