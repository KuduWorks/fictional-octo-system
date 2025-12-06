variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "eu-north-1"
}

variable "environment" {
  description = "Environment name (e.g., prod, dev)"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/23"
}

variable "public_subnet_a_cidr" {
  description = "CIDR block for public subnet in AZ a"
  type        = string
  default     = "10.0.0.0/25"
}

variable "public_subnet_b_cidr" {
  description = "CIDR block for public subnet in AZ b"
  type        = string
  default     = "10.0.0.128/25"
}

variable "private_subnet_a_cidr" {
  description = "CIDR block for private subnet in AZ a"
  type        = string
  default     = "10.0.1.0/25"
}

variable "private_subnet_b_cidr" {
  description = "CIDR block for private subnet in AZ b"
  type        = string
  default     = "10.0.1.128/25"
}
