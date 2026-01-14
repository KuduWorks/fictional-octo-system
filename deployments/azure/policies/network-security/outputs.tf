# Outputs for Network Security Policies

output "vm_nic_nsg_required_policy_id" {
  description = "The ID of the VM NIC NSG required custom policy definition"
  value       = azurerm_policy_definition.vm_nic_nsg_required.id
}

output "vm_nic_nsg_required_assignment_id" {
  description = "The ID of the VM NIC NSG required policy assignment"
  value       = azurerm_subscription_policy_assignment.vm_nic_nsg_required.id
}

output "no_public_ip_assignment_id" {
  description = "The ID of the no public IP policy assignment"
  value       = azurerm_subscription_policy_assignment.no_public_ip.id
}

output "exemption_ids" {
  description = "Map of exemption IDs for exempted resources"
  value       = { for k, v in azurerm_resource_policy_exemption.vm_public_ip : k => v.id }
}

output "exemption_expiration_dates" {
  description = "Map of exemption expiration dates"
  value       = { for k, v in azurerm_resource_policy_exemption.vm_public_ip : k => v.expires_on }
}

output "monitoring_action_group_id" {
  description = "The ID of the monitoring action group for exemption expiry alerts"
  value       = length(azurerm_monitor_action_group.exemption_expiry) > 0 ? azurerm_monitor_action_group.exemption_expiry[0].id : null
}

output "enforcement_mode" {
  description = "The enforcement mode of the policies"
  value       = var.enforcement_mode
}

output "subscription_id" {
  description = "The subscription ID where policies are deployed"
  value       = local.subscription_id
}
