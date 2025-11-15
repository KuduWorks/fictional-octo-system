variable "gcp_region" {
  description = "The GCP region to deploy resources in"
  type        = string
  default     = "europe-north1"
  
  validation {
    condition = contains([
      "us-central1", "us-east1", "us-east4", "us-west1", "us-west2", "us-west3", "us-west4",
      "europe-north1", "europe-west1", "europe-west2", "europe-west3", "europe-west4", "europe-west6"
    ], var.gcp_region)
    error_message = "GCP region must be a valid GCP region."
  }
}

variable "gcs_location" {
  description = "GCS bucket location (region or multi-region)"
  type        = string
  default     = "europe-north1"
  
  validation {
    condition = contains([
      "europe-north1",  # Finland (single region)
      "europe-west1",   # Belgium (single region)
      "EU",             # European Union (multi-region)
      "europe-west4",   # Netherlands (single region)
      "europe-west3"    # Frankfurt (single region)
    ], var.gcs_location)
    error_message = "GCS location must be a valid European location for compliance."
  }
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

variable "state_bucket_name" {
  description = "Name of the GCS bucket for Terraform state (leave empty for auto-generated name)"
  type        = string
  default     = ""
  
  validation {
    condition = var.state_bucket_name == "" || can(regex("^[a-z0-9][a-z0-9-_]{1,61}[a-z0-9]$", var.state_bucket_name))
    error_message = "Bucket name must be 3-63 characters, lowercase letters, numbers, hyphens, and underscores only."
  }
}

variable "state_version_retention_days" {
  description = "Number of days to retain old state versions"
  type        = number
  default     = 7
  
  validation {
    condition = var.state_version_retention_days >= 1 && var.state_version_retention_days <= 365
    error_message = "Retention days must be between 1 and 365."
  }
}

variable "state_version_retention_count" {
  description = "Number of newer versions to keep before deleting old versions"
  type        = number
  default     = 5
  
  validation {
    condition = var.state_version_retention_count >= 1 && var.state_version_retention_count <= 100
    error_message = "Retention count must be between 1 and 100."
  }
}

variable "kms_key_name" {
  description = "KMS key name for bucket encryption (leave empty for Google-managed encryption)"
  type        = string
  default     = ""
}

variable "enable_audit_logging" {
  description = "Enable audit logging for the state bucket"
  type        = bool
  default     = false
}

# GitHub Actions Configuration
variable "github_org" {
  description = "GitHub organization name"
  type        = string
  default     = "KuduWorks"
  
  validation {
    condition = can(regex("^[a-zA-Z0-9-]+$", var.github_org))
    error_message = "GitHub organization must contain only alphanumeric characters and hyphens."
  }
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "fictional-octo-system"
  
  validation {
    condition = can(regex("^[a-zA-Z0-9-_.]+$", var.github_repo))
    error_message = "GitHub repository must contain only alphanumeric characters, hyphens, underscores, and dots."
  }
}

variable "github_actions_sa_name" {
  description = "Service account name for GitHub Actions"
  type        = string
  default     = "github-actions-terraform"
  
  validation {
    condition = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.github_actions_sa_name))
    error_message = "Service account name must be 6-30 characters, start with lowercase letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "workload_identity_pool_name" {
  description = "Workload Identity Pool name (organization-wide)"
  type        = string
  default     = "github-actions-pool"
  
  validation {
    condition = can(regex("^[a-z][a-z0-9-]{3,30}[a-z0-9]$", var.workload_identity_pool_name))
    error_message = "Pool name must be 4-32 characters, start with lowercase letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

# Deployment Permissions
variable "enable_deployment_roles" {
  description = "Grant additional IAM roles for deployment (use with caution)"
  type        = bool
  default     = false
}

variable "deployment_roles" {
  description = "List of additional IAM roles to grant for deployment"
  type        = list(string)
  default = [
    "roles/compute.instanceAdmin.v1",
    "roles/iam.serviceAccountUser",
    "roles/storage.admin",
    "roles/cloudsql.admin"
  ]
  
  validation {
    condition = alltrue([
      for role in var.deployment_roles : can(regex("^roles/[a-zA-Z0-9.]+$", role))
    ])
    error_message = "All roles must start with 'roles/' and contain valid characters."
  }
}

# Tags and Labels
variable "labels" {
  description = "Additional labels to apply to resources"
  type        = map(string)
  default     = {}
  
  validation {
    condition = alltrue([
      for k, v in var.labels : can(regex("^[a-z][a-z0-9_-]{0,62}$", k)) && can(regex("^[a-z0-9_-]{0,63}$", v))
    ])
    error_message = "Label keys and values must be lowercase, contain only letters, numbers, underscores, and hyphens, and be 1-63 characters long."
  }
}

variable "project_id" {
  description = "The GCP project ID where resources will be created"
  type        = string
  default     = "kudu-star-dev-01"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_id))
    error_message = "Project ID must contain only lowercase letters, numbers, and hyphens."
  }
}