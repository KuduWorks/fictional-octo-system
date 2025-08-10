# Virtual Network Deployment

This directory contains the Bicep templates for deploying an Azure Virtual Network (VNet) with associated networking components.

## What's Included

- **main.bicep**: Main template for VNet deployment
- **main.parameters.json**: Parameter file with default values
- **deploy.ps1**: PowerShell deployment script
- **README.md**: This documentation

## Architecture

The deployment creates:
- Virtual Network with configurable address space
- Default subnet with Network Security Group
- Network Security Group with basic security rules (HTTPS and SSH)
- Proper tagging for resource management

## Quick Deploy

### Prerequisites
- Azure CLI or Azure PowerShell installed
- Logged into Azure (`az login` or `Connect-AzAccount`)
- Target resource group already exists

### Option 1: Using Azure CLI
```bash
az deployment group create \
  --resource-group <your-resource-group> \
  --template-file main.bicep \
  --parameters main.parameters.json
```

### Option 2: Using PowerShell Script
```powershell
.\deploy.ps1 -ResourceGroupName <your-resource-group>
```

### Option 3: Using Azure PowerShell
```powershell
New-AzResourceGroupDeployment `
  -ResourceGroupName <your-resource-group> `
  -TemplateFile main.bicep `
  -TemplateParameterFile main.parameters.json
```

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| vnetName | string | vnet-{uniqueString} | Name of the virtual network |
| vnetAddressPrefix | string | 10.0.0.0/16 | Address space for the VNet |
| subnetName | string | default | Name of the default subnet |
| subnetAddressPrefix | string | 10.0.1.0/24 | Address space for the subnet |
| location | string | resourceGroup().location | Azure region for deployment |
| tags | object | See parameters file | Tags applied to all resources |

## Outputs

The template provides these outputs:
- VNet ID and name
- Subnet ID and name  
- Network Security Group ID and name
- Address prefixes for VNet and subnet

## Customization

To customize the deployment:
1. Edit `main.parameters.json` with your desired values
2. Modify `main.bicep` for additional subnets or security rules
3. Update tags in the parameters file

## Security

The default Network Security Group includes:
- Allow HTTPS (port 443) inbound
- Allow SSH (port 22) inbound

**Note**: Review and modify security rules based on your specific requirements before production use.
