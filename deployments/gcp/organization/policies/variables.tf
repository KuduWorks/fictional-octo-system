variable "organization_id" {
  description = "GCP Organization ID (numeric). Example: 123456789012"
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.organization_id))
    error_message = "Organization ID must be numeric only."
  }
}

variable "project_id" {
  description = "GCP Project ID for Terraform state and provider configuration"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "Project ID must be 6-30 characters, start with a letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "gcp_region" {
  description = "Default GCP region for resource provisioning"
  type        = string
  default     = "europe-north1"
}

variable "environment" {
  description = "Environment name for labeling resources"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["bootstrap", "dev", "prod", "production", "staging"], var.environment)
    error_message = "Environment must be one of: bootstrap, dev, prod, production, staging."
  }
}

# ==============================================================================
# POLICY CONTROL VARIABLES
# ==============================================================================

variable "dry_run" {
  description = <<-EOT
    Enable dry-run mode for all policies. When true, policy violations are logged 
    but NOT enforced. Use this to test policies before enforcement.
    
    Workflow:
      1. Deploy with dry_run = true
      2. Monitor Cloud Logging for violations
      3. Review and adjust exemptions
      4. Set dry_run = false to enforce
    
    Default: true (safe testing mode)
  EOT
  type        = bool
  default     = true
}

variable "enable_key_expiry_policy" {
  description = "Enable service account key expiry policy (90-day rotation)"
  type        = bool
  default     = true
}

variable "enable_key_creation_policy" {
  description = "Enable policy to disable user-managed service account key creation"
  type        = bool
  default     = true
}

variable "enable_key_upload_policy" {
  description = "Enable policy to disable service account key uploads"
  type        = bool
  default     = true
}

variable "enable_domain_restriction_policy" {
  description = "Enable domain restriction policy for IAM members"
  type        = bool
  default     = true
}

# ==============================================================================
# POLICY CONFIGURATION
# ==============================================================================

variable "key_expiry_hours" {
  description = "Maximum lifespan for service account keys in hours (default: 2160 hours = 90 days)"
  type        = number
  default     = 2160

  validation {
    condition     = var.key_expiry_hours > 0 && var.key_expiry_hours <= 8760
    error_message = "Key expiry must be between 1 and 8760 hours (1 year max)."
  }
}

variable "allowed_policy_member_domains" {
  description = <<-EOT
    List of allowed domains for IAM policy members.
    Include your Cloud Identity customer ID and organization domain.
    
    Example:
      ["C0xxxxxxx", "yourdomain.com"]
    
    Find Customer ID:
      gcloud organizations describe <ORG-ID> --format="value(owner.directoryCustomerId)"
  EOT
  type        = list(string)
  default     = []
}

# ==============================================================================
# EXEMPTION VARIABLES
# ==============================================================================

variable "exclude_folders" {
  description = <<-EOT
    List of folder IDs to exempt from organization policies.
    Use for folders requiring different policy configurations.
    
    Example (with inline exemption tracking):
      [
        "123456789012",  # PERMANENT: Legacy systems folder - Approved 2026-02-10
        "987654321098",  # EXPIRES: 2026-08-01 - Migration project - Review quarterly
      ]
    
    Find Folder ID:
      gcloud resource-manager folders list --organization=<ORG-ID>
  EOT
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for f in var.exclude_folders : can(regex("^[0-9]+$", f))])
    error_message = "Folder IDs must be numeric only."
  }
}

variable "exclude_projects" {
  description = <<-EOT
    List of project IDs to exempt from organization policies.
    Use for specific projects requiring policy exemptions.
    
    Example (with inline exemption tracking):
      [
        "legacy-app-project",     # PERMANENT: Legacy application - Requires user-managed keys
        "migration-project-2026", # EXPIRES: 2026-12-31 - Temporary exemption during migration
      ]
    
    Find Project ID:
      gcloud projects list --format="value(projectId)"
  EOT
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for p in var.exclude_projects : can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", p))])
    error_message = "Project IDs must be valid GCP project ID format."
  }
}
