output "project_id" {
  description = "GCP Project ID"
  value       = local.project_id
}

output "billing_account_id" {
  description = "Billing account ID (if configured)"
  value       = var.billing_account_id
}

output "monthly_budget_id" {
  description = "Monthly budget ID"
  value       = var.billing_account_id != "" ? google_billing_budget.monthly_budget[0].name : null
}

output "monthly_budget_amount" {
  description = "Monthly budget amount in USD"
  value       = var.monthly_budget_amount
}

output "budget_alert_emails" {
  description = "Email addresses receiving budget alerts"
  value       = var.budget_alert_emails
}

output "notification_channels" {
  description = "Monitoring notification channels for budget alerts"
  value = {
    for email, channel in google_monitoring_notification_channel.budget_email :
    email => channel.id
  }
}

output "budget_summary" {
  description = "Summary of configured budgets"
  value = var.billing_account_id != "" ? {
    monthly_budget = {
      name   = google_billing_budget.monthly_budget[0].display_name
      amount = var.monthly_budget_amount
      alerts = "50%, 75%, 90%, 100% (current), 100% (forecast)"
      scope  = "All services across the entire project"
    }
  } : null
}

output "setup_instructions" {
  description = "Instructions for viewing and managing budgets"
  value       = <<-EOT
    
    Budget Setup Complete! 🎉
    
    To view your budget:
    1. Web Console: https://console.cloud.google.com/billing/budgets
    2. CLI: gcloud billing budgets list --billing-account=${var.billing_account_id}
    
    Budget Configuration:
    - Monthly Budget: $${var.monthly_budget_amount}
    - Scope: All services across the entire project
    
    Alert Thresholds:
    - 50%, 75%, 90%, 100% (actual spend)
    - 100% (forecasted spend)
    
    Email Notifications: ${length(var.budget_alert_emails)} recipient(s)
    ${length(var.budget_alert_emails) > 0 ? "- ${join("\n    - ", var.budget_alert_emails)}" : "⚠️  No email alerts configured!"}
    
    To modify budget:
    - Update terraform.tfvars and run: terraform apply
    - Adjust monthly_budget_amount to change spending limit
    - Add more email addresses to budget_alert_emails
    
  EOT
}
