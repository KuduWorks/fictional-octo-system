# Region Control Policies

This folder contains Azure Policy definitions and assignments to enforce geographic deployment restrictions, specifically allowing only **Sweden Central** region for all Azure resources.

## Overview

This deployment creates:

1. **Built-in Policy Assignment** - Uses Azure's built-in "Allowed locations" policy
2. **Custom Policy Definition** - Additional policy for resource group location control  
3. **Policy Initiative** - Groups related policies for unified management
4. **Multiple Format Support** - ARM templates, Bicep, and Terraform options

## Files

```
region-control/
├── arm-template.json              # ARM template (recommended)
├── arm-template.parameters.json   # Parameters for ARM template
├── deploy-arm.sh                  # Bash deployment script for ARM
├── deploy-arm.ps1                 # PowerShell deployment script for ARM
├── main.bicep                     # Bicep template (alternative)
├── main.parameters.json           # Parameters for Bicep
├── main.tf                        # Terraform template (alternative)
└── README.md                      # This file
```

## Policies Included

### 1. Allowed Locations Policy (Built-in)
- **Policy ID**: `e56962a6-4747-49cd-b67b-bf8b01975c4c`
- **Effect**: Deny
- **Purpose**: Restricts all resource deployments to approved regions

### 2. Resource Group Location Policy (Custom)
- **Name**: `custom-rg-location-policy`
- **Effect**: Deny  
- **Purpose**: Ensures resource groups are created only in allowed regions

### 3. Region Control Initiative
- **Name**: `region-control-initiative`
- **Type**: Policy Set Definition
- **Purpose**: Groups all region-related policies for easier management

## Deployment Options

### Option 1: ARM Template (Recommended)

```bash
# Deploy using Azure CLI
az deployment sub create \
    --location swedencentral \
    --template-file arm-template.json \
    --parameters arm-template.parameters.json \
    --name "region-control-$(date +%Y%m%d-%H%M%S)"
```

### Option 2: Using Deployment Scripts

```bash
# Bash script
./deploy-arm.sh

# PowerShell script  
./deploy-arm.ps1
```

### Option 3: Bicep Template

```bash
az deployment sub create \
    --location swedencentral \
    --template-file main.bicep \
    --parameters main.parameters.json \
    --name "region-control-bicep-$(date +%Y%m%d-%H%M%S)"
```

### Option 4: Terraform

```bash
terraform init
terraform plan
terraform apply
```

## Configuration

### Allowed Regions

To modify allowed regions, edit the parameters file:

```json
{
  "parameters": {
    "allowedRegions": {
      "value": [
        "swedencentral",
        "swedensouth"
      ]
    }
  }
}
```

### Enforcement Mode

- **Default**: Policy actively denies non-compliant resources
- **DoNotEnforce**: Policy evaluates compliance but doesn't block deployments (audit mode)

```json
{
  "parameters": {
    "enforcementMode": {
      "value": "DoNotEnforce"
    }
  }
}
```

## Testing

After deployment, test the policies:

```bash
# This should fail
az group create --name "test-blocked" --location "eastus"

# This should succeed  
az group create --name "test-allowed" --location "swedencentral"
az group delete --name "test-allowed" --yes --no-wait
```

## Verification

Check deployed policies:

```bash
# List policy assignments
az policy assignment list \
    --query "[?contains(name, 'region')].{Name:name, DisplayName:displayName, EnforcementMode:enforcementMode}" \
    --output table

# Check compliance
az policy state list \
    --query "[?complianceState=='NonCompliant']"
```

## Cleanup

To remove the policies:

```bash
# Delete policy assignments
az policy assignment delete --name "allowed-regions-sweden-central-arm"
az policy assignment delete --name "region-control-initiative-assignment"

# Delete custom policy definition
az policy definition delete --name "custom-rg-location-policy"

# Delete policy set definition  
az policy set-definition delete --name "region-control-initiative"
```

## Troubleshooting

### Common Issues

1. **Validation Errors**
   - Check Azure CLI version: `az --version`
   - Verify login status: `az account show`
   - Validate template: `az deployment sub validate`

2. **Permission Errors**
   - Ensure you have `Policy Contributor` role
   - Check subscription access: `az account list`

3. **Policy Not Enforcing**
   - Policies can take 15-30 minutes to take effect
   - Check enforcement mode is set to "Default"
   - Verify policy assignment scope

### Debug Commands

```bash
# Check specific policy assignment
az policy assignment show --name "allowed-regions-sweden-central-arm"

# View deployment details
az deployment sub show --name "your-deployment-name"

# Check activity logs
az monitor activity-log list --max-events 50
```

## Integration

This policy set can be combined with other policy categories:

- **Security Baseline**: Add encryption and access control policies
- **Cost Management**: Include resource SKU and tagging policies  
- **Compliance**: Integrate with regulatory compliance frameworks

See the parent `policies/` folder for examples of other policy categories.