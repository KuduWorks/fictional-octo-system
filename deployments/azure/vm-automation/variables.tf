# ==================== REQUIRED VARIABLES ====================

variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}

# ==================== OPTIONAL VARIABLES ====================

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "swedencentral"
}

variable "subscription_id" {
  description = "Azure subscription ID (optional, auto-detected if not provided)"
  type        = string
  default     = null
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_B2s"
}

variable "environment" {
  description = "Environment tag (dev, test, prod)"
  type        = string
  default     = "dev"
}

variable "bastion_sku" {
  description = "SKU for Azure Bastion (Basic or Standard)"
  type        = string
  default     = "Basic"
  validation {
    condition     = contains(["Basic", "Standard"], var.bastion_sku)
    error_message = "Bastion SKU must be either 'Basic' or 'Standard'."
  }
}

# ==================== VM IMAGE VARIABLES ====================

variable "vm_image_publisher" {
  description = "VM image publisher"
  type        = string
  default     = "Canonical"
}

variable "vm_image_offer" {
  description = "VM image offer"
  type        = string
  default     = "0001-com-ubuntu-server-jammy"
}

variable "vm_image_sku" {
  description = "VM image SKU"
  type        = string
  default     = "22_04-lts-gen2"
}

# ==================== TAGS ====================

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

# ==================== SCHEDULE CONFIGURATION ====================

variable "shutdown_time" {
  description = "Time to shutdown VM (24h format, Finnish time)"
  type        = string
  default     = "19:00"
}

variable "startup_time" {
  description = "Time to start VM (24h format, Finnish time)"
  type        = string
  default     = "07:00"
}
