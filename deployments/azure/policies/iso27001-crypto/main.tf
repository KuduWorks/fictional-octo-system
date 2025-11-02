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
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/f0e6e85b-9b9f-4a4b-b67b-f730d42f1b0b"  # Verify this ID exists
  display_name         = "ISO 27001 - App Service apps should use TLS 1.2 or higher"
  description          = "Enforces minimum TLS version for App Service apps"

  metadata = jsonencode({
    category   = "ISO 27001 - Cryptography"
    control    = "A.10.1.1"
    assignedBy = "Terraform"
  })
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
}

# Service Bus CMK Policy
resource "azurerm_policy_definition" "servicebus_cmk_required" {
  name         = "iso27001-servicebus-cmk-required"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "ISO 27001 - Service Bus namespaces should use customer-managed keys"
  description  = "Audits Service Bus namespaces without CMK encryption"

  metadata = jsonencode({
    category = "ISO 27001 - Cryptography"
    control  = "A.10.1.1"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.ServiceBus/namespaces"
        },
        {
          anyOf = [
            {
              field  = "Microsoft.ServiceBus/namespaces/encryption.keySource"
              notEquals = "Microsoft.KeyVault"
            },
            {
              field  = "Microsoft.ServiceBus/namespaces/encryption.keySource"
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

resource "azurerm_subscription_policy_assignment" "servicebus_cmk_assignment" {
  name                 = "iso27001-servicebus-cmk-required"
  policy_definition_id = azurerm_policy_definition.servicebus_cmk_required.id
  subscription_id      = local.subscription_id
  display_name         = "ISO 27001 - Service Bus namespaces should use customer-managed keys"
  description          = "Audits Service Bus namespaces without CMK encryption"
  metadata = jsonencode({
    category   = "ISO 27001 - Cryptography"
    control    = "A.10.1.1"
    assignedBy = "Terraform"
  })
  depends_on = [azurerm_policy_definition.servicebus_cmk_required]
}

# Event Hub CMK Policy
resource "azurerm_policy_definition" "eventhub_cmk_required" {
  name         = "iso27001-eventhub-cmk-required"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "ISO 27001 - Event Hub namespaces should use customer-managed keys"
  description  = "Audits Event Hub namespaces without CMK encryption"

  metadata = jsonencode({
    category = "ISO 27001 - Cryptography"
    control  = "A.10.1.1"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.EventHub/namespaces"
        },
        {
          anyOf = [
            {
              field  = "Microsoft.EventHub/namespaces/encryption.keySource"
              notEquals = "Microsoft.KeyVault"
            },
            {
              field  = "Microsoft.EventHub/namespaces/encryption.keySource"
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

resource "azurerm_subscription_policy_assignment" "eventhub_cmk_assignment" {
  name                 = "iso27001-eventhub-cmk-required"
  policy_definition_id = azurerm_policy_definition.eventhub_cmk_required.id
  subscription_id      = local.subscription_id
  display_name         = "ISO 27001 - Event Hub namespaces should use customer-managed keys"
  description          = "Audits Event Hub namespaces without CMK encryption"
  metadata = jsonencode({
    category   = "ISO 27001 - Cryptography"
    control    = "A.10.1.1"
    assignedBy = "Terraform"
  })
  depends_on = [azurerm_policy_definition.eventhub_cmk_required]
}

# Container Registry CMK Policy
resource "azurerm_policy_definition" "acr_cmk_required" {
  name         = "iso27001-acr-cmk-required"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "ISO 27001 - Container registries should use customer-managed keys"
  description  = "Audits container registries without CMK encryption"

  metadata = jsonencode({
    category = "ISO 27001 - Cryptography"
    control  = "A.10.1.1"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.ContainerRegistry/registries"
        },
        {
          anyOf = [
            {
              field  = "Microsoft.ContainerRegistry/registries/encryption.status"
              notEquals = "enabled"
            },
            {
              field  = "Microsoft.ContainerRegistry/registries/encryption.status"
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

resource "azurerm_subscription_policy_assignment" "acr_cmk_assignment" {
  name                 = "iso27001-acr-cmk-required"
  policy_definition_id = azurerm_policy_definition.acr_cmk_required.id
  subscription_id      = local.subscription_id
  display_name         = "ISO 27001 - Container registries should use customer-managed keys"
  description          = "Audits container registries without CMK encryption"
  metadata = jsonencode({
    category   = "ISO 27001 - Cryptography"
    control    = "A.10.1.1"
    assignedBy = "Terraform"
  })
  depends_on = [azurerm_policy_definition.acr_cmk_required]
}

# Azure Machine Learning Workspace Encryption
resource "azurerm_policy_definition" "ml_workspace_cmk" {
  name         = "iso27001-ml-workspace-cmk"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "ISO 27001 - ML workspaces should use customer-managed keys"
  description  = "Audits Machine Learning workspaces without CMK encryption"

  metadata = jsonencode({
    category = "ISO 27001 - Cryptography"
    control  = "A.10.1.1"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.MachineLearningServices/workspaces"
        },
        {
          anyOf = [
            {
              field  = "Microsoft.MachineLearningServices/workspaces/encryption.status"
              notEquals = "Enabled"
            },
            {
              field  = "Microsoft.MachineLearningServices/workspaces/encryption.status"
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

resource "azurerm_subscription_policy_assignment" "ml_workspace_cmk_assignment" {
  name                 = "iso27001-ml-workspace-cmk"
  policy_definition_id = azurerm_policy_definition.ml_workspace_cmk.id
  subscription_id      = local.subscription_id
  display_name         = "ISO 27001 - ML workspaces should use customer-managed keys"
  description          = "Audits Machine Learning workspaces without CMK encryption"
  metadata = jsonencode({
    category   = "ISO 27001 - Cryptography"
    control    = "A.10.1.1"
    assignedBy = "Terraform"
  })
  depends_on = [azurerm_policy_definition.ml_workspace_cmk]
}

# Cognitive Services CMK
resource "azurerm_subscription_policy_assignment" "cognitive_services_cmk" {
  name                 = "iso27001-cognitive-cmk"
  subscription_id      = local.subscription_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/67121cc7-ff39-4ab8-b7e3-95b84dab487d"
  display_name         = "ISO 27001 - Cognitive Services should use customer-managed keys"
  description          = "Enforces CMK encryption for Cognitive Services accounts"

  metadata = jsonencode({
    category   = "ISO 27001 - Cryptography"
    control    = "A.10.1.1"
    assignedBy = "Terraform"
  })
}
