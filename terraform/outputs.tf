# Output the client ID for GitHub Actions configuration
output "github_terraform_client_id" {
  description = "Client ID of the User-Assigned Managed Identity for GitHub Actions. Add this to GitHub environment secret AZURE_CLIENT_ID."
  value       = azurerm_user_assigned_identity.github_terraform.client_id
  sensitive   = false
}

output "github_terraform_principal_id" {
  description = "Principal ID of the User-Assigned Managed Identity"
  value       = azurerm_user_assigned_identity.github_terraform.principal_id
  sensitive   = true
}
