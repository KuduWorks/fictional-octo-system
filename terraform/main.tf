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

resource "azurerm_resource_group" "example" {
    name     = "rg-dev-01"
    location = var.location
    tags     = var.tags
}