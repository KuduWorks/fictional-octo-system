# Variables for GitHub Actions OIDC Configuration

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "eu-north-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "github_org" {
  description = "GitHub organization or user name that owns the repositories"
  type        = string
}

variable "github_repositories" {
  description = "List of GitHub repository names (without org prefix) that can assume the IAM roles"
  type        = list(string)
  default     = ["fictional-octo-system"]
}

# Role Configuration
variable "create_readonly_role" {
  description = "Whether to create a read-only IAM role for GitHub Actions"
  type        = bool
  default     = true
}

variable "readonly_role_name" {
  description = "Name of the read-only IAM role"
  type        = string
  default     = "github-actions-readonly"
}

variable "create_deploy_role" {
  description = "Whether to create a deployment IAM role for GitHub Actions"
  type        = bool
  default     = true
}

variable "deploy_role_name" {
  description = "Name of the deployment IAM role"
  type        = string
  default     = "github-actions-deploy"
}

variable "create_admin_role" {
  description = "Whether to create an admin IAM role for GitHub Actions (use with caution - broad permissions)"
  type        = bool
  default     = false
}

variable "admin_role_name" {
  description = "Name of the admin IAM role"
  type        = string
  default     = "github-actions-admin"
}
