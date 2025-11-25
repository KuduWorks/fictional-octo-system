# Azure Naming Convention Module
# Generates consistent, compliant resource names for Azure resources

locals {
  # Region abbreviations (3 characters)
  region_abbreviations = {
    # North America
    "eastus"             = "eus"
    "eastus2"            = "eu2"
    "westus"             = "wus"
    "westus2"            = "wu2"
    "westus3"            = "wu3"
    "centralus"          = "cus"
    "northcentralus"     = "ncu"
    "southcentralus"     = "scu"
    "westcentralus"      = "wcu"
    "canadacentral"      = "cac"
    "canadaeast"         = "cae"
    
    # Europe
    "northeurope"        = "neu"
    "westeurope"         = "weu"
    "uksouth"            = "uks"
    "ukwest"             = "ukw"
    "francecentral"      = "frc"
    "francesouth"        = "frs"
    "germanywestcentral" = "gwc"
    "germanynorth"       = "gno"
    "norwayeast"         = "noe"
    "norwaywest"         = "now"
    "swedencentral"      = "swe"
    "switzerlandnorth"   = "swn"
    "switzerlandwest"    = "sww"
    
    # Asia Pacific
    "southeastasia"      = "sea"
    "eastasia"           = "eas"
    "australiaeast"      = "aue"
    "australiasoutheast" = "aus"
    "australiacentral"   = "auc"
    "japaneast"          = "jpe"
    "japanwest"          = "jpw"
    "koreacentral"       = "koc"
    "koreasouth"         = "kos"
    "centralindia"       = "cin"
    "southindia"         = "sin"
    "westindia"          = "win"
    
    # Middle East & Africa
    "uaenorth"           = "uan"
    "uaecentral"         = "uac"
    "southafricanorth"   = "san"
    "southafricawest"    = "saw"
    
    # South America
    "brazilsouth"        = "brs"
    "brazilsoutheast"    = "bre"
  }

  # Resource type abbreviations
  resource_abbreviations = {
    "storage_account"     = "st"
    "virtual_machine"     = "vm"
    "virtual_network"     = "vnet"
    "subnet"              = "snet"
    "network_interface"   = "nic"
    "public_ip"           = "pip"
    "network_security_group" = "nsg"
    "resource_group"      = "rg"
    "key_vault"           = "kv"
    "app_service"         = "app"
    "function_app"        = "func"
    "container_instance"  = "aci"
    "kubernetes_cluster"  = "aks"
    "cosmos_db"           = "cosmos"
    "sql_server"          = "sql"
    "sql_database"        = "sqldb"
    "log_analytics"       = "log"
    "application_insights" = "appi"
  }

  # Get region abbreviation
  region_code = lookup(local.region_abbreviations, var.region, substr(var.region, 0, 3))

  # Base name components
  base_name = "${var.workload}-${var.environment}-${local.region_code}"
  
  # Generate names for each resource type
  storage_account_name = lower(replace("${local.resource_abbreviations["storage_account"]}${var.workload}${var.environment}${local.region_code}${var.instance}", "/[^a-z0-9]/", ""))
  
  vm_name = "${local.resource_abbreviations["virtual_machine"]}-${local.base_name}-${var.instance}"
  
  vnet_name = "${local.resource_abbreviations["virtual_network"]}-${local.base_name}"
  
  subnet_name = "${local.resource_abbreviations["subnet"]}-${var.workload}-${var.subnet_purpose}"
  
  nic_name = "${local.resource_abbreviations["network_interface"]}-${local.base_name}-${var.instance}"
  
  public_ip_name = "${local.resource_abbreviations["public_ip"]}-${local.base_name}-${var.instance}"
  
  nsg_name = "${local.resource_abbreviations["network_security_group"]}-${local.base_name}"
  
  resource_group_name = "${local.resource_abbreviations["resource_group"]}-${local.base_name}"
  
  key_vault_name = substr(lower(replace("${local.resource_abbreviations["key_vault"]}-${var.workload}-${var.environment}-${local.region_code}-${var.instance}", "/[^a-z0-9-]/", "")), 0, 24)
  
  app_service_name = "${local.resource_abbreviations["app_service"]}-${local.base_name}-${var.instance}"
  
  function_app_name = "${local.resource_abbreviations["function_app"]}-${local.base_name}-${var.instance}"
  
  container_instance_name = "${local.resource_abbreviations["container_instance"]}-${local.base_name}-${var.instance}"
  
  aks_name = "${local.resource_abbreviations["kubernetes_cluster"]}-${local.base_name}"
  
  cosmos_db_name = lower(replace("${local.resource_abbreviations["cosmos_db"]}-${local.base_name}-${var.instance}", "/[^a-z0-9-]/", ""))
  
  sql_server_name = lower(replace("${local.resource_abbreviations["sql_server"]}-${local.base_name}-${var.instance}", "/[^a-z0-9-]/", ""))
  
  sql_database_name = "${local.resource_abbreviations["sql_database"]}-${var.workload}-${var.environment}"
  
  log_analytics_name = "${local.resource_abbreviations["log_analytics"]}-${local.base_name}"
  
  app_insights_name = "${local.resource_abbreviations["application_insights"]}-${local.base_name}"

  # Common tags
  common_tags = merge(
    {
      Environment = var.environment
      Region      = var.region
      Workload    = var.workload
      ManagedBy   = "Terraform"
    },
    var.additional_tags
  )
}
