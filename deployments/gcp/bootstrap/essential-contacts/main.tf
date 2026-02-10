# Enable Essential Contacts API
resource "google_project_service" "essential_contacts_api" {
  project = var.project_id
  service = "essentialcontacts.googleapis.com"

  disable_on_destroy = false
}

# ==============================================================================
# SECURITY CONTACT
# ==============================================================================
# Receives security-related and technical notifications
# Categories: SECURITY, TECHNICAL
# Examples: Security incidents, vulnerability alerts, technical issues

resource "google_essential_contacts_contact" "security" {
  parent                              = "organizations/${var.organization_id}"
  email                               = var.security_contact_email
  language_tag                        = var.language_code
  notification_category_subscriptions = ["SECURITY", "TECHNICAL"]

  depends_on = [google_project_service.essential_contacts_api]
}

# ==============================================================================
# BILLING CONTACT
# ==============================================================================
# Receives billing-related notifications
# Categories: BILLING
# Examples: Billing anomalies, budget alerts, payment issues

resource "google_essential_contacts_contact" "billing" {
  parent                              = "organizations/${var.organization_id}"
  email                               = var.billing_contact_email
  language_tag                        = var.language_code
  notification_category_subscriptions = ["BILLING"]

  depends_on = [google_project_service.essential_contacts_api]
}

# ==============================================================================
# MONITORING CONTACT
# ==============================================================================
# Receives operational and service suspension notifications
# Categories: TECHNICAL, SUSPENSION
# Examples: Service suspensions, technical issues, operational alerts

resource "google_essential_contacts_contact" "monitoring" {
  parent                              = "organizations/${var.organization_id}"
  email                               = var.monitoring_contact_email
  language_tag                        = var.language_code
  notification_category_subscriptions = ["TECHNICAL", "SUSPENSION"]

  depends_on = [google_project_service.essential_contacts_api]
}
