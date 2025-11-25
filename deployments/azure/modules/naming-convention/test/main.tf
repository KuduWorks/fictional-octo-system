terraform {
  required_version = ">= 1.0"
}

# Test the naming convention module with various inputs
module "test_dev_eastus" {
  source = "../"
  
  workload    = "testapp"
  environment = "dev"
  region      = "eastus"
  instance    = "01"
  
  subnet_purpose = "web"
  
  additional_tags = {
    TestRun = "validation"
    Owner   = "DevOps"
  }
}

module "test_prod_westeurope" {
  source = "../"
  
  workload    = "api"
  environment = "prod"
  region      = "westeurope"
  instance    = "99"
  
  subnet_purpose = "data"
  
  additional_tags = {
    CostCenter = "Engineering"
    Compliance = "SOC2"
  }
}

module "test_stage_northeurope" {
  source = "../"
  
  workload    = "finops"
  environment = "stage"
  region      = "northeurope"
  instance    = "05"
}

# Output all generated names for verification
output "dev_eastus_names" {
  description = "All names generated for dev environment in East US"
  value = {
    storage_account        = module.test_dev_eastus.storage_account_name
    virtual_machine        = module.test_dev_eastus.virtual_machine_name
    virtual_network        = module.test_dev_eastus.virtual_network_name
    subnet                 = module.test_dev_eastus.subnet_name
    network_interface      = module.test_dev_eastus.network_interface_name
    public_ip              = module.test_dev_eastus.public_ip_name
    network_security_group = module.test_dev_eastus.network_security_group_name
    resource_group         = module.test_dev_eastus.resource_group_name
    key_vault              = module.test_dev_eastus.key_vault_name
    app_service            = module.test_dev_eastus.app_service_name
    function_app           = module.test_dev_eastus.function_app_name
    container_instance     = module.test_dev_eastus.container_instance_name
    aks                    = module.test_dev_eastus.aks_name
    cosmos_db              = module.test_dev_eastus.cosmos_db_name
    sql_server             = module.test_dev_eastus.sql_server_name
    sql_database           = module.test_dev_eastus.sql_database_name
    log_analytics          = module.test_dev_eastus.log_analytics_name
    application_insights   = module.test_dev_eastus.application_insights_name
    region_code            = module.test_dev_eastus.region_code
  }
}

output "prod_westeurope_names" {
  description = "All names generated for prod environment in West Europe"
  value = {
    storage_account        = module.test_prod_westeurope.storage_account_name
    virtual_machine        = module.test_prod_westeurope.virtual_machine_name
    virtual_network        = module.test_prod_westeurope.virtual_network_name
    subnet                 = module.test_prod_westeurope.subnet_name
    network_interface      = module.test_prod_westeurope.network_interface_name
    public_ip              = module.test_prod_westeurope.public_ip_name
    network_security_group = module.test_prod_westeurope.network_security_group_name
    resource_group         = module.test_prod_westeurope.resource_group_name
    key_vault              = module.test_prod_westeurope.key_vault_name
    app_service            = module.test_prod_westeurope.app_service_name
    function_app           = module.test_prod_westeurope.function_app_name
    container_instance     = module.test_prod_westeurope.container_instance_name
    aks                    = module.test_prod_westeurope.aks_name
    cosmos_db              = module.test_prod_westeurope.cosmos_db_name
    sql_server             = module.test_prod_westeurope.sql_server_name
    sql_database           = module.test_prod_westeurope.sql_database_name
    log_analytics          = module.test_prod_westeurope.log_analytics_name
    application_insights   = module.test_prod_westeurope.application_insights_name
    region_code            = module.test_prod_westeurope.region_code
  }
}

output "stage_northeurope_names" {
  description = "All names generated for stage environment in North Europe"
  value = {
    storage_account        = module.test_stage_northeurope.storage_account_name
    virtual_machine        = module.test_stage_northeurope.virtual_machine_name
    virtual_network        = module.test_stage_northeurope.virtual_network_name
    resource_group         = module.test_stage_northeurope.resource_group_name
    key_vault              = module.test_stage_northeurope.key_vault_name
    region_code            = module.test_stage_northeurope.region_code
  }
}

output "dev_tags" {
  description = "Tags for dev environment"
  value       = module.test_dev_eastus.common_tags
}

output "prod_tags" {
  description = "Tags for prod environment"
  value       = module.test_prod_westeurope.common_tags
}

# Validation checks
output "validation_checks" {
  description = "Validation checks for naming rules"
  value = {
    storage_account_length_dev  = length(module.test_dev_eastus.storage_account_name)
    storage_account_length_prod = length(module.test_prod_westeurope.storage_account_name)
    key_vault_length_dev        = length(module.test_dev_eastus.key_vault_name)
    key_vault_length_prod       = length(module.test_prod_westeurope.key_vault_name)
    vm_name_length_dev          = length(module.test_dev_eastus.virtual_machine_name)
    vm_name_length_prod         = length(module.test_prod_westeurope.virtual_machine_name)
  }
}
