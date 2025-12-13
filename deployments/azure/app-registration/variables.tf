variable "app_display_name" {
  description = "Display name for the Azure AD application"
  type        = string
}

variable "sign_in_audience" {
  description = "Who can sign in to this application (AzureADMyOrg, AzureADMultipleOrgs, AzureADandPersonalMicrosoftAccount, PersonalMicrosoftAccount)"
  type        = string
  default     = "AzureADMyOrg"
}

variable "redirect_uris" {
  description = "List of redirect URIs for web applications"
  type        = list(string)
  default     = null
}

variable "enable_implicit_flow" {
  description = "Enable implicit grant flow for access tokens and ID tokens"
  type        = bool
  default     = false
}

# Permissions Variables
variable "graph_permissions" {
  description = "List of Microsoft Graph API permissions. Each permission should have 'id', 'type' (Scope or Role), and 'value' (permission name)"
  type = list(object({
    id    = string
    type  = string # "Scope" for delegated, "Role" for application
    value = string
  }))
  default = []
}

variable "arm_permissions" {
  description = "List of Azure Resource Manager API permissions"
  type = list(object({
    id    = string
    type  = string
    value = string
  }))
  default = []
}

variable "custom_api_permissions" {
  description = "Permissions for custom APIs"
  type = list(object({
    resource_app_id = string
    permissions = list(object({
      id   = string
      type = string
    }))
  }))
  default = []
}

# API Exposure Variables
variable "expose_api" {
  description = "Whether to expose this application as an API"
  type        = bool
  default     = false
}

variable "api_scopes" {
  description = "OAuth2 permission scopes to expose"
  type = list(object({
    id                         = string
    value                      = string
    admin_consent_display_name = string
    admin_consent_description  = string
    user_consent_display_name  = string
    user_consent_description   = string
  }))
  default = []
}

variable "app_roles" {
  description = "Application roles to define"
  type = list(object({
    id                   = string
    value                = string
    display_name         = string
    description          = string
    allowed_member_types = list(string) # ["User"], ["Application"], or both
  }))
  default = []
}

# Service Principal Variables
variable "app_role_assignment_required" {
  description = "Whether users must be assigned to the app via a role before they can sign in"
  type        = bool
  default     = false
}

variable "notification_emails" {
  description = "Email addresses to receive notifications about the service principal"
  type        = list(string)
  default     = []
}

variable "enable_enterprise_features" {
  description = "Enable enterprise features for the service principal"
  type        = bool
  default     = false
}

variable "enable_gallery_features" {
  description = "Enable gallery features for the service principal"
  type        = bool
  default     = false
}

# Secret Rotation Variables
variable "secret_rotation_days" {
  description = "Number of days before rotating the client secret"
  type        = number
  default     = 90

  validation {
    condition     = var.secret_rotation_days >= 30 && var.secret_rotation_days <= 730
    error_message = "Secret rotation must be between 30 and 730 days (Microsoft recommendation: 90-180 days)."
  }
}

# Certificate Authentication Variables
variable "use_certificate_auth" {
  description = "Use certificate-based authentication instead of client secret"
  type        = bool
  default     = false
}

variable "certificate_value" {
  description = "The certificate value (PEM format, without private key)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "certificate_end_date" {
  description = "The end date of the certificate in RFC3339 format"
  type        = string
  default     = ""
}

# Federated Identity Credentials (OIDC)
variable "enable_github_oidc" {
  description = "Enable federated identity credential for GitHub Actions"
  type        = bool
  default     = false
}

variable "github_org" {
  description = "GitHub organization name"
  type        = string
  default     = ""
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = ""
}

variable "github_branch" {
  description = "GitHub branch name for OIDC"
  type        = string
  default     = "main"
}

variable "enable_kubernetes_oidc" {
  description = "Enable federated identity credential for Kubernetes workload"
  type        = bool
  default     = false
}

variable "kubernetes_issuer_url" {
  description = "OIDC issuer URL for the Kubernetes cluster"
  type        = string
  default     = ""
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace for the service account"
  type        = string
  default     = ""
}

variable "kubernetes_service_account" {
  description = "Kubernetes service account name"
  type        = string
  default     = ""
}

# Admin Consent Variables
variable "grant_admin_consent" {
  description = "Automatically grant admin consent for API permissions (requires admin privileges)"
  type        = bool
  default     = false
}

# Key Vault Integration
variable "store_in_key_vault" {
  description = "Store client ID and secret in Azure Key Vault"
  type        = bool
  default     = false
}

variable "key_vault_id" {
  description = "Azure Key Vault ID to store secrets"
  type        = string
  default     = ""
}

# Owner Management Variables
variable "app_owners" {
  description = <<-EOT
    List of Azure AD user or service principal object IDs to be assigned as owners.
    STRICT REQUIREMENTS:
    - Minimum 2 owners required (zero-trust principle)
    - At least 1 MUST be a human user (not service principal)
    - Maximum 1 placeholder service principal allowed
    - All human owners must have ENABLED accounts
    - Placeholder requires 50+ character justification via placeholder_owner_justification
    
    Example: ["user-object-id-1", "user-object-id-2"]
    With placeholder: ["user-object-id", "placeholder-sp-object-id"]
  EOT
  type        = list(string)
  
  validation {
    condition     = length(var.app_owners) >= 2
    error_message = "At least 2 owners are required. Current: ${length(var.app_owners)}. This enforces accountability and prevents single-owner risk."
  }
  
  validation {
    condition     = length(var.app_owners) <= 10
    error_message = "Maximum 10 owners allowed. Current: ${length(var.app_owners)}. Large owner lists dilute accountability."
  }
}

variable "placeholder_owner_justification" {
  description = <<-EOT
    Required if using a placeholder service principal as owner (minimum 50 characters).
    Must explain:
    - Why 2 human owners are not available
    - Timeline for replacing placeholder with human owner
    - Business context requiring application creation before owners identified
    
    Placeholder service principals are reviewed quarterly (Q2/Q4 first Monday).
    Placeholders existing >6 months will be escalated to leadership.
    
    Leave empty ("") if not using any placeholder service principals.
  EOT
  type        = string
  default     = ""
  sensitive   = false  # Justifications are audit trail, not sensitive
  
  validation {
    condition     = var.placeholder_owner_justification == "" || length(var.placeholder_owner_justification) >= 50
    error_message = "If provided, placeholder justification must be at least 50 characters. Current: ${length(var.placeholder_owner_justification)}. This ensures substantive documentation for quarterly audits."
  }
  
  validation {
    condition     = var.placeholder_owner_justification == "" || length(var.placeholder_owner_justification) <= 2000
    error_message = "Placeholder justification must be at most 2000 characters to fit in Azure AD notes field."
  }
  
  validation {
    condition     = var.placeholder_owner_justification == "" || !can(regex("(?i)(test|temp|temporary|todo|tbd|n/a|none)\\s*$", var.placeholder_owner_justification))
    error_message = "Placeholder justification appears to be placeholder text (test/temp/todo/tbd/n/a/none). Provide substantive business justification."
  }
}

variable "permission_justifications" {
  description = <<-EOT
    Map of HIGH-RISK permission values to their justifications (minimum 100 characters each).
    Required for permissions ending in ".All" (e.g., Directory.ReadWrite.All).
    
    Example:
    {
      "Directory.ReadWrite.All" = "Application manages user provisioning automation across 50+ departments. Requires full directory write access to create/update user accounts, assign licenses, manage group memberships. Alternative scoped permissions insufficient for cross-departmental automation. Approved by Security Team ticket #SEC-12345 on 2024-03-15."
      "Application.ReadWrite.All" = "CI/CD pipeline for managing app registrations in dev/staging/prod environments..."
    }
    
    Justifications must:
    - Be at least 100 characters (substantive explanation)
    - Not contain HTML/script characters (<, >, ", ', &)
    - Not use placeholder text (test/temp/todo/tbd/n/a)
    - Include business context and approval information
  EOT
  type        = map(string)
  default     = {}
  sensitive   = false  # Justifications are audit trail, not sensitive
  
  validation {
    condition = alltrue([
      for perm, just in var.permission_justifications : length(just) >= 100
    ])
    error_message = "All HIGH-RISK permission justifications must be at least 100 characters. This ensures comprehensive documentation of elevated privilege usage."
  }
  
  validation {
    condition = alltrue([
      for perm, just in var.permission_justifications : length(just) <= 5000
    ])
    error_message = "Permission justifications must be at most 5000 characters for readability and storage efficiency."
  }
  
  validation {
    condition = alltrue([
      for perm, just in var.permission_justifications : can(regex("^[^<>\"'&]*$", just))
    ])
    error_message = "Permission justifications must not contain HTML/script special characters (<, >, \", ', &) to prevent injection attacks in notifications/reports."
  }
  
  validation {
    condition = alltrue([
      for perm, just in var.permission_justifications : !can(regex("(?i)(test|temp|temporary|todo|tbd|n/a|none)\\s*$", just))
    ])
    error_message = "Permission justifications appear to contain placeholder text (test/temp/todo/tbd/n/a/none). Provide substantive business justification for each HIGH-RISK permission."
  }
}

variable "manual_override_justification" {
  description = <<-EOT
    Optional 50+ character justification for manually overriding validation failures.
    Use ONLY in exceptional circumstances when:
    - Validation scripts produce false positives
    - Emergency business needs require immediate deployment
    - Technical limitations prevent automated validation
    
    Manual overrides are logged in audit trail and reviewed quarterly.
    Frequent overrides may trigger security review.
    
    Leave empty ("") for normal PR approval flow.
  EOT
  type        = string
  default     = ""
  sensitive   = false  # Justifications are audit trail, not sensitive
  
  validation {
    condition     = var.manual_override_justification == "" || length(var.manual_override_justification) >= 50
    error_message = "If provided, manual override justification must be at least 50 characters. Current: ${length(var.manual_override_justification)}. This ensures substantive documentation for audit compliance."
  }
  
  validation {
    condition     = var.manual_override_justification == "" || length(var.manual_override_justification) <= 2000
    error_message = "Manual override justification must be at most 2000 characters."
  }
}

# Tags
variable "tags" {
  type = map(string)
  default = {
    ManagedBy = "Terraform"
  }
}
