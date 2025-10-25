# Local variables

#
# ==================== STORAGE ACCOUNT ACCESS CONFIGURATION ====================
# Choose your access method based on your security requirements:
# 1. ip_whitelist - Simple but requires updating IPs
# 2. private_endpoint - Most secure, no internet exposure
# 3. managed_identity - Best for Azure resources (VMs, App Services)
#

# Network Rules for Storage Account
resource "azurerm_storage_account_network_rules" "tfstate" {
  storage_account_id = data.azurerm_storage_account.state_storage_account.id
  
  # Default action:
  # - "Deny" for security (only allowed sources can access)
  # - "Allow" temporarily during private endpoint setup
  default_action = var.storage_access_method == "private_endpoint" ? "Allow" : "Deny"
  
  # IP whitelist (only used when storage_access_method = "ip_whitelist")
  ip_rules = var.storage_access_method == "ip_whitelist" ? var.allowed_ip_addresses : []
  
  # Allow Azure services (needed for Terraform, Azure Portal, etc.)
  bypass = ["AzureServices"]
  
  # VNet subnet access (for private endpoints)
  virtual_network_subnet_ids = var.storage_access_method == "private_endpoint" ? [
    azurerm_subnet.private_endpoints.id
  ] : []
}

#
# ==================== PRIVATE ENDPOINT (For secure access with changing IPs) ====================
#

# Private DNS Zone for Storage Account Blob service
resource "azurerm_private_dns_zone" "storage_blob" {
  count               = var.storage_access_method == "private_endpoint" ? 1 : 0
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = data.azurerm_storage_account.state_storage_account.resource_group_name
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "storage_blob" {
  count                 = var.storage_access_method == "private_endpoint" ? 1 : 0
  name                  = "storage-blob-dns-link"
  resource_group_name   = data.azurerm_storage_account.state_storage_account.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage_blob[0].name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false
}

# Private Endpoint for Storage Account
resource "azurerm_private_endpoint" "storage" {
  count               = var.storage_access_method == "private_endpoint" ? 1 : 0
  name                = "pe-${data.azurerm_storage_account.state_storage_account.name}"
  location            = data.azurerm_storage_account.state_storage_account.location
  resource_group_name = data.azurerm_storage_account.state_storage_account.resource_group_name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "psc-${data.azurerm_storage_account.state_storage_account.name}"
    private_connection_resource_id = data.azurerm_storage_account.state_storage_account.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "storage-blob-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage_blob[0].id]
  }
}
