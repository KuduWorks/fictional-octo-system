# Storage Account Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "storage" {
  name                       = "storage-diagnostics"
  target_resource_id         = data.azurerm_storage_account.state_storage_account.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  metric {
    category = "Transaction"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }

  metric {
    category = "Capacity"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }

  # Add dependency on network rules
  depends_on = [azurerm_storage_account_network_rules.tfstate]
}

# Storage Management Policy for Retention
resource "azurerm_storage_management_policy" "retention" {
  storage_account_id = data.azurerm_storage_account.state_storage_account.id

  rule {
    name    = "retention"
    enabled = true
    filters {
      blob_types = ["blockBlob"]
    }
    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = 30
      }
    }
  }
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-tfstate-monitoring"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags

  depends_on = [azurerm_resource_group.main]
}

# Alert for Storage Account Availability
resource "azurerm_monitor_metric_alert" "storage_availability" {
  name                = "storage-availability-alert"
  resource_group_name = var.resource_group_name
  scopes              = [data.azurerm_storage_account.state_storage_account.id]
  description         = "Alert when storage account availability drops below 99.9%"

  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts"
    metric_name      = "Availability"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 99.9
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}

# Action Group for Alerts
resource "azurerm_monitor_action_group" "main" {
  name                = "ag-storage-alerts"
  resource_group_name = var.resource_group_name
  short_name          = "storage-ag"

  email_receiver {
    name          = "admin"
    email_address = var.alert_email
  }

  depends_on = [azurerm_resource_group.main]
}