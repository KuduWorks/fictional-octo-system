terraform {
  backend "azurerm" {
    resource_group_name   = "rg-tfstate"
    storage_account_name  = "tfstate20251013"
    container_name        = "tfstate"
    key                   = "terraform.tfstate"
  }  # Do not include credentials here. Use Azure CLI authentication (az login), environment variables (ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID), or managed identity for secure access.
}