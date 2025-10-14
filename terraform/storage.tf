# Local variables

# Network Rules for Storage Account
resource "azurerm_storage_account_network_rules" "tfstate" {
  storage_account_id = data.azurerm_storage_account.state_storage_account.id
  default_action     = "Deny"
  ip_rules           = var.allowed_ip_addresses
  bypass             = ["AzureServices"]
}