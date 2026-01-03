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
    # Monitor all services on a monthly cycle
    calendar_period        = "MONTH"
    credit_types_treatment = "INCLUDE_ALL_CREDITS"
  }

  amount {
    specified_amount {
      currency_code = "EUR"
      units         = tostring(var.monthly_budget_amount)
    }
  }

  # Alert at 50%, 80%, and 100% of budget
  threshold_rules {
    threshold_percent = 0.5
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 0.8
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "CURRENT_SPEND"
  }

  # Email notifications
  all_updates_rule {
    monitoring_notification_channels = [
      for email in var.budget_alert_emails :
      google_monitoring_notification_channel.budget_email[email].id
    ]
    disable_default_iam_recipients = false
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

# Project budgets using for_each to eliminate code duplication
locals {
  # Define project configurations
  project_configs = {
    dev = {
      project_id    = var.dev_project_id
      budget_amount = var.dev_project_budget_amount
      require_positive_amount = true  # Dev budget requires amount > 0
    }
    prod = {
      project_id    = var.prod_project_id
      budget_amount = var.prod_project_budget_amount
      require_positive_amount = false  # Prod budget allows 0 amount
    }
  }

  # Filter to only include projects that meet their conditions
  project_budgets = {
    for env, config in local.project_configs : env => config
    if config.project_id != "" && var.billing_account_id != "" && 
       (!config.require_positive_amount || config.budget_amount > 0)
  }
}

resource "google_billing_budget" "project_budget" {
  for_each = local.project_budgets

  billing_account = var.billing_account_id
  display_name    = "${each.value.project_id}-budget"

  budget_filter {
    projects               = ["projects/${each.value.project_id}"]
    calendar_period        = "MONTH"
    credit_types_treatment = "INCLUDE_ALL_CREDITS"
  }

  amount {
    specified_amount {
      currency_code = "EUR"
      units         = tostring(each.value.budget_amount)
    }
  }

  # Alert at 50%, 80%, and 100% of budget
  threshold_rules {
    threshold_percent = 0.5
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 0.8
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "CURRENT_SPEND"
  }

  # Email notifications
  all_updates_rule {
    monitoring_notification_channels = [
      for email in var.budget_alert_emails :
      google_monitoring_notification_channel.budget_email[email].id
    ]
    disable_default_iam_recipients = false
  }

  depends_on = [google_project_service.cloudbilling]
}
