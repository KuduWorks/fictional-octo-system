# Monitoring for Policy Exemption Expirations
# Alerts 60 days before exemptions expire

# Resource group for monitoring resources
resource "azurerm_resource_group" "monitoring" {
  count    = length(var.exempted_resources) > 0 ? 1 : 0
  name     = var.monitoring_resource_group_name
  location = var.monitoring_location

  tags = {
    Purpose     = "Policy Exemption Monitoring"
    ManagedBy   = "Terraform"
    Environment = "Production"
  }
}

# Log Analytics Workspace for query execution
resource "azurerm_log_analytics_workspace" "policy_monitoring" {
  count               = length(var.exempted_resources) > 0 ? 1 : 0
  name                = "law-policy-monitoring"
  location            = azurerm_resource_group.monitoring[0].location
  resource_group_name = azurerm_resource_group.monitoring[0].name
  sku                 = "PerGB2018"
  retention_in_days   = 90

  tags = {
    Purpose   = "Policy Exemption Monitoring"
    ManagedBy = "Terraform"
  }
}

# Action Group for email notifications
resource "azurerm_monitor_action_group" "exemption_expiry" {
  count               = length(var.exempted_resources) > 0 ? 1 : 0
  name                = "ag-exemption-expiry-alerts"
  resource_group_name = azurerm_resource_group.monitoring[0].name
  short_name          = "ExemptExpiry"

  email_receiver {
    name          = "Security Team"
    email_address = var.alert_email
  }

  tags = {
    Purpose   = "Policy Exemption Expiration Alerts"
    ManagedBy = "Terraform"
  }
}

# Scheduled Query Rule to check exemptions expiring within 60 days
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "exemption_expiry" {
  count               = length(var.exempted_resources) > 0 ? 1 : 0
  name                = "alert-exemption-expiring-soon"
  resource_group_name = azurerm_resource_group.monitoring[0].name
  location            = azurerm_resource_group.monitoring[0].location

  evaluation_frequency = "P1D" # Daily
  window_duration      = "P1D"
  scopes               = [azurerm_log_analytics_workspace.policy_monitoring[0].id]
  severity             = 2 # Warning

  criteria {
    query                   = <<-QUERY
      PolicyResources
      | where type == "microsoft.authorization/policyexemptions"
      | where properties.expiryTime != ""
      | extend expiryDate = todatetime(properties.expiryTime)
      | extend daysUntilExpiry = datetime_diff('day', expiryDate, now())
      | where daysUntilExpiry <= 60 and daysUntilExpiry >= 0
      | project name, resourceGroup, expiryDate, daysUntilExpiry, properties.displayName, properties.exemptionCategory
    QUERY
    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  auto_mitigation_enabled          = false
  workspace_alerts_storage_enabled = false
  description                      = "Alerts when policy exemptions are expiring within 60 days"
  display_name                     = "Policy Exemption Expiring Soon"
  enabled                          = true

  action {
    action_groups = [azurerm_monitor_action_group.exemption_expiry[0].id]
  }

  tags = {
    Purpose   = "Policy Exemption Expiration Monitoring"
    ManagedBy = "Terraform"
  }
}
