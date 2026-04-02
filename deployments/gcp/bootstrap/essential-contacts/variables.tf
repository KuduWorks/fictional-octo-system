variable "organization_id" {
  description = "GCP Organization ID (numeric). Example: 123456789012"
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.organization_id))
    error_message = "Organization ID must be numeric only."
  }
}

variable "security_contact_email" {
  description = <<-EOT
    Email address for security notifications (SECURITY, TECHNICAL categories).
    Receives alerts about security incidents, technical issues, and critical updates.
    
    Note: Email format validation will be added in future refinement.
  EOT
  type        = string
}

variable "billing_contact_email" {
  description = <<-EOT
    Email address for billing notifications (BILLING category).
    Receives alerts about billing anomalies, budget alerts, and payment issues.
    
    Note: Email format validation will be added in future refinement.
  EOT
  type        = string
}

variable "monitoring_contact_email" {
  description = <<-EOT
    Email address for monitoring notifications (TECHNICAL, SUSPENSION categories).
    Receives alerts about service suspensions, technical issues, and operational concerns.
    
    Note: Email format validation will be added in future refinement.
  EOT
  type        = string
}

variable "project_id" {
  description = "GCP Project ID where Essential Contacts API will be enabled. Usually your bootstrap/dev project."
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

  validation {
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]$", var.gcp_region))
    error_message = "Region must be a valid GCP region format (e.g., europe-north1, us-central1)."
  }
}

variable "environment" {
  description = "Environment name for labeling resources"
  type        = string
  default     = "bootstrap"

  validation {
    condition     = contains(["bootstrap", "dev", "prod", "staging"], var.environment)
    error_message = "Environment must be one of: bootstrap, dev, prod, staging."
  }
}

variable "language_code" {
  description = "Language code for notification emails (ISO 639-1 format)"
  type        = string
  default     = "en"

  validation {
    condition     = can(regex("^[a-z]{2}$", var.language_code))
    error_message = "Language code must be a valid ISO 639-1 two-letter code (e.g., en, fi, sv)."
  }
}
