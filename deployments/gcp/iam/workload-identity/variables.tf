variable "gcp_region" {
  description = "GCP region for resources"
  type        = string
  default     = "europe-north1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition = contains(["dev", "staging", "prod", "test"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, test."
  }
}

variable "workload_identity_pool_name" {
  description = "Workload Identity Pool name (must exist - created by bootstrap)"
  type        = string
  default     = "github-actions-pool"
}

variable "github_repositories" {
  description = "Map of GitHub repositories and their configurations"
  type = map(object({
    org           = string
    repo          = string
    display_name  = string
    branches      = list(string)  # Empty list allows all branches
    roles         = list(string)  # IAM roles to grant
    custom_roles  = list(string)  # Custom IAM roles to grant
  }))
  
  default = {
    "main" = {
      org          = "KuduWorks"
      repo         = "fictional-octo-system"
      display_name = "Fictional Octo System"
      branches     = ["main", "develop"]
      roles = [
        "roles/storage.objectAdmin",
        "roles/compute.viewer",
        "roles/iam.serviceAccountUser"
      ]
      custom_roles = []
    }
  }
  
  validation {
    condition = alltrue([
      for k, v in var.github_repositories :
      can(regex("^[a-zA-Z0-9-]+$", v.org)) &&
      can(regex("^[a-zA-Z0-9-_.]+$", v.repo))
    ])
    error_message = "GitHub org and repo names must contain only valid characters."
  }
}

variable "custom_roles" {
  description = "Custom IAM roles to create"
  type = map(object({
    title       = string
    description = string
    permissions = list(string)
    stage       = string
  }))
  
  default = {}
  
  validation {
    condition = alltrue([
      for k, v in var.custom_roles :
      contains(["ALPHA", "BETA", "GA", "DEPRECATED"], v.stage)
    ])
    error_message = "Custom role stage must be one of: ALPHA, BETA, GA, DEPRECATED."
  }
}

# Terraform State Access
variable "enable_terraform_state_access" {
  description = "Grant service accounts access to Terraform state bucket"
  type        = bool
  default     = true
}

variable "terraform_state_bucket" {
  description = "Terraform state bucket name (if enable_terraform_state_access = true)"
  type        = string
  default     = ""
}

# Service Account Keys (not recommended)
variable "create_service_account_keys" {
  description = "Create service account keys (not recommended - use Workload Identity Federation)"
  type        = bool
  default     = false
}

variable "store_keys_in_secret_manager" {
  description = "Store service account keys in Secret Manager (only if create_service_account_keys = true)"
  type        = bool
  default     = false
}

variable "project_id" {
  description = "The GCP project ID where resources will be created"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_id))
    error_message = "Project ID must contain only lowercase letters, numbers, and hyphens."
  }
}

# Labels
variable "labels" {
  description = "Additional labels to apply to resources"
  type        = map(string)
  default     = {}
}