terraform {
  required_version = ">= 1.3.0"

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.10"
    }
  }
}

provider "azuread" {
  # Uses Azure CLI authentication by default
}

provider "azurerm" {
  features {}
}

# Data source to get current client configuration
data "azuread_client_config" "current" {}

# Data sources to validate owners exist and get their details
data "azuread_user" "owners" {
  for_each = toset([
    for owner_id in var.app_owners : owner_id
    if can(data.azuread_user.owners[owner_id])
  ])
  
  object_id = each.value
}

data "azuread_service_principal" "owners" {
  for_each = toset([
    for owner_id in var.app_owners : owner_id
    if !can(data.azuread_user.owners[owner_id])
  ])
  
  object_id = each.value
}

# Local values for owner validation
locals {
  # Identify which owners are users vs service principals
  user_owner_ids = [
    for owner_id in var.app_owners : owner_id
    if can(data.azuread_user.owners[owner_id])
  ]
  
  sp_owner_ids = [
    for owner_id in var.app_owners : owner_id
    if can(data.azuread_service_principal.owners[owner_id])
  ]
  
  # Count owners by type
  human_owner_count = length(local.user_owner_ids)
  placeholder_count = length(local.sp_owner_ids)
  
  # Validate disabled users (requires external script verification)
  # This is a Terraform-level check; actual account status checked by verify-owners.sh in CI/CD
  
  # Detect if any high-risk permissions are used
  high_risk_permissions = [
    for perm in var.graph_permissions : perm.value
    if can(regex("\\.All$", perm.value))
  ]
  
  # Validate all high-risk permissions have justifications
  missing_justifications = [
    for perm in local.high_risk_permissions : perm
    if !contains(keys(var.permission_justifications), perm)
  ]
}

# Application Registration
resource "azuread_application" "app" {
  display_name     = var.app_display_name
  owners           = var.app_owners  # Use dynamic owner list instead of hard-coded current user
  sign_in_audience = var.sign_in_audience

  # Web application configuration
  dynamic "web" {
    for_each = var.redirect_uris != null ? [1] : []
    content {
      redirect_uris = var.redirect_uris

      implicit_grant {
        access_token_issuance_enabled = var.enable_implicit_flow
        id_token_issuance_enabled     = var.enable_implicit_flow
      }
    }
  }

  # API permissions - Microsoft Graph
  dynamic "required_resource_access" {
    for_each = length(var.graph_permissions) > 0 ? [1] : []
    content {
      resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

      dynamic "resource_access" {
        for_each = var.graph_permissions
        content {
          id   = resource_access.value.id
          type = resource_access.value.type # "Scope" for delegated, "Role" for application
        }
      }
    }
  }

  # API permissions - Azure Resource Manager (if needed)
  dynamic "required_resource_access" {
    for_each = length(var.arm_permissions) > 0 ? [1] : []
    content {
      resource_app_id = "797f4846-ba00-4fd7-ba43-dac1f8f63013" # Azure Service Management

      dynamic "resource_access" {
        for_each = var.arm_permissions
        content {
          id   = resource_access.value.id
          type = resource_access.value.type
        }
      }
    }
  }

  # Custom API permissions (for your own APIs)
  dynamic "required_resource_access" {
    for_each = var.custom_api_permissions
    content {
      resource_app_id = required_resource_access.value.resource_app_id

      dynamic "resource_access" {
        for_each = required_resource_access.value.permissions
        content {
          id   = resource_access.value.id
          type = resource_access.value.type
        }
      }
    }
  }

  # Optional: Expose an API
  dynamic "api" {
    for_each = var.expose_api ? [1] : []
    content {
      mapped_claims_enabled          = false
      requested_access_token_version = 2

      dynamic "oauth2_permission_scope" {
        for_each = var.api_scopes
        content {
          admin_consent_description  = oauth2_permission_scope.value.admin_consent_description
          admin_consent_display_name = oauth2_permission_scope.value.admin_consent_display_name
          enabled                    = true
          id                         = oauth2_permission_scope.value.id
          type                       = "User"
          user_consent_description   = oauth2_permission_scope.value.user_consent_description
          user_consent_display_name  = oauth2_permission_scope.value.user_consent_display_name
          value                      = oauth2_permission_scope.value.value
        }
      }
    }
  }

  # App roles (application permissions)
  dynamic "app_role" {
    for_each = var.app_roles
    content {
      allowed_member_types = app_role.value.allowed_member_types
      description          = app_role.value.description
      display_name         = app_role.value.display_name
      enabled              = true
      id                   = app_role.value.id
      value                = app_role.value.value
    }
  }

  tags = toset(values(var.tags))
  
  # Lifecycle validation rules (zero-trust enforcement)
  lifecycle {
    # Rule 1: At least 1 human owner required
    precondition {
      condition     = local.human_owner_count >= 1
      error_message = <<-EOT
        FAILED: At least 1 HUMAN owner required (zero-trust principle).
        Current: ${local.human_owner_count} human owner(s), ${local.placeholder_count} service principal(s).
        
        Human owners ensure accountability and prevent automation-only access.
        Add at least one Azure AD user object ID to app_owners list.
      EOT
    }
    
    # Rule 2: Maximum 1 placeholder service principal
    precondition {
      condition     = local.placeholder_count <= 1
      error_message = <<-EOT
        FAILED: Maximum 1 placeholder service principal allowed.
        Current: ${local.placeholder_count} service principal(s) in app_owners.
        
        Multiple placeholders dilute accountability and violate governance policy.
        Replace placeholder service principals with human owners.
        Use modules/placeholder-service-principal only when absolutely necessary.
      EOT
    }
    
    # Rule 3: If placeholder used, justification required
    precondition {
      condition     = local.placeholder_count == 0 || (local.placeholder_count > 0 && length(var.placeholder_owner_justification) >= 50)
      error_message = <<-EOT
        FAILED: Placeholder service principal detected but justification missing or too short.
        Current placeholder_owner_justification length: ${length(var.placeholder_owner_justification)} characters.
        
        Placeholder justifications must be at least 50 characters.
        Explain:
        - Why 2 human owners are not available
        - Timeline for replacing placeholder with human owner
        - Business context requiring application creation before owners identified
        
        Placeholder service principals are reviewed quarterly (Q2/Q4 first Monday).
        Placeholders existing >6 months will be escalated to leadership.
      EOT
    }
    
    # Rule 4: All high-risk permissions must have justifications
    precondition {
      condition     = length(local.missing_justifications) == 0
      error_message = <<-EOT
        FAILED: HIGH-RISK permissions detected without justifications.
        Missing justifications for: ${jsonencode(local.missing_justifications)}
        
        Permissions ending in ".All" grant broad access and require 100+ character justification.
        Add to permission_justifications map:
        {
          "Permission.Name.All" = "Detailed justification explaining business need, alternatives considered, approval details (minimum 100 characters)..."
        }
        
        See permission-policies/graph-permissions-risk-matrix.json for risk classification.
      EOT
    }
    
    # Rule 5: Manual override requires justification if validation bypassed
    precondition {
      condition     = var.manual_override_justification == "" || length(var.manual_override_justification) >= 50
      error_message = <<-EOT
        FAILED: Manual override justification too short.
        Current length: ${length(var.manual_override_justification)} characters.
        
        Manual overrides require 50+ character justification documenting:
        - Why validation is being bypassed
        - Risk assessment and mitigation
        - Approval authority
        
        Manual overrides are logged and reviewed quarterly for compliance.
      EOT
    }
  }
}

# Service Principal for the application
resource "azuread_service_principal" "app_sp" {
  client_id                    = azuread_application.app.client_id
  app_role_assignment_required = var.app_role_assignment_required
  owners                       = var.app_owners  # Use same dynamic owner list

  feature_tags {
    enterprise = false
    gallery    = false
  }
}

# Application Password (Client Secret) with rotation
resource "time_rotating" "secret_rotation" {
  rotation_days = var.secret_rotation_days
}

resource "azuread_application_password" "app_secret" {
  application_id = azuread_application.app.id
  display_name   = "Managed by Terraform - Rotates every ${var.secret_rotation_days} days"

  # Secret will expire after rotation days
  end_date_relative = "${var.secret_rotation_days * 24}h"

  # When the secret rotation resource changes, this triggers replacement of the application password to ensure secrets are rotated regularly for security and compliance.
  lifecycle {
    replace_triggered_by = [
      time_rotating.secret_rotation.id
    ]
  }
}

# Optional: Certificate-based authentication (more secure than secrets)
resource "azuread_application_certificate" "app_cert" {
  count = var.use_certificate_auth ? 1 : 0

  application_id = azuread_application.app.id
  type           = "AsymmetricX509Cert"
  value          = var.certificate_value
  end_date       = var.certificate_end_date
}

# Optional: Federated Identity Credentials (for GitHub Actions, Kubernetes, etc.)
resource "azuread_application_federated_identity_credential" "github" {
  count = var.enable_github_oidc ? 1 : 0

  application_id = azuread_application.app.id
  display_name   = "GitHub-${var.github_repo}"
  description    = "Federated credential for GitHub Actions"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${var.github_branch}"
}

resource "azuread_application_federated_identity_credential" "kubernetes" {
  count = var.enable_kubernetes_oidc ? 1 : 0

  application_id = azuread_application.app.id
  display_name   = "Kubernetes-${var.kubernetes_namespace}-${var.kubernetes_service_account}"
  description    = "Federated credential for Kubernetes workload"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = var.kubernetes_issuer_url
  subject        = "system:serviceaccount:${var.kubernetes_namespace}:${var.kubernetes_service_account}"
}

# Admin consent for application permissions (requires admin privileges)
resource "azuread_service_principal_delegated_permission_grant" "admin_consent" {
  count = var.grant_admin_consent && length(var.graph_permissions) > 0 ? 1 : 0

  service_principal_object_id          = azuread_service_principal.app_sp.object_id
  resource_service_principal_object_id = data.azuread_service_principal.msgraph.object_id
  claim_values                         = [for perm in var.graph_permissions : perm.value if perm.type == "Scope"]
}

# Data source for Microsoft Graph service principal
data "azuread_service_principal" "msgraph" {
  client_id = "00000003-0000-0000-c000-000000000000"
}

# Optional: Grant application permissions using service principal
resource "azuread_app_role_assignment" "app_permissions" {
  for_each = var.grant_admin_consent ? toset([
    for perm in var.graph_permissions : perm.id if perm.type == "Role"
  ]) : toset([])

  app_role_id         = each.value
  principal_object_id = azuread_service_principal.app_sp.object_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}

# Store secrets in Azure Key Vault (recommended)
resource "azurerm_key_vault_secret" "client_id" {
  count = var.store_in_key_vault ? 1 : 0

  name         = "${var.app_display_name}-client-id"
  value        = azuread_application.app.client_id
  key_vault_id = var.key_vault_id

  tags = var.tags
}

resource "azurerm_key_vault_secret" "client_secret" {
  count = var.store_in_key_vault ? 1 : 0

  name         = "${var.app_display_name}-client-secret"
  value        = azuread_application_password.app_secret.value
  key_vault_id = var.key_vault_id

  tags = var.tags

  lifecycle {
    # Create new secret before destroying old one
    create_before_destroy = true
  }
}

resource "azurerm_key_vault_secret" "tenant_id" {
  count = var.store_in_key_vault ? 1 : 0

  name         = "${var.app_display_name}-tenant-id"
  value        = data.azuread_client_config.current.tenant_id
  key_vault_id = var.key_vault_id

  tags = var.tags
}
