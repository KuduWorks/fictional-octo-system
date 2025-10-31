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

# Application Registration
resource "azuread_application" "app" {
  display_name     = var.app_display_name
  owners           = [data.azuread_client_config.current.object_id]
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
}

# Service Principal for the application
resource "azuread_service_principal" "app_sp" {
  client_id                    = azuread_application.app.client_id
  app_role_assignment_required = var.app_role_assignment_required
  owners                       = [data.azuread_client_config.current.object_id]

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
