resource "azurerm_virtual_network" "main" {
  name                = "vnet-main"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = var.vnet_address_space

  tags = var.tags
}

resource "azurerm_subnet" "main" {
  name                 = "subnet-main"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_prefix]
}

# Subnet for Private Endpoints
resource "azurerm_subnet" "private_endpoints" {
  name                 = "subnet-private-endpoints"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.private_endpoints_subnet_prefix]
}
