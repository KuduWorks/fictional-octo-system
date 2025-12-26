terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "azurerm" {
  features {}
}

# Data source for existing Terraform state storage account
data "azurerm_storage_account" "state_storage_account" {
  name                = var.state_storage_account_name
  resource_group_name = var.state_storage_resource_group_name

}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}