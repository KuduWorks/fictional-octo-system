output "application_id" {
  description = "Application (client) ID of the placeholder application"
  value       = azuread_application.placeholder.client_id
}

output "application_object_id" {
  description = "Object ID of the placeholder application"
  value       = azuread_application.placeholder.object_id
}

output "service_principal_id" {
  description = "Object ID of the placeholder service principal (use this for app_owners)"
  value       = azuread_service_principal.placeholder.id
}

output "service_principal_object_id" {
  description = "Object ID of the placeholder service principal"
  value       = azuread_service_principal.placeholder.object_id
}

output "display_name" {
  description = "Display name of the placeholder"
  value       = azuread_application.placeholder.display_name
}

output "justification" {
  description = "Justification for placeholder (stored for audit trail)"
  value       = var.justification
  sensitive   = false  # Justifications are audit trail, not sensitive credentials
}

output "created_date" {
  description = "Timestamp when placeholder was created (for quarterly review tracking)"
  value       = azuread_application.placeholder.created_date
}

output "notes" {
  description = "Full audit trail stored in application notes"
  value       = azuread_application.placeholder_with_notes.notes
  sensitive   = false
}
