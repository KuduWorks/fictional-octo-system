variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-north-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "github_org" {
  description = "GitHub organization or username"
  type        = string
}

variable "github_repositories" {
  description = "List of GitHub repositories that can use these IAM roles (without org prefix)"
  type        = list(string)
}

variable "create_readonly_role" {
  description = "Whether to create a read-only role"
  type        = bool
  default     = true
}

variable "create_deploy_role" {
  description = "Whether to create a deployment role"
  type        = bool
  default     = true
}

variable "create_admin_role" {
  description = "Whether to create an admin role (restricted to main branch)"
  type        = bool
  default     = false
}

variable "readonly_role_name" {
  description = "Name for the read-only IAM role"
  type        = string
  default     = "github-actions-readonly"
}

variable "deploy_role_name" {
  description = "Name for the deployment IAM role"
  type        = string
  default     = "github-actions-deploy"
}

variable "admin_role_name" {
  description = "Name for the admin IAM role"
  type        = string
  default     = "github-actions-admin"
}
