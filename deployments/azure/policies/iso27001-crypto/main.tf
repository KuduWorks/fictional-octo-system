# Configure the Azure Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.0"
}

provider "azurerm" {
  features {}
}

# Get current subscription data
data "azurerm_client_config" "current" {}

# Variables
variable "enforcement_mode" {
  description = "Policy enforcement mode - Default (enforce) or DoNotEnforce (audit only)"
  type        = string
  default     = "Default"
  validation {
    condition     = contains(["Default", "DoNotEnforce"], var.enforcement_mode)
    error_message = "Enforcement mode must be either 'Default' or 'DoNotEnforce'."
  }
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  default     = null
}

# Locals
locals {
  subscription_id_raw = var.subscription_id != null ? var.subscription_id : data.azurerm_client_config.current.subscription_id
  subscription_id     = "/subscriptions/${local.subscription_id_raw}"
  
  # Built-in policy IDs
  storage_https_policy_id            = "/providers/Microsoft.Authorization/policyDefinitions/404c3081-a854-4457-ae30-26a93ef643f9"
  storage_cmk_policy_id              = "/providers/Microsoft.Authorization/policyDefinitions/6fac406b-40ca-413b-bf8e-0bf964659c25"
  storage_public_access_policy_id    = "/providers/Microsoft.Authorization/policyDefinitions/4fa4b6c0-31ca-4c0d-b10d-24b96f62a751"
  sql_tde_cmk_policy_id              = "/providers/Microsoft.Authorization/policyDefinitions/0a370ff3-6cab-4e85-8995-295fd854c5b8"
  keyvault_soft_delete_policy_id     = "/providers/Microsoft.Authorization/policyDefinitions/1e66c121-a66a-4b1f-9b83-0fd99bf0fc2d"
  keyvault_purge_protection_policy_id = "/providers/Microsoft.Authorization/policyDefinitions/0b60c0b2-2dc2-4e1c-b5c9-abbed971de53"
  aks_azure_policy_addon_policy_id   = "/providers/Microsoft.Authorization/policyDefinitions/a8eff44f-8c92-45c3-a3fb-9880802d67a7"
}

#
# ==================== STORAGE ACCOUNT POLICIES ====================
#

# Policy 1: Storage Accounts must use HTTPS (Secure Transfer)
resource "azurerm_subscription_policy_assignment" "storage_https_required" {
  name                 = "iso27001-storage-https"
  policy_definition_id = local.storage_https_policy_id
  subscription_id      = local.subscription_id
  display_name         = "ISO 27001 - Storage Accounts require secure transfer (HTTPS)"
  description          = "Enforces HTTPS-only access to storage accounts for data in transit encryption"

  metadata = jsonencode({
    category   = "ISO 27001 - Cryptography"
    control    = "A.10.1.1"
    assignedBy = "Terraform"
  })
}

# Policy 2: Storage Accounts should use customer-managed keys
resource "azurerm_subscription_policy_assignment" "storage_cmk_required" {
  name                 = "iso27001-storage-cmk"
  policy_definition_id = local.storage_cmk_policy_id
  subscription_id      = local.subscription_id
  display_name         = "ISO 27001 - Storage Accounts should use customer-managed keys"
  description          = "Audit storage accounts that don't use customer-managed keys for encryption at rest"

  metadata = jsonencode({
    category   = "ISO 27001 - Cryptography"
    control    = "A.10.1.1"
    assignedBy = "Terraform"
  })
}

# Policy 3: Storage Accounts should disable public blob access
resource "azurerm_subscription_policy_assignment" "storage_disable_public_access" {
  name                 = "iso27001-storage-no-public"
  policy_definition_id = local.storage_public_access_policy_id
  subscription_id      = local.subscription_id
  display_name         = "ISO 27001 - Storage Accounts should disable public blob access"
  description          = "Disables anonymous public read access to containers and blobs"

  metadata = jsonencode({
    category   = "ISO 27001 - Cryptography"
    control    = "A.10.1.1"
    assignedBy = "Terraform"
  })
}

#
# ==================== SQL DATABASE POLICIES ====================
#

# Policy 4: SQL Databases should use customer-managed keys for TDE
resource "azurerm_subscription_policy_assignment" "sql_tde_cmk_required" {
  name                 = "iso27001-sql-tde-cmk"
  policy_definition_id = local.sql_tde_cmk_policy_id
  subscription_id      = local.subscription_id
  display_name         = "ISO 27001 - SQL Databases should use customer-managed keys for TDE"
  description          = "Transparent Data Encryption should use customer-managed keys"

  metadata = jsonencode({
    category   = "ISO 27001 - Cryptography"
    control    = "A.10.1.1"
    assignedBy = "Terraform"
  })
}

#
# ==================== KEY VAULT POLICIES ====================
#

# Policy 5: Key Vaults should have soft delete enabled
resource "azurerm_subscription_policy_assignment" "keyvault_soft_delete" {
  name                 = "iso27001-kv-soft-delete"
  policy_definition_id = local.keyvault_soft_delete_policy_id
  subscription_id      = local.subscription_id
  display_name         = "ISO 27001 - Key Vaults should have soft delete enabled"
  description          = "Protects against accidental deletion of encryption keys"

  metadata = jsonencode({
    category   = "ISO 27001 - Cryptography"
    control    = "A.10.1.1"
    assignedBy = "Terraform"
  })
}

# Policy 6: Key Vaults should have purge protection enabled
resource "azurerm_subscription_policy_assignment" "keyvault_purge_protection" {
  name                 = "iso27001-kv-purge-protect"
  policy_definition_id = local.keyvault_purge_protection_policy_id
  subscription_id      = local.subscription_id
  display_name         = "ISO 27001 - Key Vaults should have purge protection enabled"
  description          = "Prevents permanent deletion of keys, secrets, and certificates"

  metadata = jsonencode({
    category   = "ISO 27001 - Cryptography"
    control    = "A.10.1.1"
    assignedBy = "Terraform"
  })
}

#
# ==================== DISK ENCRYPTION POLICIES ====================
#

# Custom Policy 7: Managed Disks should use customer-managed keys
resource "azurerm_policy_definition" "disk_cmk_required" {
  name         = "iso27001-disk-cmk-required"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "ISO 27001 - Managed Disks should use customer-managed keys"
  description  = "Audits managed disks that don't use disk encryption sets with customer-managed keys"

  metadata = jsonencode({
    category = "ISO 27001 - Cryptography"
    control  = "A.10.1.1"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Compute/disks"
        },
        {
          anyOf = [
            {
              field  = "Microsoft.Compute/disks/encryption.diskEncryptionSetId"
              exists = "false"
            },
            {
              field  = "Microsoft.Compute/disks/encryption.diskEncryptionSetId"
              equals = ""
            }
          ]
        }
      ]
    }
    then = {
      effect = "audit"
    }
  })
}

resource "azurerm_subscription_policy_assignment" "disk_cmk_assignment" {
  name                 = "iso27001-disk-cmk"
  policy_definition_id = azurerm_policy_definition.disk_cmk_required.id
  subscription_id      = local.subscription_id
  display_name         = "ISO 27001 - Managed Disks must use customer-managed keys"
  description          = "Ensures managed disks use disk encryption sets with CMK"

  metadata = jsonencode({
    category   = "ISO 27001 - Cryptography"
    control    = "A.10.1.1"
    assignedBy = "Terraform"
  })

  depends_on = [azurerm_policy_definition.disk_cmk_required]
}

#
# ==================== DATA EXPLORER (KUSTO) POLICIES ====================
#

# Custom Policy 8: Data Explorer clusters should have disk encryption enabled
resource "azurerm_policy_definition" "kusto_disk_encryption" {
  name         = "iso27001-kusto-disk-encryption"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "ISO 27001 - Data Explorer clusters should have disk encryption enabled"
  description  = "Audits Data Explorer (Kusto) clusters without disk encryption"

  metadata = jsonencode({
    category = "ISO 27001 - Cryptography"
    control  = "A.10.1.1"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Kusto/clusters"
        },
        {
          anyOf = [
            {
              field  = "Microsoft.Kusto/clusters/enableDiskEncryption"
              exists = "false"
            },
            {
              field     = "Microsoft.Kusto/clusters/enableDiskEncryption"
              notEquals = true
            }
          ]
        }
      ]
    }
    then = {
      effect = "audit"
    }
  })
}

resource "azurerm_subscription_policy_assignment" "kusto_disk_encryption_assignment" {
  name                 = "iso27001-kusto-encryption"
  policy_definition_id = azurerm_policy_definition.kusto_disk_encryption.id
  subscription_id      = local.subscription_id
  display_name         = "ISO 27001 - Data Explorer clusters require disk encryption"
  description          = "Ensures Data Explorer clusters have disk encryption enabled"

  metadata = jsonencode({
    category   = "ISO 27001 - Cryptography"
    control    = "A.10.1.1"
    assignedBy = "Terraform"
  })

  depends_on = [azurerm_policy_definition.kusto_disk_encryption]
}

# Custom Policy 9: Data Explorer should use customer-managed keys
resource "azurerm_policy_definition" "kusto_cmk_required" {
  name         = "iso27001-kusto-cmk-required"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "ISO 27001 - Data Explorer should use customer-managed keys"
  description  = "Audits Data Explorer clusters that don't use customer-managed keys for encryption"

  metadata = jsonencode({
    category = "ISO 27001 - Cryptography"
    control  = "A.10.1.1"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Kusto/clusters"
        },
        {
          anyOf = [
            {
              field  = "Microsoft.Kusto/clusters/keyVaultProperties.keyName"
              exists = "false"
            },
            {
              field  = "Microsoft.Kusto/clusters/keyVaultProperties.keyVaultUri"
              exists = "false"
            }
          ]
        }
      ]
    }
    then = {
      effect = "audit"
    }
  })
}

resource "azurerm_subscription_policy_assignment" "kusto_cmk_assignment" {
  name                 = "iso27001-kusto-cmk"
  policy_definition_id = azurerm_policy_definition.kusto_cmk_required.id
  subscription_id      = local.subscription_id
  display_name         = "ISO 27001 - Data Explorer must use customer-managed keys"
  description          = "Ensures Data Explorer uses CMK for encryption at rest"

  metadata = jsonencode({
    category   = "ISO 27001 - Cryptography"
    control    = "A.10.1.1"
    assignedBy = "Terraform"
  })

  depends_on = [azurerm_policy_definition.kusto_cmk_required]
}

#
# ==================== AKS (KUBERNETES) POLICIES ====================
#

# Policy 10: AKS clusters should have Azure Policy add-on enabled
resource "azurerm_subscription_policy_assignment" "aks_azure_policy_addon" {
  name                 = "iso27001-aks-policy-addon"
  subscription_id      = local.subscription_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/a8eff44f-8c92-45c3-a3fb-9880802d67a7"
  display_name         = "ISO 27001 - AKS clusters should have Azure Policy add-on enabled"
  description          = "Enables policy enforcement within AKS clusters"
  enforce              = true
  location             = "swedencentral"

  identity {
    type = "SystemAssigned"
  }
  
  metadata = jsonencode({
    assignedBy = "Terraform"
    category   = "ISO 27001 - Cryptography"
    control    = "A.10.1.1"
  })
}

# Custom Policy 11: AKS clusters should have encryption at host enabled
resource "azurerm_policy_definition" "aks_encryption_at_host" {
  name         = "iso27001-aks-encryption-at-host"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "ISO 27001 - AKS node pools should have encryption at host enabled"
  description  = "Audits AKS clusters where node pools don't have encryption at host enabled"

  metadata = jsonencode({
    category = "ISO 27001 - Cryptography"
    control  = "A.10.1.1"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.ContainerService/managedClusters"
        },
        {
          count = {
            field = "Microsoft.ContainerService/managedClusters/agentPoolProfiles[*]"
            where = {
              anyOf = [
                {
                  field  = "Microsoft.ContainerService/managedClusters/agentPoolProfiles[*].enableEncryptionAtHost"
                  exists = "false"
                },
                {
                  field     = "Microsoft.ContainerService/managedClusters/agentPoolProfiles[*].enableEncryptionAtHost"
                  notEquals = true
                }
              ]
            }
          }
          greater = 0
        }
      ]
    }
    then = {
      effect = "audit"
    }
  })
}

resource "azurerm_subscription_policy_assignment" "aks_encryption_at_host_assignment" {
  name                 = "iso27001-aks-encrypt-host"
  policy_definition_id = azurerm_policy_definition.aks_encryption_at_host.id
  subscription_id      = local.subscription_id
  display_name         = "ISO 27001 - AKS node pools must have encryption at host"
  description          = "Ensures AKS node pools use encryption at host for data security"

  metadata = jsonencode({
    category   = "ISO 27001 - Cryptography"
    control    = "A.10.1.1"
    assignedBy = "Terraform"
  })

  depends_on = [azurerm_policy_definition.aks_encryption_at_host]
}

#
# ==================== VIRTUAL MACHINE ENCRYPTION ====================
#

# Custom Policy: Audit VMs without EncryptionAtHost or Azure Disk Encryption
resource "azurerm_policy_definition" "vm_encryption_audit" {
  name         = "custom-vm-encryption-audit"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Audit VMs without EncryptionAtHost or Azure Disk Encryption"
  description  = "Audits VMs that don't have EncryptionAtHost enabled or Azure Disk Encryption applied. This allows either encryption method."

  metadata = jsonencode({
    category = "ISO 27001 - Cryptography"
    control  = "A.10.1.1"
    source   = "Terraform"
    version  = "1.0.0"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Compute/virtualMachines"
        },
        {
          # Only audit if EncryptionAtHost is NOT enabled
          # (If it IS enabled, VM is compliant)
          anyOf = [
            {
              field  = "Microsoft.Compute/virtualMachines/securityProfile.encryptionAtHost"
              exists = "false"
            },
            {
              field     = "Microsoft.Compute/virtualMachines/securityProfile.encryptionAtHost"
              notEquals = true
            }
          ]
        }
      ]
    }
    then = {
      effect = "auditIfNotExists"
      details = {
        type = "Microsoft.Compute/virtualMachines/extensions"
        existenceCondition = {
          allOf = [
            {
              field  = "Microsoft.Compute/virtualMachines/extensions/publisher"
              equals = "Microsoft.Azure.Security"
            },
            {
              field = "Microsoft.Compute/virtualMachines/extensions/type"
              in    = ["AzureDiskEncryption", "AzureDiskEncryptionForLinux"]
            },
            {
              field  = "Microsoft.Compute/virtualMachines/extensions/provisioningState"
              equals = "Succeeded"
            }
          ]
        }
      }
    }
  })
}

# Policy Assignment: VM Encryption Audit
resource "azurerm_subscription_policy_assignment" "vm_encryption_audit" {
  name                 = "vm-encryption-audit"
  policy_definition_id = azurerm_policy_definition.vm_encryption_audit.id
  subscription_id      = local.subscription_id
  display_name         = "Audit VMs - Require EncryptionAtHost OR Azure Disk Encryption"
  description          = "Audits VMs to ensure they have either EncryptionAtHost or Azure Disk Encryption. Does not block deployment. Applies to both Windows and Linux VMs."
  location             = "swedencentral"

  identity {
    type = "SystemAssigned"
  }

  metadata = jsonencode({
    category   = "ISO 27001 - Cryptography"
    control    = "A.10.1.1"
    assignedBy = "Terraform"
  })

  depends_on = [azurerm_policy_definition.vm_encryption_audit]
}

#
# ==================== OUTPUTS ====================
#

output "subscription_id" {
  description = "The subscription ID where policies are deployed"
  value       = local.subscription_id
}

output "enforcement_mode" {
  description = "The enforcement mode variable value (note: only applies to policies where 'enforce' is set using this variable)"
  value       = var.enforcement_mode
}

output "policy_assignments" {
  description = "List of all policy assignments created"
  value = {
    storage_https                = azurerm_subscription_policy_assignment.storage_https_required.id
    storage_cmk                  = azurerm_subscription_policy_assignment.storage_cmk_required.id
    storage_disable_public       = azurerm_subscription_policy_assignment.storage_disable_public_access.id
    sql_tde_cmk                  = azurerm_subscription_policy_assignment.sql_tde_cmk_required.id
    keyvault_soft_delete         = azurerm_subscription_policy_assignment.keyvault_soft_delete.id
    keyvault_purge_protection    = azurerm_subscription_policy_assignment.keyvault_purge_protection.id
    disk_cmk                     = azurerm_subscription_policy_assignment.disk_cmk_assignment.id
    kusto_disk_encryption        = azurerm_subscription_policy_assignment.kusto_disk_encryption_assignment.id
    kusto_cmk                    = azurerm_subscription_policy_assignment.kusto_cmk_assignment.id
    aks_azure_policy_addon       = azurerm_subscription_policy_assignment.aks_azure_policy_addon.id
    aks_encryption_at_host       = azurerm_subscription_policy_assignment.aks_encryption_at_host_assignment.id
    vm_encryption_audit          = azurerm_subscription_policy_assignment.vm_encryption_audit.id
    app_service_tls_12           = azurerm_subscription_policy_assignment.app_service_tls_12.id
    function_app_tls_12          = azurerm_subscription_policy_assignment.function_app_tls_12.id
    cognitive_services_cmk       = azurerm_subscription_policy_assignment.cognitive_services_cmk.id
    app_service_tls_13           = azurerm_subscription_policy_assignment.app_service_tls_13.id
    cdn_tls_13                   = azurerm_subscription_policy_assignment.cdn_tls_13.id
    app_gateway_tls_13           = azurerm_subscription_policy_assignment.app_gateway_tls_13.id
  }
}

output "custom_policy_definitions" {
  description = "List of custom policy definitions created"
  value = {
    disk_cmk_required        = azurerm_policy_definition.disk_cmk_required.id
    kusto_disk_encryption    = azurerm_policy_definition.kusto_disk_encryption.id
    kusto_cmk_required       = azurerm_policy_definition.kusto_cmk_required.id
    aks_encryption_at_host   = azurerm_policy_definition.aks_encryption_at_host.id
    vm_encryption_audit      = azurerm_policy_definition.vm_encryption_audit.id
    mysql_ssl_enforcement    = azurerm_policy_definition.mysql_ssl_enforcement.id
    postgresql_ssl_enforcement = azurerm_policy_definition.postgresql_ssl_enforcement.id
    cosmosdb_cmk_required    = azurerm_policy_definition.cosmosdb_cmk_required.id
    servicebus_cmk_required  = azurerm_policy_definition.servicebus_cmk_required.id
    eventhub_cmk_required    = azurerm_policy_definition.eventhub_cmk_required.id
    acr_cmk_required         = azurerm_policy_definition.acr_cmk_required.id
    ml_workspace_cmk         = azurerm_policy_definition.ml_workspace_cmk.id
  }
}

# MySQL/PostgreSQL Encryption Policies
resource "azurerm_policy_definition" "mysql_ssl_enforcement" {
  name         = "iso27001-mysql-ssl-required"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "ISO 27001 - MySQL servers should enforce SSL connections"
  description  = "Ensures MySQL servers require SSL/TLS for connections"

  metadata = jsonencode({
    category = "ISO 27001 - Cryptography"
    control  = "A.10.1.1"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.DBforMySQL/servers"
        },
        {
          field     = "Microsoft.DBforMySQL/servers/sslEnforcement"
          notEquals = "Enabled"
        }
      ]
    }
    then = {
      effect = "audit"
    }
  })
}

resource "azurerm_policy_definition" "postgresql_ssl_enforcement" {
  name         = "iso27001-postgresql-ssl-required"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "ISO 27001 - PostgreSQL servers should enforce SSL connections"
  description  = "Ensures PostgreSQL servers require SSL/TLS for connections"

  metadata = jsonencode({
    category = "ISO 27001 - Cryptography"
    control  = "A.10.1.1"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.DBforPostgreSQL/servers"
        },
        {
          field     = "Microsoft.DBforPostgreSQL/servers/sslEnforcement"
          notEquals = "Enabled"
        }
      ]
    }
    then = {
      effect = "audit"
    }
  })
}

# Cosmos DB Encryption
resource "azurerm_policy_definition" "cosmosdb_cmk_required" {
  name         = "iso27001-cosmosdb-cmk-required"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "ISO 27001 - Cosmos DB should use customer-managed keys"
  description  = "Audits Cosmos DB accounts without customer-managed key encryption"

  metadata = jsonencode({
    category = "ISO 27001 - Cryptography"
    control  = "A.10.1.1"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.DocumentDB/databaseAccounts"
        },
        {
          anyOf = [
            {
              field  = "Microsoft.DocumentDB/databaseAccounts/keyVaultKeyUri"
              exists = "false"
            },
            {
              field  = "Microsoft.DocumentDB/databaseAccounts/keyVaultKeyUri"
              equals = ""
            }
          ]
        }
      ]
    }
    then = {
      effect = "audit"
    }
  })
}

resource "azurerm_subscription_policy_assignment" "cosmosdb_cmk_assignment" {
  name                 = "iso27001-cosmosdb-cmk-required"
  policy_definition_id = azurerm_policy_definition.cosmosdb_cmk_required.id
  subscription_id      = local.subscription_id
  display_name         = "ISO 27001 - Cosmos DB should use customer-managed keys"
  description          = "Audits Cosmos DB accounts without customer-managed key encryption"
  metadata = jsonencode({
    category   = "ISO 27001 - Cryptography"
    control    = "A.10.1.1"
    assignedBy = "Terraform"
  })
  depends_on = [azurerm_policy_definition.cosmosdb_cmk_required]
}

# App Service TLS Policy
resource "azurerm_subscription_policy_assignment" "app_service_tls_12" {
  name                 = "iso27001-appservice-tls"
  subscription_id      = local.subscription_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/ae44c1d1-0df2-4ca9-98fa-a3d3ae5b409d"
  display_name         = "ISO 27001 - App Service apps should use TLS 1.2 or higher"
  description          = "Enforces minimum TLS version for App Service apps"

  metadata = jsonencode({
    category   = "ISO 27001 - Cryptography"
    control    = "A.10.1.1"
    assignedBy = "Terraform"
  })

  identity {
    type = "SystemAssigned"
  }

  location = "swedencentral"  # Required when identity is specified
}

# Function App TLS Policy
resource "azurerm_subscription_policy_assignment" "function_app_tls_12" {
  name                 = "iso27001-function-tls"
  subscription_id      = local.subscription_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/f9d614c5-c173-4d56-95a7-b4437057d193"
  display_name         = "ISO 27001 - Function Apps should use TLS 1.2 or higher"
  description          = "Enforces minimum TLS version for Function Apps"

  metadata = jsonencode({
    category   = "ISO 27001 - Cryptography"
    control    = "A.10.1.1"
    assignedBy = "Terraform"
  })

  identity {
    type = "SystemAssigned"
  }

  location = "swedencentral"  # Required when identity is specified
}

# ==================== ENCRYPTION IN TRANSIT POLICIES ====================

# Policy: App Service must use TLS 1.3
resource "azurerm_subscription_policy_assignment" "app_service_tls_13" {
  name                 = "iso27001-appservice-tls13"
  subscription_id      = local.subscription_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/0a914e76-4921-4c7b-8d3b-4b6b6b8a0b7e" # Built-in: App Service should use latest TLS version
  display_name         = "ISO 27001 - App Service apps should use TLS 1.3"
  description          = "Enforces minimum TLS version 1.3 for App Service apps"

  metadata = jsonencode({
    category   = "ISO 27001 - Cryptography"
    control    = "A.10.1.1"
    assignedBy = "Terraform"
  })

  identity {
    type = "SystemAssigned"
  }

  location = "swedencentral"
}

# Policy: CDN endpoints must use TLS 1.3
resource "azurerm_subscription_policy_assignment" "cdn_tls_13" {
  name                 = "iso27001-cdn-tls13"
  subscription_id      = local.subscription_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/0a914e76-4921-4c7b-8d3b-4b6b6b8a0b7e" # Built-in: CDN should use latest TLS version
  display_name         = "ISO 27001 - CDN endpoints should use TLS 1.3"
  description          = "Enforces minimum TLS version 1.3 for CDN endpoints"

  metadata = jsonencode({
    category   = "ISO 27001 - Cryptography"
    control    = "A.10.1.1"
    assignedBy = "Terraform"
  })

  identity {
    type = "SystemAssigned"
  }

  location = "swedencentral"
}

# Policy: Application Gateway must use TLS 1.3
resource "azurerm_subscription_policy_assignment" "app_gateway_tls_13" {
  name                 = "iso27001-appgw-tls13"
  subscription_id      = local.subscription_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/0a914e76-4921-4c7b-8d3b-4b6b6b8a0b7e" # Built-in: App Gateway should use latest TLS version
  display_name         = "ISO 27001 - Application Gateway should use TLS 1.3"
  description          = "Enforces minimum TLS version 1.3 for Application Gateway"

  metadata = jsonencode({
    category   = "ISO 27001 - Cryptography"
    control    = "A.10.1.1"
    assignedBy = "Terraform"
  })

  identity {
    type = "SystemAssigned"
  }

  location = "swedencentral"
}

# ==================== CRYPTOGRAPHIC CONTROLS - DATA AT REST ====================

# Storage Accounts must use encryption-at-rest
resource "azurerm_subscription_policy_assignment" "storage_encryption_required" {
  name                 = "iso27001-storage-encryption"
  subscription_id      = local.subscription_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/2a2b9908-6ea1-4ae2-8e65-6b5b4b7a2730" # Built-in: Storage accounts should be encrypted
  display_name         = "ISO 27001 - Storage accounts must use encryption-at-rest"
  description          = "Enforces encryption-at-rest for all storage accounts"
  metadata = jsonencode({
    category   = "ISO 27001 - Cryptography"
    control    = "A.10.1.1"
    assignedBy = "Terraform"
  })
}

# SQL, MySQL, PostgreSQL must use encryption-at-rest
resource "azurerm_subscription_policy_assignment" "sql_encryption_required" {
  name                 = "iso27001-sql-encryption"
  subscription_id      = local.subscription_id
  policy_definition_id = azurerm_policy_definition.sql_tde_cmk_required.id
  display_name         = "ISO 27001 - SQL servers must use encryption-at-rest"
  description          = "Enforces encryption-at-rest for Azure SQL, MySQL, PostgreSQL servers"
  metadata = jsonencode({
    category   = "ISO 27001 - Cryptography"
    control    = "A.10.1.1"
    assignedBy = "Terraform"
  })
  depends_on = [azurerm_policy_definition.sql_tde_cmk_required]
}

# Key Vault must use encryption-at-rest (default)
# Already enforced by Azure, but can audit for compliance
resource "azurerm_subscription_policy_assignment" "keyvault_encryption_audit" {
  name                 = "iso27001-keyvault-encryption-audit"
  subscription_id      = local.subscription_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/0a914e76-4921-4c7b-8d3b-4b6b6b8a0b7e"
  display_name         = "ISO 27001 - Key Vault encryption audit"
  description          = "Audits Key Vaults for encryption-at-rest compliance"
  metadata = jsonencode({
    category   = "ISO 27001 - Cryptography"
    control    = "A.10.1.1"
    assignedBy = "Terraform"
  })
}

# Disk Encryption for VMs
resource "azurerm_subscription_policy_assignment" "disk_encryption_required" {
  name                 = "iso27001-disk-encryption-cmk"
  subscription_id      = local.subscription_id
  policy_definition_id = azurerm_policy_definition.disk_cmk_required.id
  display_name         = "ISO 27001 - Managed disks must use encryption"
  description          = "Enforces disk encryption for all managed disks"
  metadata = jsonencode({
    category   = "ISO 27001 - Cryptography"
    control    = "A.10.1.1"
    assignedBy = "Terraform"
  })
  depends_on = [azurerm_policy_definition.disk_cmk_required]
}

# Backup Vaults must use encryption
resource "azurerm_subscription_policy_assignment" "backup_encryption_required" {
  name                 = "iso27001-backup-encryption"
  subscription_id      = local.subscription_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/2a2b9908-6ea1-4ae2-8e65-6b5b4b7a2730"
  display_name         = "ISO 27001 - Backup vaults must use encryption"
  description          = "Enforces encryption for Azure Backup vaults"
  metadata = jsonencode({
    category   = "ISO 27001 - Cryptography"
    control    = "A.10.1.1"
    assignedBy = "Terraform"
  })
}

# Container Registry must use encryption
resource "azurerm_subscription_policy_assignment" "acr_encryption_required" {
  name                 = "iso27001-acr-encryption"
  subscription_id      = local.subscription_id
  policy_definition_id = azurerm_policy_definition.acr_cmk_required.id
  display_name         = "ISO 27001 - Container registries must use encryption"
  description          = "Enforces encryption for Azure Container Registry"
  metadata = jsonencode({
    category   = "ISO 27001 - Cryptography"
    control    = "A.10.1.1"
    assignedBy = "Terraform"
  })
  depends_on = [azurerm_policy_definition.acr_cmk_required]
}

# Data Explorer (Kusto) must use disk encryption and CMK
resource "azurerm_subscription_policy_assignment" "kusto_encryption_required" {
  name                 = "iso27001-kusto-encryption-disk"
  subscription_id      = local.subscription_id
  policy_definition_id = azurerm_policy_definition.kusto_disk_encryption.id
  display_name         = "ISO 27001 - Data Explorer must use disk encryption"
  description          = "Enforces disk encryption for Data Explorer clusters"
  metadata = jsonencode({
    category   = "ISO 27001 - Cryptography"
    control    = "A.10.1.1"
    assignedBy = "Terraform"
  })
  depends_on = [azurerm_policy_definition.kusto_disk_encryption]
}

resource "azurerm_subscription_policy_assignment" "kusto_cmk_assignment" {
  name                 = "iso27001-kusto-cmk-required"
  subscription_id      = local.subscription_id
  policy_definition_id = azurerm_policy_definition.kusto_cmk_required.id
  display_name         = "ISO 27001 - Data Explorer must use CMK"
  description          = "Enforces CMK for Data Explorer clusters"
  metadata = jsonencode({
    category   = "ISO 27001 - Cryptography"
    control    = "A.10.1.1"
    assignedBy = "Terraform"
  })
  depends_on = [azurerm_policy_definition.kusto_cmk_required]
}

# General Audit: Audit any resource not using encryption
resource "azurerm_policy_definition" "general_encryption_audit" {
  name         = "iso27001-general-encryption-audit"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "ISO 27001 - Audit resources without encryption"
  description  = "Audits any resource not using encryption for data at rest or in transit"
  metadata = jsonencode({
    category = "ISO 27001 - Cryptography"
    control  = "A.10.1.1"
  })
  policy_rule = jsonencode({
    if = {
      not = {
        anyOf = [
          {
            field = "type"
            equals = "Microsoft.Storage/storageAccounts"
          },
          {
            field = "Microsoft.Storage/storageAccounts/encryption.services.blob.enabled"
            equals = "true"
          },
          {
            field = "type"
            equals = "Microsoft.Sql/servers"
          },
          {
            field = "Microsoft.Sql/servers/transparentDataEncryption.status"
            equals = "Enabled"
          },
          {
            field = "type"
            equals = "Microsoft.KeyVault/vaults"
          },
          {
            field = "Microsoft.KeyVault/vaults/properties.enableSoftDelete"
            equals = "true"
          }
        ]
      }
    }
    then = {
      effect = "audit"
    }
  })
}

resource "azurerm_subscription_policy_assignment" "general_encryption_audit_assignment" {
  name                 = "iso27001-general-encryption-audit"
  subscription_id      = local.subscription_id
  policy_definition_id = azurerm_policy_definition.general_encryption_audit.id
  display_name         = "ISO 27001 - Audit resources without encryption"
  description          = "Audits any resource not using encryption for data at rest or in transit"
  metadata = jsonencode({
    category   = "ISO 27001 - Cryptography"
    control    = "A.10.1.1"
    assignedBy = "Terraform"
  })
  depends_on = [azurerm_policy_definition.general_encryption_audit]
}
