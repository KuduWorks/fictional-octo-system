output "organization_id" {
  description = "GCP Organization ID where contacts are configured"
  value       = var.organization_id
}

output "security_contact" {
  description = "Security contact configuration"
  value = {
    email      = google_essential_contacts_contact.security.email
    categories = google_essential_contacts_contact.security.notification_category_subscriptions
    id         = google_essential_contacts_contact.security.id
  }
}

output "billing_contact" {
  description = "Billing contact configuration"
  value = {
    email      = google_essential_contacts_contact.billing.email
    categories = google_essential_contacts_contact.billing.notification_category_subscriptions
    id         = google_essential_contacts_contact.billing.id
  }
}

output "monitoring_contact" {
  description = "Monitoring contact configuration"
  value = {
    email      = google_essential_contacts_contact.monitoring.email
    categories = google_essential_contacts_contact.monitoring.notification_category_subscriptions
    id         = google_essential_contacts_contact.monitoring.id
  }
}

output "essential_contacts_api_enabled" {
  description = "Essential Contacts API enablement status"
  value       = google_project_service.essential_contacts_api.service
}

output "contacts_summary" {
  description = "Summary of all configured essential contacts"
  value       = <<-EOT
  
  ====================================================================
  GCP ESSENTIAL CONTACTS CONFIGURED
  ====================================================================
  
  Organization ID: ${var.organization_id}
  
  Security Contact (SECURITY, TECHNICAL):
    - Email: ${google_essential_contacts_contact.security.email}
    - ID: ${google_essential_contacts_contact.security.id}
  
  Billing Contact (BILLING):
    - Email: ${google_essential_contacts_contact.billing.email}
    - ID: ${google_essential_contacts_contact.billing.id}
  
  Monitoring Contact (TECHNICAL, SUSPENSION):
    - Email: ${google_essential_contacts_contact.monitoring.email}
    - ID: ${google_essential_contacts_contact.monitoring.id}
  
  ====================================================================
  NEXT STEPS
  ====================================================================
  1. Verify contacts received confirmation emails
  2. Test notifications by triggering a test alert
  3. Deploy organization policies module next
  4. Set up service account key audit automation
  
  ====================================================================
  EOT
}
