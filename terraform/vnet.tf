resource "azurerm_virtual_network" "main" {
  name     = "vnet-main"
  location = var.location
  # References the name attribute from the azurerm_resource_group.main resource
  resource_group_name = azurerm_resource_group.main.name
  address_space       = var.vnet_address_space

  subnet {
    name           = "subnet-main"
    address_prefix = var.subnet_prefix
  }

  tags = var.tags
}