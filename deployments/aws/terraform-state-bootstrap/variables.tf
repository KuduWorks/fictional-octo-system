variable "aws_region" {
  description = "AWS region for state storage"
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state (leave empty for auto-generated name)"
  type        = string
  default     = ""
}

variable "lock_table_name" {
  description = "Name of the DynamoDB table for state locking"
  type        = string
  default     = "terraform-state-locks"
}

variable "state_version_retention_days" {
  description = "Number of days to retain old state versions"
  type        = number
  default     = 90
}

variable "enable_logging" {
  description = "Enable access logging for the state bucket"
  type        = bool
  default     = false
}

variable "create_access_policy" {
  description = "Create an IAM policy for state bucket access"
  type        = bool
  default     = true
}
