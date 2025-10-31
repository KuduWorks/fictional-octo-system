output "application_id" {
  description = "The Application (Client) ID"
  value       = azuread_application.app.client_id
}

output "application_object_id" {
  description = "The Object ID of the application"
  value       = azuread_application.app.object_id
}

output "service_principal_id" {
  description = "The Service Principal Object ID"
  value       = azuread_service_principal.app_sp.object_id
}

output "service_principal_app_id" {
  description = "The Service Principal Application ID"
  value       = azuread_service_principal.app_sp.client_id
}

output "client_secret" {
  description = "The client secret value (sensitive)"
  value       = azuread_application_password.app_secret.value
  sensitive   = true
}

output "client_secret_key_id" {
  description = "The key ID of the client secret"
  value       = azuread_application_password.app_secret.key_id
}

output "tenant_id" {
  description = "The Azure AD Tenant ID"
  value       = data.azuread_client_config.current.tenant_id
}

output "secret_rotation_date" {
  description = "Next secret rotation date"
  value       = time_rotating.secret_rotation.rotation_rfc3339
}

output "github_oidc_subject" {
  description = "GitHub OIDC subject format (if enabled)"
  value       = var.enable_github_oidc ? "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${var.github_branch}" : null
}

output "kubernetes_oidc_subject" {
  description = "Kubernetes OIDC subject format (if enabled)"
  value       = var.enable_kubernetes_oidc ? "system:serviceaccount:${var.kubernetes_namespace}:${var.kubernetes_service_account}" : null
}

output "key_vault_secret_names" {
  description = "Names of secrets stored in Key Vault (if enabled)"
  value = var.store_in_key_vault ? {
    client_id     = "${var.app_display_name}-client-id"
    client_secret = "${var.app_display_name}-client-secret"
    tenant_id     = "${var.app_display_name}-tenant-id"
  } : null
}
