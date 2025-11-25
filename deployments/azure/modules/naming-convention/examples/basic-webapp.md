# Basic Web Application Example

This example demonstrates using the naming convention module for a simple web application infrastructure.

## Usage

```bash
cd examples/basic-webapp
terraform init
terraform plan
```

## Configuration

```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Use the naming convention module
module "naming" {
  source = "../../"
  
  workload    = "webapp"
  environment = "dev"
  region      = "westeurope"
  instance    = "01"
  
  additional_tags = {
    CostCenter = "Engineering"
    Owner      = "DevTeam"
    Project    = "CustomerPortal"
  }
}

# Resource Group
resource "azurerm_resource_group" "webapp" {
  name     = module.naming.resource_group_name
  location = var.region
  tags     = module.naming.common_tags
}

# Virtual Network
resource "azurerm_virtual_network" "webapp" {
  name                = module.naming.virtual_network_name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.webapp.location
  resource_group_name = azurerm_resource_group.webapp.name
  tags                = module.naming.common_tags
}

# Storage Account
resource "azurerm_storage_account" "webapp" {
  name                     = module.naming.storage_account_name
  resource_group_name      = azurerm_resource_group.webapp.name
  location                 = azurerm_resource_group.webapp.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = module.naming.common_tags
}

# App Service Plan
resource "azurerm_service_plan" "webapp" {
  name                = "plan-${module.naming.app_service_name}"
  resource_group_name = azurerm_resource_group.webapp.name
  location            = azurerm_resource_group.webapp.location
  os_type             = "Linux"
  sku_name            = "B1"
  tags                = module.naming.common_tags
}

# App Service
resource "azurerm_linux_web_app" "webapp" {
  name                = module.naming.app_service_name
  resource_group_name = azurerm_resource_group.webapp.name
  location            = azurerm_service_plan.webapp.location
  service_plan_id     = azurerm_service_plan.webapp.id
  tags                = module.naming.common_tags

  site_config {
    always_on = false
  }
}

# Application Insights
resource "azurerm_application_insights" "webapp" {
  name                = module.naming.application_insights_name
  location            = azurerm_resource_group.webapp.location
  resource_group_name = azurerm_resource_group.webapp.name
  application_type    = "web"
  tags                = module.naming.common_tags
}

# Variables
variable "region" {
  description = "Azure region"
  type        = string
  default     = "westeurope"
}

# Outputs
output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.webapp.name
}

output "app_service_url" {
  description = "App Service URL"
  value       = azurerm_linux_web_app.webapp.default_hostname
}

output "storage_account_name" {
  description = "Storage account name"
  value       = azurerm_storage_account.webapp.name
}

output "all_tags" {
  description = "Common tags applied to all resources"
  value       = module.naming.common_tags
}
```

## Expected Resource Names

- Resource Group: `rg-webapp-dev-weu`
- Virtual Network: `vnet-webapp-dev-weu-01`
- Storage Account: `stwebappdevweu001`
- App Service: `app-webapp-dev-weu-01`
- Application Insights: `appi-monitoring-dev-weu`
