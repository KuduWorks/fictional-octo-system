# Network Security Policies for Azure
# Requires NSG on all subnets and denies public IPs on VMs (Bastion-first approach)

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

# Locals
locals {
  subscription_id_raw = var.subscription_id != null ? var.subscription_id : data.azurerm_client_config.current.subscription_id
  subscription_id     = "/subscriptions/${local.subscription_id_raw}"

  # Built-in policy definition IDs
  vm_no_public_ip_policy_id = "/providers/Microsoft.Authorization/policyDefinitions/83a86a26-fd1f-447c-b59d-e51f44264114"
}

#
# Custom Policy: Require NSG on VM Network Interfaces
#
resource "azurerm_policy_definition" "vm_nic_nsg_required" {
  name         = "vm-nic-nsg-required"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Virtual Machine Network Interfaces must have a Network Security Group"
  description  = "Audits or denies VM NICs without an associated NSG. Provides defense-in-depth alongside subnet NSGs."

  metadata = jsonencode({
    category   = "Network Security"
    control    = "ISO 27001 A.13.1.3"
    version    = "1.0.0"
    assignedBy = "Terraform"
    note       = "Defense-in-depth: NSG at both subnet and NIC level"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Network/networkInterfaces"
        },
        {
          anyOf = [
            {
              field  = "Microsoft.Network/networkInterfaces/networkSecurityGroup.id"
              exists = false
            },
            {
              field  = "Microsoft.Network/networkInterfaces/networkSecurityGroup.id"
              equals = ""
            }
          ]
        }
      ]
    }
    then = {
      effect = var.vm_nic_nsg_effect
    }
  })
}

# Policy Assignment: NSG Required on VM NICs
resource "azurerm_subscription_policy_assignment" "vm_nic_nsg_required" {
  name                 = "vm-nic-nsg-required"
  policy_definition_id = azurerm_policy_definition.vm_nic_nsg_required.id
  subscription_id      = local.subscription_id
  display_name         = "Network Security Groups Required on VM Network Interfaces"
  description          = "Ensures all VM NICs have NSGs for defense-in-depth (both internet-facing and internal VMs)"
  enforce              = var.enforcement_mode == "Default" ? true : false

  metadata = jsonencode({
    category       = "Network Security"
    control        = "ISO 27001 A.13.1.3"
    assignedBy     = "Terraform"
    defenseInDepth = "true"
    note           = "Complements subnet NSG policy"
  })
}

#
# Built-in Policy: Deny public IPs on VMs
#
resource "azurerm_subscription_policy_assignment" "no_public_ip" {
  name                 = "deny-vm-public-ip"
  policy_definition_id = local.vm_no_public_ip_policy_id
  subscription_id      = local.subscription_id
  display_name         = "Virtual Machines Should Not Have Public IP Addresses"
  description          = "Denies public IP addresses on VMs to enforce Azure Bastion for remote access"
  enforce              = var.enforcement_mode == "Default" ? true : false

  metadata = jsonencode({
    category      = "Network Security"
    control       = "ISO 27001 A.13.1.3"
    assignedBy    = "Terraform"
    justification = "Enforces Azure Bastion usage for secure VM access"
  })
}
