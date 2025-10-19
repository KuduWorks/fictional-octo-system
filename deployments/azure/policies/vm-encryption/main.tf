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
  description = "Policy enforcement mode"
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
}

# Policy 1: Audit VMs that don't have either encryption method
# This uses AuditIfNotExists to check for Azure Disk Encryption on existing VMs
resource "azurerm_policy_definition" "vm_encryption_audit" {
  name         = "custom-vm-encryption-audit"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Audit VMs without EncryptionAtHost or Azure Disk Encryption"
  description  = "Audits VMs that don't have EncryptionAtHost enabled or Azure Disk Encryption applied. This allows either encryption method."

  metadata = jsonencode({
    category = "Security"
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

# Policy Assignment for VM Encryption Audit
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
    category   = "Security"
    source     = "Terraform"
    version    = "1.0.0"
    assignedBy = "Terraform - VM Encryption Audit Policy"
  })

  depends_on = [azurerm_policy_definition.vm_encryption_audit]
}

# Outputs
output "vm_encryption_audit_policy_id" {
  description = "The ID of the VM encryption audit policy definition"
  value       = azurerm_policy_definition.vm_encryption_audit.id
}

output "vm_encryption_audit_assignment_id" {
  description = "The ID of the VM encryption audit policy assignment"
  value       = azurerm_subscription_policy_assignment.vm_encryption_audit.id
}

output "subscription_id" {
  description = "The subscription ID where policies are deployed"
  value       = local.subscription_id
}

output "enforcement_mode" {
  description = "The enforcement mode of the policies"
  value       = var.enforcement_mode
}
