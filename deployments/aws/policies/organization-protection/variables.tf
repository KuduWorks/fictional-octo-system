variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "eu-north-1"
}

variable "environment" {
  description = "Environment name (e.g., prod, dev, staging)"
  type        = string
  default     = "prod"
}

variable "management_account_id" {
  description = "AWS Management Account ID that should be exempted from organization modification restrictions"
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.management_account_id))
    error_message = "Management account ID must be a 12-digit number"
  }
}
