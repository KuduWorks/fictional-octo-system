resource "azurerm_virtual_network" "main" {
  name                = "vnet-dev-01"
  location            = var.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.0.0.0/16"]

  subnet {
    name           = "subnet-dev-01"
    address_prefix = "10.0.1.0/24"
  }

  tags = var.tags
}