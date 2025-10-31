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

# Tags
variable "tags" {
  type = map(string)
  default = {
    ManagedBy = "Terraform"
  }
}
