terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "tfstateprod20251215"
    container_name       = "tfstate-prod"
    key                  = "terraform.tfstate"
    use_azuread_auth     = true
  } # Do not include credentials here. Use Azure CLI authentication (az login), environment variables (ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID), or managed identity for secure access.
}