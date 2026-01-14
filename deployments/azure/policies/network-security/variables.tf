# Variables for Network Security Policies

variable "enforcement_mode" {
  description = "Policy enforcement mode - 'Default' (enforce) or 'DoNotEnforce' (audit only). Start with DoNotEnforce to assess impact."
  type        = string
  default     = "Default"

  validation {
    condition     = contains(["Default", "DoNotEnforce"], var.enforcement_mode)
    error_message = "Enforcement mode must be either 'Default' or 'DoNotEnforce'."
  }
}

variable "vm_nic_nsg_effect" {
  description = "Effect for VM NIC NSG policy - 'audit' (log violations) or 'deny' (block violations). Recommend starting with 'audit'."
  type        = string
  default     = "audit"

  validation {
    condition     = contains(["audit", "deny"], var.vm_nic_nsg_effect)
    error_message = "VM NIC NSG effect must be either 'audit' or 'deny'."
  }
}

variable "subscription_id" {
  description = "Azure subscription ID. If not provided, uses the current subscription from Azure CLI context."
  type        = string
  default     = null
}

variable "exempted_resources" {
  description = <<-EOT
    Map of resources exempted from the no-public-IP policy.
    Each exemption must include justification, expiration date, compensating controls, and approver.
    Use 'Mitigated' category when compensating security controls are in place.
    Maximum exemption period: 12 months.
  EOT

  type = map(object({
    resource_id           = string
    justification         = string
    expires_on            = string # ISO 8601 format: "2027-12-31T23:59:00Z"
    compensating_controls = string
    approved_by           = string
    ticket_number         = string
  }))

  default = {}
}

variable "alert_email" {
  description = "Email address for exemption expiration alerts (60 days before expiry)"
  type        = string
  default     = "security@example.com"
}

variable "monitoring_resource_group_name" {
  description = "Resource group name for monitoring resources (Log Analytics, Action Groups)"
  type        = string
  default     = "rg-policy-monitoring"
}

variable "monitoring_location" {
  description = "Azure region for monitoring resources"
  type        = string
  default     = "swedencentral"
}
