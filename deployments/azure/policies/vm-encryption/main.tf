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
  subscription_id_raw               = var.subscription_id != null ? var.subscription_id : data.azurerm_client_config.current.subscription_id
  subscription_id                   = "/subscriptions/${local.subscription_id_raw}"
  windows_vm_encryption_policy_id   = "/providers/Microsoft.Authorization/policyDefinitions/3dc5edcd-002d-444c-b216-e123bbfa37c0"
  linux_vm_encryption_policy_id     = "/providers/Microsoft.Authorization/policyDefinitions/ca88aadc-6e2b-416c-9de2-5a0f01d1693f"
}

# Policy Assignment for Windows VM Encryption
resource "azurerm_subscription_policy_assignment" "windows_vm_encryption" {
  name                 = "windows-vm-encryption-required"
  policy_definition_id = local.windows_vm_encryption_policy_id
  subscription_id      = local.subscription_id
  display_name         = "Windows VMs - Require Azure Disk Encryption or EncryptionAtHost"
  description          = "Enforces that Windows virtual machines must have either Azure Disk Encryption or EncryptionAtHost enabled"
  location             = "swedencentral"

  identity {
    type = "SystemAssigned"
  }

  parameters = jsonencode({
    effect = {
      value = "Deny"
    }
  })

  metadata = jsonencode({
    category   = "Security"
    source     = "Terraform"
    version    = "1.0.0"
    assignedBy = "Terraform - VM Encryption Policy"
  })
}

# Policy Assignment for Linux VM Encryption
resource "azurerm_subscription_policy_assignment" "linux_vm_encryption" {
  name                 = "linux-vm-encryption-required"
  policy_definition_id = local.linux_vm_encryption_policy_id
  subscription_id      = local.subscription_id
  display_name         = "Linux VMs - Require Azure Disk Encryption or EncryptionAtHost"
  description          = "Enforces that Linux virtual machines must have either Azure Disk Encryption or EncryptionAtHost enabled"
  location             = "swedencentral"

  identity {
    type = "SystemAssigned"
  }

  parameters = jsonencode({
    effect = {
      value = "Deny"
    }
  })

  metadata = jsonencode({
    category   = "Security"
    source     = "Terraform"
    version    = "1.0.0"
    assignedBy = "Terraform - VM Encryption Policy"
  })
}

# Outputs
output "windows_vm_encryption_assignment_id" {
  description = "The ID of the Windows VM encryption policy assignment"
  value       = azurerm_subscription_policy_assignment.windows_vm_encryption.id
}

output "linux_vm_encryption_assignment_id" {
  description = "The ID of the Linux VM encryption policy assignment"
  value       = azurerm_subscription_policy_assignment.linux_vm_encryption.id
}

output "subscription_id" {
  description = "The subscription ID where policies are deployed"
  value       = local.subscription_id
}

output "enforcement_mode" {
  description = "The enforcement mode of the policies"
  value       = var.enforcement_mode
}
