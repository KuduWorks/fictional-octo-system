variable "gcp_region" {
  description = "GCP region for resources"
  type        = string
  default     = "europe-north1"
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "billing_account_id" {
  description = "GCP billing account ID for budget management"
  type        = string
  default     = ""
}

variable "monthly_budget_amount" {
  description = "Monthly budget amount in EUR"
  type        = number
  default     = 100
}

variable "budget_alert_emails" {
  description = "List of email addresses for budget alerts"
  type        = list(string)
  default     = []
}

variable "dev_project_id" {
  description = "Immutable GCP project ID for development environment (ensures stability if project display name changes)"
  type        = string
  default     = ""

  validation {
    condition     = var.dev_project_id == "" || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.dev_project_id))
    error_message = "The dev_project_id must be a valid GCP project ID (6-30 characters, lowercase letters, digits, hyphens)."
  }
}

variable "prod_project_id" {
  description = "Immutable GCP project ID for production environment (ensures stability if project display name changes)"
  type        = string
  default     = ""

  validation {
    condition     = var.prod_project_id == "" || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.prod_project_id))
    error_message = "The prod_project_id must be a valid GCP project ID (6-30 characters, lowercase letters, digits, hyphens)."
  }
}

variable "dev_project_budget_amount" {
  description = "Monthly budget amount in EUR for development project"
  type        = number
  default     = 50

  validation {
    condition     = var.dev_project_budget_amount >= 0
    error_message = "The dev_project_budget_amount must be non-negative."
  }
}

variable "prod_project_budget_amount" {
  description = "Monthly budget amount in EUR for production project"
  type        = number
  default     = 50

  validation {
    condition     = var.prod_project_budget_amount >= 0
    error_message = "The prod_project_budget_amount must be non-negative."
  }
}

check "project_budget_amounts_within_monthly_limit" {
  assert {
    condition = (
      (var.dev_project_id == "" ? 0 : var.dev_project_budget_amount) +
      (var.prod_project_id == "" ? 0 : var.prod_project_budget_amount)
    ) <= var.monthly_budget_amount
    error_message = "The sum of dev_project_budget_amount and prod_project_budget_amount (for enabled projects) must not exceed monthly_budget_amount."
  }
}