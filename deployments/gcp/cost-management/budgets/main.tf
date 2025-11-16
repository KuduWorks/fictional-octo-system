terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project               = var.project_id
  region                = var.gcp_region
  user_project_override = true
  billing_project       = var.project_id

  default_labels = {
    environment = var.environment
    managed_by  = "terraform"
    module      = "budgets"
    purpose     = "cost-management"
  }
}

# Get current project information
data "google_project" "current" {
  project_id = var.project_id
}

locals {
  project_id = var.project_id != "" ? var.project_id : data.google_project.current.project_id
}

# Enable Cloud Billing Budget API
resource "google_project_service" "cloudbilling" {
  project = local.project_id
  service = "cloudbilling.googleapis.com"

  disable_on_destroy = false
}

# Get billing account information
data "google_billing_account" "account" {
  count           = var.billing_account_id != "" ? 1 : 0
  billing_account = var.billing_account_id
}

# Main monthly budget with multiple alert thresholds
resource "google_billing_budget" "monthly_budget" {
  count = var.billing_account_id != "" ? 1 : 0

  billing_account = var.billing_account_id
  display_name    = "${var.environment}-monthly-budget"

  budget_filter {
    projects = ["kudu-star-dev-01"]  # Use project ID, not "projects/..." format

    # Monitor all services
    services = []

    # Monitor all credit types
    credit_types_treatment = "INCLUDE_ALL_CREDITS"
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = tostring(var.monthly_budget_amount)
    }
  }

  # Alert at 50%, 75%, 90%, and 100% of budget
  threshold_rules {
    threshold_percent = 0.5
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 0.75
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 0.9
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "CURRENT_SPEND"
  }

  # Forecasted spend alert at 100%
  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "FORECASTED_SPEND"
  }

  # Email notifications
  dynamic "all_updates_rule" {
    for_each = length(var.budget_alert_emails) > 0 ? [1] : []
    content {
      monitoring_notification_channels = [
        for email in var.budget_alert_emails :
        google_monitoring_notification_channel.budget_email[email].id
      ]
      disable_default_iam_recipients = false
    }
  }

  depends_on = [google_project_service.cloudbilling]
}

# Compute Engine specific budget
resource "google_billing_budget" "compute_budget" {
  count = var.billing_account_id != "" ? 1 : 0

  billing_account = var.billing_account_id
  display_name    = "${var.environment}-compute-budget"

  budget_filter {
    projects = ["kudu-star-dev-01"]  # Use project ID, not "projects/..." format

    # Monitor only Compute Engine
    services = ["services/6F81-5844-456A"] # Compute Engine service ID
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = tostring(var.monthly_budget_amount * 0.5) # 50% of total budget
    }
  }

  threshold_rules {
    threshold_percent = 0.8
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "CURRENT_SPEND"
  }

  dynamic "all_updates_rule" {
    for_each = length(var.budget_alert_emails) > 0 ? [1] : []
    content {
      monitoring_notification_channels = [
        for email in var.budget_alert_emails :
        google_monitoring_notification_channel.budget_email[email].id
      ]
    }
  }

  depends_on = [google_project_service.cloudbilling]
}

# Storage budget
resource "google_billing_budget" "storage_budget" {
  count = var.billing_account_id != "" ? 1 : 0

  billing_account = var.billing_account_id
  display_name    = "${var.environment}-storage-budget"

  budget_filter {
    projects = ["kudu-star-dev-01"]  # Use project ID, not "projects/..." format

    # Monitor Cloud Storage
    services = ["services/95FF-2EF5-5EA1"] # Cloud Storage service ID
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = tostring(var.monthly_budget_amount * 0.2) # 20% of total budget
    }
  }

  threshold_rules {
    threshold_percent = 0.8
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "CURRENT_SPEND"
  }

  dynamic "all_updates_rule" {
    for_each = length(var.budget_alert_emails) > 0 ? [1] : []
    content {
      monitoring_notification_channels = [
        for email in var.budget_alert_emails :
        google_monitoring_notification_channel.budget_email[email].id
      ]
    }
  }

  depends_on = [google_project_service.cloudbilling]
}

# Notification channels for email alerts
resource "google_monitoring_notification_channel" "budget_email" {
  for_each = toset(var.budget_alert_emails)

  project      = local.project_id
  display_name = "Budget Alert - ${each.value}"
  type         = "email"

  labels = {
    email_address = each.value
  }

  enabled = true
}