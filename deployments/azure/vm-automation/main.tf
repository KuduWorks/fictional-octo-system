# Configure the Azure Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.0"
}

provider "azurerm" {
  features {}
}

# Get current subscription data
data "azurerm_client_config" "current" {}

# Locals
locals {
  subscription_id     = var.subscription_id != null ? var.subscription_id : data.azurerm_client_config.current.subscription_id
  resource_group_name = var.resource_group_name
  location            = var.location
  vm_name             = var.vm_name

  # Tags
  common_tags = merge(
    var.tags,
    {
      Environment  = var.environment
      ManagedBy    = "Terraform"
      AutoShutdown = "Enabled"
      ShutdownTime = "19:00 Finnish Time"
      StartupTime  = "07:00 Finnish Time"
    }
  )
}

#
# ==================== RESOURCE GROUP ====================
#

resource "azurerm_resource_group" "vm_rg" {
  name     = local.resource_group_name
  location = local.location
  tags     = local.common_tags
}

#
# ==================== NETWORKING ====================
#

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.vm_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.vm_rg.location
  resource_group_name = azurerm_resource_group.vm_rg.name
  tags                = local.common_tags
}

# VM Subnet
resource "azurerm_subnet" "vm_subnet" {
  name                 = "vm-subnet"
  resource_group_name  = azurerm_resource_group.vm_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Azure Bastion Subnet (required name and size)
resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet" # Required name
  resource_group_name  = azurerm_resource_group.vm_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/26"] # Minimum /26 required
}

# Network Security Group for VM subnet
resource "azurerm_network_security_group" "vm_nsg" {
  name                = "${var.vm_name}-vm-nsg"
  location            = azurerm_resource_group.vm_rg.location
  resource_group_name = azurerm_resource_group.vm_rg.name
  tags                = local.common_tags

  # Allow SSH from Bastion subnet only
  security_rule {
    name                       = "Allow-SSH-From-Bastion"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.2.0/26" # Bastion subnet
    destination_address_prefix = "*"
  }

  # Deny all other inbound traffic
  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow outbound to internet via NAT Gateway
  security_rule {
    name                       = "Allow-Internet-Outbound"
    priority                   = 1000
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }
}

# Associate NSG with VM subnet
resource "azurerm_subnet_network_security_group_association" "vm_subnet_nsg" {
  subnet_id                 = azurerm_subnet.vm_subnet.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

#
# ==================== NAT GATEWAY ====================
#

# Public IP for NAT Gateway
resource "azurerm_public_ip" "nat_gateway_ip" {
  name                = "${var.vm_name}-nat-gateway-ip"
  location            = azurerm_resource_group.vm_rg.location
  resource_group_name = azurerm_resource_group.vm_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

# NAT Gateway
resource "azurerm_nat_gateway" "nat_gateway" {
  name                    = "${var.vm_name}-nat-gateway"
  location                = azurerm_resource_group.vm_rg.location
  resource_group_name     = azurerm_resource_group.vm_rg.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  tags                    = local.common_tags
}

# Associate Public IP with NAT Gateway
resource "azurerm_nat_gateway_public_ip_association" "nat_gateway_ip_assoc" {
  nat_gateway_id       = azurerm_nat_gateway.nat_gateway.id
  public_ip_address_id = azurerm_public_ip.nat_gateway_ip.id
}

# Associate NAT Gateway with VM subnet
resource "azurerm_subnet_nat_gateway_association" "vm_subnet_nat" {
  subnet_id      = azurerm_subnet.vm_subnet.id
  nat_gateway_id = azurerm_nat_gateway.nat_gateway.id
}

#
# ==================== AZURE BASTION ====================
#

# Public IP for Bastion
resource "azurerm_public_ip" "bastion_ip" {
  name                = "${var.vm_name}-bastion-ip"
  location            = azurerm_resource_group.vm_rg.location
  resource_group_name = azurerm_resource_group.vm_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

# Azure Bastion Host
resource "azurerm_bastion_host" "bastion" {
  name                = "${var.vm_name}-bastion"
  location            = azurerm_resource_group.vm_rg.location
  resource_group_name = azurerm_resource_group.vm_rg.name
  sku                 = var.bastion_sku
  tags                = local.common_tags

  ip_configuration {
    name                 = "bastion-ipconfig"
    subnet_id            = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion_ip.id
  }
}
#
# ==================== NETWORK INTERFACE ====================
#

resource "azurerm_network_interface" "nic" {
  name                = "${var.vm_name}-nic"
  location            = azurerm_resource_group.vm_rg.location
  resource_group_name = azurerm_resource_group.vm_rg.name
  tags                = local.common_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
    # No public IP - access via Bastion only
  }
}

# No need for NSG association on NIC since it's on the subnet

#
# ==================== VIRTUAL MACHINE ====================
#

resource "azurerm_linux_virtual_machine" "vm" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.vm_rg.name
  location            = azurerm_resource_group.vm_rg.location
  size                = var.vm_size
  admin_username      = var.admin_username
  tags                = local.common_tags

  # Enable encryption at host (for ISO 27001 compliance)
  encryption_at_host_enabled = true

  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    name                 = "${var.vm_name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = var.vm_image_publisher
    offer     = var.vm_image_offer
    sku       = var.vm_image_sku
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }
}

#
# ==================== AUTOMATION ACCOUNT ====================
#

resource "azurerm_automation_account" "automation" {
  name                = "${var.vm_name}-automation"
  location            = azurerm_resource_group.vm_rg.location
  resource_group_name = azurerm_resource_group.vm_rg.name
  sku_name            = "Basic"
  tags                = local.common_tags

  identity {
    type = "SystemAssigned"
  }
}

# Grant Automation Account permissions to manage the VM
resource "azurerm_role_assignment" "automation_vm_contributor" {
  scope                = azurerm_resource_group.vm_rg.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azurerm_automation_account.automation.identity[0].principal_id
}

#
# ==================== SHUTDOWN RUNBOOK ====================
#

resource "azurerm_automation_runbook" "shutdown_vm" {
  name                    = "Shutdown-VM"
  location                = azurerm_resource_group.vm_rg.location
  resource_group_name     = azurerm_resource_group.vm_rg.name
  automation_account_name = azurerm_automation_account.automation.name
  log_verbose             = true
  log_progress            = true
  runbook_type            = "PowerShell"
  tags                    = local.common_tags

  content = <<-EOT
    param(
        [string]$ResourceGroupName,
        [string]$VMName
    )

    try {
        # Authenticate using managed identity
        Connect-AzAccount -Identity
        
        Write-Output "Shutting down VM: $VMName in resource group: $ResourceGroupName"
        
        # Stop the VM
        Stop-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName -Force
        
        Write-Output "VM $VMName has been stopped successfully"
    }
    catch {
        Write-Error "Error stopping VM: $_"
        throw
    }
  EOT
}

#
# ==================== STARTUP RUNBOOK ====================
#

resource "azurerm_automation_runbook" "startup_vm" {
  name                    = "Startup-VM"
  location                = azurerm_resource_group.vm_rg.location
  resource_group_name     = azurerm_resource_group.vm_rg.name
  automation_account_name = azurerm_automation_account.automation.name
  log_verbose             = true
  log_progress            = true
  runbook_type            = "PowerShell"
  tags                    = local.common_tags

  content = <<-EOT
    param(
        [string]$ResourceGroupName,
        [string]$VMName
    )

    try {
        # Authenticate using managed identity
        Connect-AzAccount -Identity
        
        Write-Output "Starting VM: $VMName in resource group: $ResourceGroupName"
        
        # Start the VM
        Start-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName
        
        Write-Output "VM $VMName has been started successfully"
    }
    catch {
        Write-Error "Error starting VM: $_"
        throw
    }
  EOT
}

#
# ==================== SCHEDULES ====================
#

# Shutdown schedule - 7:00 PM Finnish Time (UTC+2/UTC+3 depending on DST)
# Using UTC 17:00 (5 PM UTC = 7 PM EET) for winter time
resource "azurerm_automation_schedule" "shutdown_schedule" {
  name                    = "Shutdown-Schedule"
  resource_group_name     = azurerm_resource_group.vm_rg.name
  automation_account_name = azurerm_automation_account.automation.name
  frequency               = "Day"
  interval                = 1
  timezone                = "Europe/Helsinki"
  start_time              = var.shutdown_time # Use variable for schedule time
  description             = "Shutdown VM daily at configurable time"

  # Start time is now configurable via var.shutdown_time
}

# Startup schedule - 7:00 AM Finnish Time
resource "azurerm_automation_schedule" "startup_schedule" {
  name                    = "Startup-Schedule"
  resource_group_name     = azurerm_resource_group.vm_rg.name
  automation_account_name = azurerm_automation_account.automation.name
  frequency               = "Day"
  interval                = 1
  timezone                = "Europe/Helsinki"
  start_time              = var.startup_time # Use variable for schedule time
  description             = "Start VM daily at configurable time"

  # Start time is now configurable via var.startup_time
}

#
# ==================== JOB SCHEDULES (Link Runbooks to Schedules) ====================
#

resource "azurerm_automation_job_schedule" "shutdown_job" {
  resource_group_name     = azurerm_resource_group.vm_rg.name
  automation_account_name = azurerm_automation_account.automation.name
  schedule_name           = azurerm_automation_schedule.shutdown_schedule.name
  runbook_name            = azurerm_automation_runbook.shutdown_vm.name

  parameters = {
    resourcegroupname = azurerm_resource_group.vm_rg.name
    vmname            = azurerm_linux_virtual_machine.vm.name
  }
}

resource "azurerm_automation_job_schedule" "startup_job" {
  resource_group_name     = azurerm_resource_group.vm_rg.name
  automation_account_name = azurerm_automation_account.automation.name
  schedule_name           = azurerm_automation_schedule.startup_schedule.name
  runbook_name            = azurerm_automation_runbook.startup_vm.name

  parameters = {
    resourcegroupname = azurerm_resource_group.vm_rg.name
    vmname            = azurerm_linux_virtual_machine.vm.name
  }
}

#
# ==================== OUTPUTS ====================
#

output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.vm_rg.name
}

output "vm_name" {
  description = "The name of the virtual machine"
  value       = azurerm_linux_virtual_machine.vm.name
}

output "vm_id" {
  description = "The ID of the virtual machine"
  value       = azurerm_linux_virtual_machine.vm.id
}

output "private_ip_address" {
  description = "The private IP address of the VM"
  value       = azurerm_network_interface.nic.private_ip_address
}

output "bastion_host_name" {
  description = "The name of the Azure Bastion host"
  value       = azurerm_bastion_host.bastion.name
}

output "bastion_dns_name" {
  description = "The DNS name of the Azure Bastion"
  value       = azurerm_bastion_host.bastion.dns_name
}

output "nat_gateway_ip" {
  description = "The public IP of the NAT Gateway (for outbound connectivity)"
  value       = azurerm_public_ip.nat_gateway_ip.ip_address
}

output "connection_instructions" {
  description = "How to connect to the VM"
  value       = <<-EOT
    
    To connect to your VM via Azure Bastion:
    
    1. Azure Portal Method (Recommended):
       - Go to: https://portal.azure.com
       - Navigate to Virtual Machines → ${azurerm_linux_virtual_machine.vm.name}
       - Click "Connect" → "Bastion"
       - Enter username: ${var.admin_username}
       - Select "SSH Private Key from Local File"
       - Upload your private key file
       - Click "Connect"
    
    2. Azure CLI Method:
       az network bastion ssh \
         --name ${azurerm_bastion_host.bastion.name} \
         --resource-group ${azurerm_resource_group.vm_rg.name} \
         --target-resource-id ${azurerm_linux_virtual_machine.vm.id} \
         --auth-type ssh-key \
         --username ${var.admin_username} \
         --ssh-key ~/.ssh/id_rsa_azure
    
    Private IP: ${azurerm_network_interface.nic.private_ip_address}
    Outbound IP (NAT): ${azurerm_public_ip.nat_gateway_ip.ip_address}
  EOT
}

output "automation_account_name" {
  description = "The name of the automation account"
  value       = azurerm_automation_account.automation.name
}

output "shutdown_schedule" {
  description = "Shutdown schedule details"
  value = {
    name     = azurerm_automation_schedule.shutdown_schedule.name
    time     = var.shutdown_time
    timezone = "Europe/Helsinki"
  }
}

output "startup_schedule" {
  description = "Startup schedule details"
  value = {
    name     = azurerm_automation_schedule.startup_schedule.name
    time     = var.startup_time
    timezone = "Europe/Helsinki"
  }
}
