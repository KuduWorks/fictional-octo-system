# Multiple Instances Example

This example demonstrates using the naming convention module to create multiple instances of the same resource type in different regions or with different instance numbers.

## Usage

```bash
cd examples/multiple-instances
terraform init
terraform plan
```

## Configuration

```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Primary region - Instance 01
module "naming_primary" {
  source = "../../"
  
  workload    = "api"
  environment = "prod"
  region      = "eastus"
  instance    = "01"
  
  additional_tags = {
    Region = "Primary"
  }
}

# Primary region - Instance 02
module "naming_primary_02" {
  source = "../../"
  
  workload    = "api"
  environment = "prod"
  region      = "eastus"
  instance    = "02"
  
  additional_tags = {
    Region = "Primary"
  }
}

# Secondary region - Instance 01
module "naming_secondary" {
  source = "../../"
  
  workload    = "api"
  environment = "prod"
  region      = "westeurope"
  instance    = "01"
  
  additional_tags = {
    Region = "Secondary"
  }
}

# Primary region resources
resource "azurerm_resource_group" "primary" {
  name     = module.naming_primary.resource_group_name
  location = "eastus"
  tags     = module.naming_primary.common_tags
}

resource "azurerm_virtual_machine" "primary_01" {
  name                  = module.naming_primary.virtual_machine_name
  location              = azurerm_resource_group.primary.location
  resource_group_name   = azurerm_resource_group.primary.name
  vm_size               = "Standard_D2s_v3"
  tags                  = module.naming_primary.common_tags
  
  # ... VM configuration omitted for brevity
}

resource "azurerm_virtual_machine" "primary_02" {
  name                  = module.naming_primary_02.virtual_machine_name
  location              = azurerm_resource_group.primary.location
  resource_group_name   = azurerm_resource_group.primary.name
  vm_size               = "Standard_D2s_v3"
  tags                  = module.naming_primary_02.common_tags
  
  # ... VM configuration omitted for brevity
}

# Secondary region resources
resource "azurerm_resource_group" "secondary" {
  name     = module.naming_secondary.resource_group_name
  location = "westeurope"
  tags     = module.naming_secondary.common_tags
}

resource "azurerm_virtual_machine" "secondary" {
  name                  = module.naming_secondary.virtual_machine_name
  location              = azurerm_resource_group.secondary.location
  resource_group_name   = azurerm_resource_group.secondary.name
  vm_size               = "Standard_D2s_v3"
  tags                  = module.naming_secondary.common_tags
  
  # ... VM configuration omitted for brevity
}

# Storage accounts in multiple regions
resource "azurerm_storage_account" "primary" {
  name                     = module.naming_primary.storage_account_name
  resource_group_name      = azurerm_resource_group.primary.name
  location                 = azurerm_resource_group.primary.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = module.naming_primary.common_tags
}

resource "azurerm_storage_account" "secondary" {
  name                     = module.naming_secondary.storage_account_name
  resource_group_name      = azurerm_resource_group.secondary.name
  location                 = azurerm_resource_group.secondary.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = module.naming_secondary.common_tags
}

# Outputs
output "primary_resources" {
  description = "Primary region resource names"
  value = {
    resource_group  = azurerm_resource_group.primary.name
    vm_01           = azurerm_virtual_machine.primary_01.name
    vm_02           = azurerm_virtual_machine.primary_02.name
    storage_account = azurerm_storage_account.primary.name
  }
}

output "secondary_resources" {
  description = "Secondary region resource names"
  value = {
    resource_group  = azurerm_resource_group.secondary.name
    vm              = azurerm_virtual_machine.secondary.name
    storage_account = azurerm_storage_account.secondary.name
  }
}
```

## Expected Resource Names

### Primary Region (East US)
- Resource Group: `rg-api-prod-eus`
- Virtual Machine 01: `vm-api-prod-eus-01`
- Virtual Machine 02: `vm-api-prod-eus-02`
- Storage Account: `stapiprodeus01`

### Secondary Region (West Europe)
- Resource Group: `rg-api-prod-weu`
- Virtual Machine: `vm-api-prod-weu-01`
- Storage Account: `stapiprodweu01`

## Use Cases

This pattern is useful for:
- **Multi-region deployments** for high availability
- **Scale-out scenarios** with multiple instances in the same region
- **Blue-green deployments** using different instance numbers
- **Geographic distribution** for global applications

## Notes

- Each module instance generates independent names
- Instance numbers provide unique identifiers within the same region/environment
- Region codes automatically differentiate resources across regions
- Tags can be customized per module instance for additional metadata
