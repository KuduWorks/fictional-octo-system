output "key_vault_id" {
  description = "The ID of the Key Vault."
  value       = azurerm_key_vault.main.id
}

output "key_vault_name" {
  description = "The name of the Key Vault."
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "The URI of the Key Vault."
  value       = azurerm_key_vault.main.vault_uri
}

output "key_vault_resource_group_name" {
  description = "The name of the resource group containing the Key Vault."
  value       = local.resource_group_name
}

output "key_vault_location" {
  description = "The Azure region where the Key Vault is deployed."
  value       = azurerm_key_vault.main.location
}

output "key_vault_tenant_id" {
  description = "The Azure AD tenant ID for the Key Vault."
  value       = azurerm_key_vault.main.tenant_id
}

output "rbac_authorization_enabled" {
  description = "Whether RBAC authorization is enabled for the Key Vault."
  value       = azurerm_key_vault.main.enable_rbac_authorization
}

output "purge_protection_enabled" {
  description = "Whether purge protection is enabled."
  value       = azurerm_key_vault.main.purge_protection_enabled
}

output "soft_delete_retention_days" {
  description = "The number of days items are retained after soft deletion."
  value       = azurerm_key_vault.main.soft_delete_retention_days
}

output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics workspace (if diagnostics enabled)."
  value       = var.enable_diagnostics ? azurerm_log_analytics_workspace.kv[0].id : null
}

output "private_endpoint_id" {
  description = "The ID of the private endpoint (if enabled)."
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.kv[0].id : null
}

output "private_endpoint_ip" {
  description = "The private IP address of the Key Vault private endpoint (if enabled)."
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.kv[0].private_service_connection[0].private_ip_address : null
}

# Role assignment information
output "role_assignments_created" {
  description = "Summary of role assignments created."
  value = {
    deployer_admin       = var.assign_deployer_admin ? "Key Vault Administrator" : "Not assigned"
    secrets_officers     = length(var.secrets_officer_principal_ids)
    secrets_users        = length(var.secrets_user_principal_ids)
    crypto_officers      = length(var.crypto_officer_principal_ids)
    crypto_users         = length(var.crypto_user_principal_ids)
    certificate_officers = length(var.certificate_officer_principal_ids)
    certificate_users    = length(var.certificate_user_principal_ids)
    readers              = length(var.reader_principal_ids)
    custom_roles         = length(var.custom_role_assignments)
  }
}

# Useful commands for users
output "useful_commands" {
  description = "Useful Azure CLI commands for managing this Key Vault."
  value       = <<-EOT
    # List all secrets
    az keyvault secret list --vault-name ${azurerm_key_vault.main.name}
    
    # Set a secret
    az keyvault secret set --vault-name ${azurerm_key_vault.main.name} --name "my-secret" --value "my-value"
    
    # Get a secret
    az keyvault secret show --vault-name ${azurerm_key_vault.main.name} --name "my-secret"
    
    # List RBAC role assignments
    az role assignment list --scope ${azurerm_key_vault.main.id}
    
    # Assign a role (example: Secrets User)
    az role assignment create \
      --role "Key Vault Secrets User" \
      --assignee <user-or-sp-object-id> \
      --scope ${azurerm_key_vault.main.id}
  EOT
}
