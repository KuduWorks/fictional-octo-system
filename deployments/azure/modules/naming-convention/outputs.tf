output "storage_account_name" {
  description = "Storage account name (3-24 chars, lowercase alphanumeric only)"
  value       = local.storage_account_name
}

output "virtual_machine_name" {
  description = "Virtual machine name"
  value       = local.vm_name
}

output "virtual_network_name" {
  description = "Virtual network name"
  value       = local.vnet_name
}

output "subnet_name" {
  description = "Subnet name"
  value       = local.subnet_name
}

output "network_interface_name" {
  description = "Network interface name"
  value       = local.nic_name
}

output "public_ip_name" {
  description = "Public IP name"
  value       = local.public_ip_name
}

output "network_security_group_name" {
  description = "Network security group name"
  value       = local.nsg_name
}

output "resource_group_name" {
  description = "Resource group name"
  value       = local.resource_group_name
}

output "key_vault_name" {
  description = "Key Vault name (3-24 chars, alphanumeric and hyphens)"
  value       = local.key_vault_name
}

output "app_service_name" {
  description = "App Service name"
  value       = local.app_service_name
}

output "function_app_name" {
  description = "Function App name"
  value       = local.function_app_name
}

output "container_instance_name" {
  description = "Container Instance name"
  value       = local.container_instance_name
}

output "aks_name" {
  description = "Azure Kubernetes Service cluster name"
  value       = local.aks_name
}

output "cosmos_db_name" {
  description = "Cosmos DB account name"
  value       = local.cosmos_db_name
}

output "sql_server_name" {
  description = "SQL Server name"
  value       = local.sql_server_name
}

output "sql_database_name" {
  description = "SQL Database name"
  value       = local.sql_database_name
}

output "log_analytics_name" {
  description = "Log Analytics workspace name"
  value       = local.log_analytics_name
}

output "application_insights_name" {
  description = "Application Insights name"
  value       = local.app_insights_name
}

output "common_tags" {
  description = "Common tags to apply to all resources"
  value       = merge(local.common_tags, var.additional_tags)
}

output "region_code" {
  description = "Three-character region abbreviation"
  value       = local.region_code
}
