terraform {
  required_version = ">= 1.3.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = var.purge_on_destroy
      recover_soft_deleted_key_vaults = true
    }
  }
}

provider "azuread" {}

# Get current client configuration for default access
data "azurerm_client_config" "current" {}

# Get current user/service principal details
data "azuread_client_config" "current" {}

# Resource Group
resource "azurerm_resource_group" "kv" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Use existing resource group if not creating new one
data "azurerm_resource_group" "existing" {
  count = var.create_resource_group ? 0 : 1
  name  = var.resource_group_name
}

locals {
  resource_group_name = var.create_resource_group ? azurerm_resource_group.kv[0].name : data.azurerm_resource_group.existing[0].name
  resource_group_id   = var.create_resource_group ? azurerm_resource_group.kv[0].id : data.azurerm_resource_group.existing[0].id
}

# Log Analytics Workspace for diagnostics
resource "azurerm_log_analytics_workspace" "kv" {
  count               = var.enable_diagnostics ? 1 : 0
  name                = "${var.key_vault_name}-logs"
  location            = var.location
  resource_group_name = local.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = var.tags
}

# Key Vault with RBAC enabled
resource "azurerm_key_vault" "main" {
  name                = var.key_vault_name
  location            = var.location
  resource_group_name = local.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = var.sku_name

  # RBAC Authorization - This is the key setting for RBAC instead of access policies
  enable_rbac_authorization = true

  # Security features
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_template_deployment = var.enabled_for_template_deployment
  purge_protection_enabled        = var.purge_protection_enabled
  soft_delete_retention_days      = var.soft_delete_retention_days

  # Public network access
  public_network_access_enabled = var.public_network_access_enabled

  # Network ACLs
  network_acls {
    bypass                     = var.network_acls_bypass
    default_action             = var.network_acls_default_action
    ip_rules                   = var.allowed_ip_addresses
    virtual_network_subnet_ids = var.allowed_subnet_ids
  }

  tags = var.tags
}

# Diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "kv" {
  count                      = var.enable_diagnostics ? 1 : 0
  name                       = "${var.key_vault_name}-diagnostics"
  target_resource_id         = azurerm_key_vault.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.kv[0].id

  # Metrics
  dynamic "metric" {
    for_each = var.diagnostic_metrics
    content {
      category = metric.value
      enabled  = true
    }
  }

  # Logs
  dynamic "enabled_log" {
    for_each = var.diagnostic_logs
    content {
      category = enabled_log.value
    }
  }
}

# RBAC Role Assignments
# Administrator access for the deploying user/service principal
resource "azurerm_role_assignment" "deployer_admin" {
  count                = var.assign_deployer_admin ? 1 : 0
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id

  depends_on = [azurerm_key_vault.main]
}

# Additional role assignments for secrets officers
resource "azurerm_role_assignment" "secrets_officers" {
  for_each             = toset(var.secrets_officer_principal_ids)
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = each.value

  depends_on = [azurerm_key_vault.main]
}

# Additional role assignments for secrets users (read-only)
resource "azurerm_role_assignment" "secrets_users" {
  for_each             = toset(var.secrets_user_principal_ids)
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value

  depends_on = [azurerm_key_vault.main]
}

# Additional role assignments for crypto officers
resource "azurerm_role_assignment" "crypto_officers" {
  for_each             = toset(var.crypto_officer_principal_ids)
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Crypto Officer"
  principal_id         = each.value

  depends_on = [azurerm_key_vault.main]
}

# Additional role assignments for crypto users (read-only)
resource "azurerm_role_assignment" "crypto_users" {
  for_each             = toset(var.crypto_user_principal_ids)
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Crypto User"
  principal_id         = each.value

  depends_on = [azurerm_key_vault.main]
}

# Additional role assignments for certificate officers
resource "azurerm_role_assignment" "certificate_officers" {
  for_each             = toset(var.certificate_officer_principal_ids)
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Certificates Officer"
  principal_id         = each.value

  depends_on = [azurerm_key_vault.main]
}

# Additional role assignments for certificate users (read-only)
resource "azurerm_role_assignment" "certificate_users" {
  for_each             = toset(var.certificate_user_principal_ids)
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Certificates User"
  principal_id         = each.value

  depends_on = [azurerm_key_vault.main]
}

# Reader access for monitoring and auditing
resource "azurerm_role_assignment" "readers" {
  for_each             = toset(var.reader_principal_ids)
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Reader"
  principal_id         = each.value

  depends_on = [azurerm_key_vault.main]
}

# Custom role assignments
resource "azurerm_role_assignment" "custom" {
  for_each             = var.custom_role_assignments
  scope                = azurerm_key_vault.main.id
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id

  depends_on = [azurerm_key_vault.main]
}

# Private Endpoint (optional)
resource "azurerm_private_endpoint" "kv" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "${var.key_vault_name}-pe"
  location            = var.location
  resource_group_name = local.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.key_vault_name}-psc"
    private_connection_resource_id = azurerm_key_vault.main.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id != null ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }

  tags = var.tags
}
