variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-north-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "config_recorder_name" {
  description = "Name of the AWS Config recorder"
  type        = string
  default     = "encryption-baseline-recorder"
}

variable "enable_scps" {
  description = "Whether to create Service Control Policies (requires AWS Organizations)"
  type        = bool
  default     = false
}

variable "remediation_enabled" {
  description = "Enable automatic remediation for non-compliant resources"
  type        = bool
  default     = false
}

variable "security_sns_topic_arn" {
  description = "ARN of the SNS topic for security compliance alerts (Config non-compliance notifications)"
  type        = string
  default     = ""
}
