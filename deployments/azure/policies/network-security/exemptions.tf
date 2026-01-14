# Policy Exemptions for Resources Requiring Public IPs
# Use sparingly - exemptions should be reviewed quarterly

# Create exemptions for resources that legitimately need public IPs
resource "azurerm_resource_policy_exemption" "vm_public_ip" {
  for_each = var.exempted_resources

  name                 = "exemption-${each.key}-public-ip"
  resource_id          = each.value.resource_id
  policy_assignment_id = azurerm_subscription_policy_assignment.no_public_ip.id
  exemption_category   = "Mitigated" # Indicates compensating controls are in place

  display_name = "Public IP Exemption: ${each.key}"
  description  = each.value.justification
  expires_on   = each.value.expires_on

  metadata = jsonencode({
    compensatingControls = each.value.compensating_controls
    approvedBy           = each.value.approved_by
    ticketNumber         = each.value.ticket_number
    createdBy            = "Terraform"
    managedBy            = "Platform Team"
    reviewRequired       = "Quarterly"
  })

  depends_on = [
    azurerm_subscription_policy_assignment.no_public_ip
  ]
}
