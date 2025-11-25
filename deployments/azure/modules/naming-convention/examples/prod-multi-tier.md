# Production Multi-Tier Application Example

This example shows how to use the naming convention module for a production environment with multiple tiers (web, app, data).

## Usage

```bash
cd examples/prod-multi-tier
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
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Naming convention for the application
module "naming" {
  source = "../../"
  
  workload    = "finops"
  environment = "prod"
  region      = "eastus"
  instance    = "01"
  
  additional_tags = {
    CostCenter    = "Finance"
    Owner         = "FinOps Team"
    Compliance    = "SOC2"
    BusinessUnit  = "Operations"
  }
}

# Separate naming for subnets
module "naming_web_subnet" {
  source = "../../"
  
  workload       = "finops"
  environment    = "prod"
  region         = "eastus"
  subnet_purpose = "web"
}

module "naming_app_subnet" {
  source = "../../"
  
  workload       = "finops"
  environment    = "prod"
  region         = "eastus"
  subnet_purpose = "app"
}

module "naming_data_subnet" {
  source = "../../"
  
  workload       = "finops"
  environment    = "prod"
  region         = "eastus"
  subnet_purpose = "data"
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = module.naming.resource_group_name
  location = var.region
  tags     = module.naming.common_tags
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = module.naming.virtual_network_name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = module.naming.common_tags
}

# Web Tier Subnet
resource "azurerm_subnet" "web" {
  name                 = module.naming_web_subnet.subnet_name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# App Tier Subnet
resource "azurerm_subnet" "app" {
  name                 = module.naming_app_subnet.subnet_name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Data Tier Subnet
resource "azurerm_subnet" "data" {
  name                 = module.naming_data_subnet.subnet_name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.3.0/24"]
}

# NSG for Web Tier
resource "azurerm_network_security_group" "web" {
  name                = "${module.naming.network_security_group_name}-web"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = module.naming.common_tags

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Key Vault for secrets
resource "azurerm_key_vault" "main" {
  name                       = module.naming.key_vault_name
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "premium"
  soft_delete_retention_days = 7
  purge_protection_enabled   = true
  tags                       = module.naming.common_tags

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Recover",
      "Backup",
      "Restore"
    ]
  }
}

# Generate random password for SQL Server
resource "random_password" "sql_admin" {
  length  = 24
  special = true
}

# Store SQL password in Key Vault
resource "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "sql-admin-password"
  value        = random_password.sql_admin.result
  key_vault_id = azurerm_key_vault.main.id
  
  depends_on = [azurerm_key_vault.main]
}

# SQL Server with AAD authentication (recommended for production)
resource "azurerm_mssql_server" "main" {
  name                         = module.naming.sql_server_name
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = random_password.sql_admin.result
  tags                         = module.naming.common_tags

  azuread_administrator {
    login_username = "AzureAD Admin"
    object_id      = data.azurerm_client_config.current.object_id
  }
}

# SQL Database
resource "azurerm_mssql_database" "main" {
  name      = module.naming.sql_database_name
  server_id = azurerm_mssql_server.main.id
  sku_name  = "S0"
  tags      = module.naming.common_tags
}

# Storage Account
resource "azurerm_storage_account" "main" {
  name                     = module.naming.storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  tags                     = module.naming.common_tags
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = module.naming.log_analytics_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 90
  tags                = module.naming.common_tags
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = module.naming.application_insights_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
  tags                = module.naming.common_tags
}

# Function App for processing
resource "azurerm_service_plan" "functions" {
  name                = "plan-${module.naming.function_app_name}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "Y1"
  tags                = module.naming.common_tags
}

resource "azurerm_linux_function_app" "main" {
  name                       = module.naming.function_app_name
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  service_plan_id            = azurerm_service_plan.functions.id
  storage_account_name       = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key
  tags                       = module.naming.common_tags

  site_config {
    application_insights_key = azurerm_application_insights.main.instrumentation_key
- Virtual Network: `vnet-finops-prod-eus`
}

data "azurerm_client_config" "current" {}

variable "region" {
  description = "Azure region"
  type        = string
  default     = "eastus"
- Storage Account: `stfinopsprodeus01`
- Log Analytics: `log-finops-prod-eus`
- Application Insights: `appi-finops-prod-eus`
- Function App: `func-finops-prod-eus-01`
  description = "All generated resource names"
  value = {
    resource_group      = azurerm_resource_group.main.name
    vnet                = azurerm_virtual_network.main.name
    subnet_web          = azurerm_subnet.web.name
    subnet_app          = azurerm_subnet.app.name
    subnet_data         = azurerm_subnet.data.name
    key_vault           = azurerm_key_vault.main.name
    sql_server          = azurerm_mssql_server.main.name
    sql_database        = azurerm_mssql_database.main.name
    storage_account     = azurerm_storage_account.main.name
    log_analytics       = azurerm_log_analytics_workspace.main.name
    application_insights = azurerm_application_insights.main.name
    function_app        = azurerm_linux_function_app.main.name
  }
}

output "tags" {
  description = "Common tags"
  value       = module.naming.common_tags
}
```

## Expected Resource Names

- Resource Group: `rg-finops-prod-eus`
- Virtual Network: `vnet-finops-prod-eus-01`
- Subnets:
  - `snet-finops-web`
  - `snet-finops-app`
  - `snet-finops-data`
- Network Security Group: `nsg-finops-prod-eus-web`
- Key Vault: `kv-finops-prod-eus-01`
- SQL Server: `sql-finops-prod-eus-01`
- SQL Database: `sqldb-finops-prod`
- Storage Account: `stfinopsprodeus001`
- Log Analytics: `log-monitoring-prod-eus`
- Application Insights: `appi-monitoring-prod-eus`
- Function App: `func-processor-prod-eus-01`

## Notes

- This example demonstrates production-grade resource naming
- Uses separate naming module instances for subnet naming with different purposes
- Includes monitoring and observability resources (Log Analytics, Application Insights)
- Shows how to extend base names (e.g., `${module.naming.network_security_group_name}-web`)
- **Security best practices:**
  - SQL password generated randomly and stored in Key Vault
  - AAD authentication configured for SQL Server
  - Key Vault access policy configured for current user
  - No hardcoded credentials in code
