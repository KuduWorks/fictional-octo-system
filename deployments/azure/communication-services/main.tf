terraform {
  required_version = ">= 1.3.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "acs" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Communication Service
resource "azurerm_communication_service" "acs" {
  name                = var.communication_service_name
  resource_group_name = azurerm_resource_group.acs.name
  data_location       = var.data_location
  tags                = var.tags
}

# Email Communication Service
resource "azurerm_email_communication_service" "email" {
  name                = "${var.communication_service_name}-email"
  resource_group_name = azurerm_resource_group.acs.name
  data_location       = var.data_location
  tags                = var.tags
}

# Custom Email Domain
resource "azurerm_email_communication_service_domain" "custom_domain" {
  name                     = var.domain_name
  email_service_id         = azurerm_email_communication_service.email.id
  domain_management        = "CustomerManaged"
  
  tags = var.tags
}

# Link Email Service to Communication Service
resource "azurerm_communication_service_email_domain_association" "association" {
  communication_service_id = azurerm_communication_service.acs.id
  email_service_domain_id  = azurerm_email_communication_service_domain.custom_domain.id
}

# Sender Username (creates no-reply@yourdomain.com)
# Note: This resource may need to be created via Azure CLI or Portal
# as Terraform provider support varies

# Output connection string and domain verification info
data "azurerm_communication_service" "acs" {
  name                = azurerm_communication_service.acs.name
  resource_group_name = azurerm_resource_group.acs.name
  depends_on          = [azurerm_communication_service.acs]
}
