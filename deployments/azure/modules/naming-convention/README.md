# Azure Naming Convention Module

This Terraform module generates consistent, Azure-compliant resource names following organizational naming standards.

## Features

- **Consistent naming** across all Azure resources
- **Region abbreviations** (3 characters) for compact names
- **Environment-based** naming (dev, test, stage, prod)
- **Azure compliance** - respects character limits and allowed characters for each resource type
- **Automatic sanitization** for resources with strict naming rules (e.g., Storage Accounts)
- **Common tags** generated automatically

## Naming Pattern

```
{resource_type}-{workload}-{environment}-{region}-{instance}
```

### Examples:
- Storage Account: `stfinopsprodeus001` (sanitized, no hyphens)
- Virtual Machine: `vm-webapp-dev-weu-01`
- Virtual Network: `vnet-core-prod-neu`
- Key Vault: `kv-secrets-prod-uks-01` (max 24 chars)

## Usage

```hcl
module "naming" {
  source = "./modules/naming-convention"
  
  workload    = "finops"
  environment = "prod"
  region      = "eastus"
  instance    = "01"
  
  subnet_purpose = "web"  # Optional, for subnet naming
  
  additional_tags = {
    CostCenter = "Engineering"
    Owner      = "Platform Team"
  }
}

# Use the generated names
resource "azurerm_resource_group" "example" {
  name     = module.naming.resource_group_name
  location = "eastus"
  tags     = module.naming.common_tags
}

resource "azurerm_storage_account" "example" {
  name                     = module.naming.storage_account_name
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = module.naming.common_tags
}
```

## Supported Resource Types

| Resource Type | Abbreviation | Example Output |
|--------------|--------------|----------------|
| Storage Account | `st` | `stfinopsprodeus001` |
| Virtual Machine | `vm` | `vm-webapp-dev-weu-01` |
| Virtual Network | `vnet` | `vnet-core-prod-neu` |
| Subnet | `snet` | `snet-webapp-web` |
| Network Interface | `nic` | `nic-webapp-dev-weu-01` |
| Public IP | `pip` | `pip-webapp-dev-weu-01` |
| Network Security Group | `nsg` | `nsg-webapp-dev-weu` |
| Resource Group | `rg` | `rg-webapp-dev-weu` |
| Key Vault | `kv` | `kv-secrets-prod-uks-01` |
| App Service | `app` | `app-api-prod-eus-01` |
| Function App | `func` | `func-processor-prod-eus-01` |
| Container Instance | `aci` | `aci-worker-prod-eus-01` |
| AKS Cluster | `aks` | `aks-platform-prod-neu` |
| Cosmos DB | `cosmos` | `cosmos-data-prod-eus-01` |
| SQL Server | `sql` | `sql-app-prod-eus-01` |
| SQL Database | `sqldb` | `sqldb-webapp-prod` |
| Log Analytics | `log` | `log-monitoring-prod-eus` |
| Application Insights | `appi` | `appi-monitoring-prod-eus` |

## Region Codes (3-char)

### North America
- `eastus` → `eus`
- `eastus2` → `eu2`
- `westus` → `wus`
- `centralus` → `cus`
- `canadacentral` → `cac`

### Europe
- `northeurope` → `neu`
- `westeurope` → `weu`
- `uksouth` → `uks`
- `francecentral` → `frc`
- `germanywestcentral` → `gwc`
- `swedencentral` → `swe`

### Asia Pacific
- `southeastasia` → `sea`
- `eastasia` → `eas`
- `australiaeast` → `aue`
- `japaneast` → `jpe`
- `koreacentral` → `koc`
- `centralindia` → `cin`

(See `main.tf` for complete list)

## Variables

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| `workload` | Workload/application name (2-10 chars, lowercase alphanumeric) | `string` | Yes | - |
| `environment` | Environment (dev, test, stage, prod) | `string` | Yes | - |
| `region` | Azure region | `string` | Yes | - |
| `instance` | Instance number (1-3 digits) | `string` | No | `"01"` |
| `subnet_purpose` | Subnet purpose (e.g., web, db, app) | `string` | No | `"default"` |
| `additional_tags` | Additional tags to merge | `map(string)` | No | `{}` |

## Outputs

All resource names are available as outputs:
- `storage_account_name`
- `virtual_machine_name`
- `virtual_network_name`
- `subnet_name`
- `network_interface_name`
- `public_ip_name`
- `network_security_group_name`
- `resource_group_name`
- `key_vault_name`
- `app_service_name`
- `function_app_name`
- `container_instance_name`
- `aks_name`
- `cosmos_db_name`
- `sql_server_name`
- `sql_database_name`
- `log_analytics_name`
- `application_insights_name`
- `common_tags`
- `region_code`

## Azure Naming Rules

This module automatically enforces Azure naming rules:

- **Storage Accounts**: 3-24 characters, lowercase letters and numbers only
- **Key Vaults**: 3-24 characters, alphanumeric and hyphens
- **Virtual Machines**: 1-15 characters (Windows), 1-64 (Linux)
- **Most Resources**: 2-64 characters, alphanumeric and hyphens

## Notes

- All names are deterministic - same inputs always produce same outputs
- Storage account names are automatically sanitized (hyphens removed, lowercase)
- Key Vault names are truncated to 24 characters if needed
- Common tags include: Environment, Region, Workload, ManagedBy, CreatedDate
