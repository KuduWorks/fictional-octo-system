# ==================== REQUIRED SETTINGS ====================

# VM Configuration
vm_name             = "dev-vm-01"
resource_group_name = "rg-vm-automation-dev"
admin_username      = "azureuser"

# SSH Public Key - REPLACE THIS WITH YOUR PUBLIC KEY
# Generate one with: ssh-keygen -t rsa -b 4096
# Then copy from: cat ~/.ssh/id_rsa.pub
# ssh_public_key is now stored in terraform.tfvars.secret (excluded from version control)
# Example: ssh_public_key = "ssh-rsa AAAA... user@host"

# ==================== OPTIONAL SETTINGS ====================

# Location
location = "swedencentral"

# VM Size (Standard_B2s = 2 vCPU, 4GB RAM - good for dev/test)
# Other options: Standard_B1s (1 vCPU, 1GB), Standard_D2s_v3 (2 vCPU, 8GB)
vm_size = "Standard_B2s"

# Environment
environment = "dev"

# Azure Bastion SKU
# - Basic: Standard features, native SSH/RDP support via portal
# - Standard: Advanced features (IP-based connection, custom ports, file transfer)
bastion_sku = "Basic" 

# ==================== VM IMAGE ====================
# Default: Ubuntu 22.04 LTS
# For Windows Server, change to:
# vm_image_publisher = "MicrosoftWindowsServer"
# vm_image_offer     = "WindowsServer"
# vm_image_sku       = "2022-datacenter-azure-edition"

vm_image_publisher = "Canonical"
vm_image_offer     = "0001-com-ubuntu-server-jammy"
vm_image_sku       = "22_04-lts-gen2"

# ==================== AUTOMATION SCHEDULE ====================
# Times are in Finnish timezone (Europe/Helsinki)
# Finland uses EET (UTC+2) in winter and EEST (UTC+3) in summer
# Use RFC3339 format with timezone (must be in future)
# NOTE: Update shutdown_time and startup_time to future dates before each deployment to avoid schedule errors.
shutdown_time = "2025-10-25T19:00:00+02:00"  # 19:00 Finnish Time
startup_time  = "2025-10-26T07:00:00+02:00"  # 07:00 Finnish Time tomorrow
startup_time  = "2025-10-26T07:00:00+02:00"  # 07:00 Finnish Time tomorrow
# ==================== TAGS ====================

tags = {
  Project     = "VM Automation"
  Owner       = "DevOps Team"
  CostCenter  = "Engineering"
  AutoManaged = "true"
}
