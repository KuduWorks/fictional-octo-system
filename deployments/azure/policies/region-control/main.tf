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

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Get current subscription data
data "azurerm_client_config" "current" {}

# Variables
variable "allowed_regions" {
  description = "List of allowed Azure regions"
  type        = list(string)
  default     = ["swedencentral"]
}

variable "policy_assignment_name" {
  description = "Name for the policy assignment"
  type        = string
  default     = "allowed-regions-policy"
}

variable "policy_assignment_display_name" {
  description = "Display name for the policy assignment"
  type        = string
  default     = "Allowed Regions Policy - Sweden Central"
}

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
  subscription_id_raw                   = var.subscription_id != null ? var.subscription_id : data.azurerm_client_config.current.subscription_id
  subscription_id                       = "/subscriptions/${local.subscription_id_raw}"
  allowed_locations_definition_id       = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
  allowed_rg_locations_definition_id    = "/providers/Microsoft.Authorization/policyDefinitions/e765b5de-1225-4ba3-bd56-1ac6695af988"
  subscription_scope                    = local.subscription_id
}

# Policy Assignment for Allowed Locations (Built-in Policy)
resource "azurerm_subscription_policy_assignment" "allowed_locations_assignment" {
  name                 = var.policy_assignment_name
  policy_definition_id = local.allowed_locations_definition_id
  subscription_id      = local.subscription_id
  display_name         = var.policy_assignment_display_name
  description          = "This policy restricts resource deployment to approved Azure regions (Sweden Central)"
  location             = var.allowed_regions[0]

  identity {
    type = "SystemAssigned"
  }

  parameters = jsonencode({
    listOfAllowedLocations = {
      value = var.allowed_regions
    }
  })

  metadata = jsonencode({
    category = "General"
    source   = "Terraform"
    version  = "1.0.0"
  })
}

# Policy Assignment for Resource Group Locations (Built-in Policy)
resource "azurerm_subscription_policy_assignment" "rg_location_assignment" {
  name                 = "rg-location-policy-assignment"
  policy_definition_id = local.allowed_rg_locations_definition_id
  subscription_id      = local.subscription_id
  display_name         = "Resource Group Location Control - Sweden Central"
  description          = "Ensures resource groups are created only in Sweden Central using built-in policy"
  location             = var.allowed_regions[0]

  identity {
    type = "SystemAssigned"
  }

  parameters = jsonencode({
    listOfAllowedLocations = {
      value = var.allowed_regions
    }
  })

  metadata = jsonencode({
    category = "General"
    source   = "Terraform"
    version  = "1.0.0"
  })
}

# Outputs
output "allowed_locations_policy_assignment_id" {
  description = "The ID of the allowed locations policy assignment"
  value       = azurerm_subscription_policy_assignment.allowed_locations_assignment.id
}

output "allowed_locations_policy_assignment_name" {
  description = "The name of the allowed locations policy assignment"
  value       = azurerm_subscription_policy_assignment.allowed_locations_assignment.name
}

output "resource_group_location_policy_assignment_id" {
  description = "The ID of the resource group location policy assignment"
  value       = azurerm_subscription_policy_assignment.rg_location_assignment.id
}

output "configured_allowed_regions" {
  description = "The list of allowed regions configured in the policies"
  value       = var.allowed_regions
}

output "enforcement_mode" {
  description = "The enforcement mode of the policies"
  value       = var.enforcement_mode
}

output "subscription_id" {
  description = "The subscription ID where policies are deployed"
  value       = local.subscription_id
}