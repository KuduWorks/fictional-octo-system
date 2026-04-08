variable "project_id" {
  description = "GCP project ID for Secret Manager resources"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be a valid GCP project ID: 6-30 characters, start with a lowercase letter, only lowercase letters, digits, and hyphens, and not end with a hyphen."
  }
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "europe-north1"

  validation {
    condition     = can(regex("^[a-z]+-[a-z0-9]+[0-9]$", var.region))
    error_message = "The region variable must be a valid GCP region name, e.g., europe-north1, us-central1, asia-southeast1."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}