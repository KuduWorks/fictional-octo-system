variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-north-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "allowed_regions" {
  description = "List of allowed AWS regions for resource deployment"
  type        = list(string)
  default     = ["eu-north-1"] # Stockholm only
}
