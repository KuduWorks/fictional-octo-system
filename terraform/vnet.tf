resource "azurerm_virtual_network" "main" {
  name                = "vnet-dev-01"
  location            = var.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = var.vnet_address_space

  subnet {
    name           = "subnet-dev-01"
    address_prefix = var.subnet_prefix
  }

  tags = var.tags
}