variable "environment" {
  description = "Environment name (must match allowed values in approved-tags.yaml: dev, staging, production)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production. See approved-tags.yaml for allowed values."
  }
}

variable "team" {
  description = "Team ID responsible for resources (must exist in approved-tags.yaml)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.team))
    error_message = "Team must be lowercase alphanumeric with hyphens only (e.g., platform-engineering)."
  }
}

variable "costcenter" {
  description = "Cost center code for billing (must match allowed values in approved-tags.yaml)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.costcenter))
    error_message = "Cost center must be lowercase alphanumeric with hyphens (e.g., eng-0001)."
  }
}

variable "repository_name" {
  description = "Name of the repository managing these resources (for traceability)"
  type        = string
  default     = "fictional-octo-system"
}

variable "include_common_tags" {
  description = "Whether to include common tags (managed_by, repository) in baseline"
  type        = bool
  default     = true
}
