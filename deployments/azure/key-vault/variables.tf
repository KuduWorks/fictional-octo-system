variable "key_vault_name" {
  description = "Name of the Azure Key Vault. Must be globally unique (3-24 alphanumeric characters)."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{3,24}$", var.key_vault_name))
    error_message = "Key Vault name must be 3-24 characters long and contain only alphanumeric characters and hyphens."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group where Key Vault will be deployed."
  type        = string
}

variable "create_resource_group" {
  description = "Whether to create a new resource group. Set to false to use an existing one."
  type        = bool
  default     = false
}

variable "location" {
  description = "Azure region where resources will be deployed."
  type        = string
  default     = "swedencentral"
}

variable "sku_name" {
  description = "SKU for the Key Vault. Options: 'standard' or 'premium' (for HSM-backed keys)."
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "SKU must be either 'standard' or 'premium'."
  }
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default = {
    Environment = "production"
    ManagedBy   = "terraform"
    Purpose     = "key-vault"
  }
}

# RBAC is enabled by default - no access policies needed
# Access is managed through Azure RBAC role assignments

variable "assign_deployer_admin" {
  description = "Whether to assign Key Vault Administrator role to the current user/service principal."
  type        = bool
  default     = true
}

variable "secrets_officer_principal_ids" {
  description = "List of principal IDs to grant 'Key Vault Secrets Officer' role (full secrets management)."
  type        = list(string)
  default     = []
}

variable "secrets_user_principal_ids" {
  description = "List of principal IDs to grant 'Key Vault Secrets User' role (read-only secrets access)."
  type        = list(string)
  default     = []
}

variable "crypto_officer_principal_ids" {
  description = "List of principal IDs to grant 'Key Vault Crypto Officer' role (full key management)."
  type        = list(string)
  default     = []
}

variable "crypto_user_principal_ids" {
  description = "List of principal IDs to grant 'Key Vault Crypto User' role (cryptographic operations only)."
  type        = list(string)
  default     = []
}

variable "certificate_officer_principal_ids" {
  description = "List of principal IDs to grant 'Key Vault Certificates Officer' role (full certificate management)."
  type        = list(string)
  default     = []
}

variable "certificate_user_principal_ids" {
  description = "List of principal IDs to grant 'Key Vault Certificates User' role (read-only certificate access)."
  type        = list(string)
  default     = []
}

variable "reader_principal_ids" {
  description = "List of principal IDs to grant 'Key Vault Reader' role (read metadata only)."
  type        = list(string)
  default     = []
}

variable "custom_role_assignments" {
  description = "Map of custom role assignments. Key is a unique identifier, value is an object with role_definition_name and principal_id."
  type = map(object({
    role_definition_name = string
    principal_id         = string
  }))
  default = {}
}

# Security Settings

variable "purge_protection_enabled" {
  description = "Enable purge protection (prevents permanent deletion during soft-delete period). Recommended for production."
  type        = bool
  default     = true
}

variable "soft_delete_retention_days" {
  description = "Number of days to retain soft-deleted items (7-90 days)."
  type        = number
  default     = 7

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "Soft delete retention must be between 7 and 90 days."
  }
}

variable "purge_on_destroy" {
  description = "Whether to purge Key Vault on destroy (use with caution in production)."
  type        = bool
  default     = false
}

variable "enabled_for_disk_encryption" {
  description = "Enable Azure Disk Encryption to retrieve secrets from the vault."
  type        = bool
  default     = true
}

variable "enabled_for_deployment" {
  description = "Enable Azure Virtual Machines to retrieve certificates from the vault."
  type        = bool
  default     = true
}

variable "enabled_for_template_deployment" {
  description = "Enable Azure Resource Manager to retrieve secrets from the vault during deployments."
  type        = bool
  default     = true
}

# Network Settings

variable "public_network_access_enabled" {
  description = "Whether public network access is allowed. Set to false for private-only access."
  type        = bool
  default     = false
}

variable "network_acls_bypass" {
  description = "Which Azure services can bypass network ACLs. Options: 'AzureServices', 'None'."
  type        = string
  default     = "AzureServices"

  validation {
    condition     = contains(["AzureServices", "None"], var.network_acls_bypass)
    error_message = "Network ACLs bypass must be 'AzureServices' or 'None'."
  }
}

variable "network_acls_default_action" {
  description = "Default action for network ACLs. Options: 'Allow', 'Deny'."
  type        = string
  default     = "Deny"

  validation {
    condition     = contains(["Allow", "Deny"], var.network_acls_default_action)
    error_message = "Default action must be 'Allow' or 'Deny'."
  }
}

variable "allowed_ip_addresses" {
  description = "List of IP addresses or CIDR ranges allowed to access the Key Vault."
  type        = list(string)
  default     = []
}

variable "allowed_subnet_ids" {
  description = "List of Virtual Network subnet IDs allowed to access the Key Vault."
  type        = list(string)
  default     = []
}

# Private Endpoint

variable "enable_private_endpoint" {
  description = "Whether to create a private endpoint for the Key Vault."
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID where the private endpoint will be created."
  type        = string
  default     = null
}

variable "private_dns_zone_id" {
  description = "Private DNS Zone ID for Key Vault private endpoint DNS resolution."
  type        = string
  default     = null
}

# Monitoring and Diagnostics

variable "enable_diagnostics" {
  description = "Whether to enable diagnostic settings and create Log Analytics workspace."
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Number of days to retain logs in Log Analytics (30-730 days)."
  type        = number
  default     = 30

  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "Log retention must be between 30 and 730 days."
  }
}

variable "diagnostic_logs" {
  description = "List of log categories to enable for diagnostics."
  type        = list(string)
  default = [
    "AuditEvent",
    "AzurePolicyEvaluationDetails"
  ]
}

variable "diagnostic_metrics" {
  description = "List of metric categories to enable for diagnostics."
  type        = list(string)
  default = [
    "AllMetrics"
  ]
}
