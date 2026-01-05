# ==================== USER-ASSIGNED MANAGED IDENTITY FOR GITHUB OIDC ====================
# This managed identity will be used by GitHub Actions to authenticate to Azure
# using OpenID Connect (OIDC) instead of storing secrets/access keys.
# It can perform Terraform operations on state storage and manage Azure resources.

# Data source for current subscription (needed for role assignments)
data "azurerm_subscription" "current" {}

# User-Assigned Managed Identity for GitHub Actions
resource "azurerm_user_assigned_identity" "github_terraform" {
  name                = "uami-github-terraform"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

# Federated Identity Credential for Main Branch (terraform apply)
resource "azurerm_federated_identity_credential" "github_main" {
  name                = "github-main-branch"
  resource_group_name = azurerm_resource_group.main.name
  parent_id           = azurerm_user_assigned_identity.github_terraform.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  subject             = "repo:KuduWorks/fictional-octo-system:ref:refs/heads/main"
}

# Federated Identity Credential for Pull Requests (terraform plan)
resource "azurerm_federated_identity_credential" "github_pr" {
  name                = "github-pull-requests"
  resource_group_name = azurerm_resource_group.main.name
  parent_id           = azurerm_user_assigned_identity.github_terraform.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  subject             = "repo:KuduWorks/fictional-octo-system:pull_request"
}

# Role Assignment: Contributor on Subscription (needed to create/modify resources)
resource "azurerm_role_assignment" "github_contributor" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.github_terraform.principal_id
}

# Role Assignment: Storage Blob Data Contributor on State Storage Account
# This allows reading and writing Terraform state files
resource "azurerm_role_assignment" "github_storage_state" {
  scope                = data.azurerm_storage_account.state_storage_account.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.github_terraform.principal_id
}
