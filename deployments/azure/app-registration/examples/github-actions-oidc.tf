# Example: GitHub Actions with Federated Identity (Passwordless)

module "github_deployer" {
  source = "../"

  app_display_name = "github-actions-deployer"
  sign_in_audience = "AzureADMyOrg"

  # Enable GitHub OIDC - No client secret needed!
  enable_github_oidc = true
  github_org         = "KuduWorks"
  github_repo        = "fictional-octo-system"
  github_branch      = "main"

  # Azure Resource Manager permissions for deployment
  arm_permissions = [
    {
      id    = "41094075-9dad-400e-a0bd-54e686782033" # user_impersonation
      type  = "Scope"
      value = "user_impersonation"
    }
  ]

  # Keep a backup secret (optional)
  secret_rotation_days = 180

  tags = { 
    Environment = "Production"
    CICD        = "GitHub"
    ManagedBy   = "Terraform"
  }
}

# Grant RBAC permissions on subscription/resource groups
resource "azurerm_role_assignment" "github_contributor" {
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  role_definition_name = "Contributor"
  principal_id         = module.github_deployer.service_principal_id
}

# Outputs for GitHub Secrets configuration
output "github_secrets_instructions" {
  value = <<-EOT
    Add these secrets to your GitHub repository:
    
    AZURE_CLIENT_ID: ${module.github_deployer.application_id}
    AZURE_TENANT_ID: ${module.github_deployer.tenant_id}
    AZURE_SUBSCRIPTION_ID: ${data.azurerm_client_config.current.subscription_id}
    
    Then use in your workflow:
    
    - name: Azure Login
      uses: azure/login@v1
      with:
        client-id: $${{ secrets.AZURE_CLIENT_ID }}
        tenant-id: $${{ secrets.AZURE_TENANT_ID }}
        subscription-id: $${{ secrets.AZURE_SUBSCRIPTION_ID }}
  EOT
}

output "github_oidc_subject" {
  description = "GitHub OIDC subject claim"
  value       = module.github_deployer.github_oidc_subject
}

data "azurerm_client_config" "current" {}
