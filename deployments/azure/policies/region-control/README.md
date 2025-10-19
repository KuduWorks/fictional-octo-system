# Region Control Policies

This folder contains Azure Policy definitions and assignments to enforce geographic deployment restrictions, specifically allowing only **Sweden Central** region for all Azure resources.

## Overview

This deployment creates **two built-in policy assignments**:

1. **Allowed Locations Policy** - Restricts where resources can be deployed
2. **Allowed Resource Group Locations Policy** - Restricts where resource groups can be created

Both policies work together to ensure complete regional control.

## Files

```
region-control/
├── arm-template.json              # ARM template deployment option
├── arm-template.parameters.json   # Parameters for ARM template
├── deploy-arm.sh                  # Bash deployment script for ARM
├── deploy-arm.ps1                 # PowerShell deployment script for ARM
├── main.tf                        # Terraform configuration (recommended)
├── terraform.tfvars               # Terraform variable customization
├── main.parameters.json           # Legacy parameters file
├── TERRAFORM.md                   # Detailed Terraform deployment guide
└── README.md                      # This file
```

## Policies Included

### 1. Allowed Locations Policy (Built-in)
- **Policy ID**: `e56962a6-4747-49cd-b67b-bf8b01975c4c`
- **Assignment Name**: `allowed-regions-sweden-central-tf`
- **Effect**: Deny
- **Purpose**: Blocks all resource deployments outside approved regions
- **Applies To**: VMs, storage accounts, databases, networks, etc.

### 2. Allowed Resource Group Locations Policy (Built-in)
- **Policy ID**: `e765b5de-1225-4ba3-bd56-1ac6695af988`
- **Assignment Name**: `rg-location-policy-assignment`
- **Effect**: Deny
- **Purpose**: Blocks resource group creation outside approved regions
- **Applies To**: Resource groups only

## Deployment Options

### Option 1: Terraform (Recommended)

Terraform provides the best experience with state management and preview capabilities.

```bash
# Navigate to the region-control folder
cd deployments/azure/policies/region-control

# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Deploy the policies
terraform apply
```

**See [TERRAFORM.md](./TERRAFORM.md) for detailed Terraform deployment guide.**

### Option 2: ARM Template

```bash
# Deploy using Azure CLI
az deployment sub create \
    --location swedencentral \
    --template-file arm-template.json \
    --parameters arm-template.parameters.json \
    --name "region-control-$(date +%Y%m%d-%H%M%S)"
```

### Option 3: Using Deployment Scripts

```bash
# Bash script
./deploy-arm.sh

# PowerShell script  
./deploy-arm.ps1
```

## Configuration

### Terraform Configuration (Recommended)

Edit `terraform.tfvars` to customize:

```hcl
# Allowed Azure regions
allowed_regions = ["swedencentral", "swedensouth"]

# Policy assignment name
policy_assignment_name = "allowed-regions-sweden-central-tf"

# Enforcement mode: "Default" (enforce) or "DoNotEnforce" (audit only)
enforcement_mode = "Default"
```

### ARM Template Configuration

To modify allowed regions, edit `arm-template.parameters.json`:

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

- **Default**: Policy actively denies non-compliant resources (recommended for production)
- **DoNotEnforce**: Policy evaluates compliance but doesn't block deployments (audit mode for testing)

## Testing

After deployment, **wait 15-30 minutes** for policies to take effect, then test:

```bash
# This should FAIL - resource group in wrong region
az group create --name "test-blocked-rg" --location "eastus"

# This should SUCCEED - resource group in allowed region
az group create --name "test-allowed-rg" --location "swedencentral"

# This should FAIL - resource in wrong region (even if RG is correct)
az network vnet create \
    --name "test-vnet" \
    --resource-group "test-allowed-rg" \
    --location "eastus"

# This should SUCCEED - resource in allowed region
az network vnet create \
    --name "test-vnet" \
    --resource-group "test-allowed-rg" \
    --location "swedencentral"

# Cleanup
az group delete --name "test-allowed-rg" --yes --no-wait
```

### Expected Behavior

✅ **Resource groups** can only be created in Sweden Central  
✅ **Resources** (VMs, VNets, storage, etc.) can only be deployed in Sweden Central  
❌ Any attempt to deploy outside Sweden Central is **blocked**

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

### Terraform Cleanup

```bash
# Remove all policies managed by Terraform
terraform destroy
```

### Manual Cleanup (ARM/CLI deployments)

```bash
# Delete policy assignments
az policy assignment delete --name "allowed-regions-sweden-central-tf"
az policy assignment delete --name "rg-location-policy-assignment"

# Note: Built-in policy definitions cannot be deleted
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
   - **Policies take 15-30 minutes to take effect** after deployment
   - Check enforcement mode is set to "Default" (not "DoNotEnforce")
   - Verify policy assignment scope
   - Existing resources are NOT blocked (only new deployments)

### Debug Commands

```bash
# Check specific policy assignments
az policy assignment show --name "allowed-regions-sweden-central-tf"
az policy assignment show --name "rg-location-policy-assignment"

# List all policy assignments
az policy assignment list --output table

# Check compliance state
az policy state list --query "[?complianceState=='NonCompliant']"

# View Terraform state
terraform show
terraform state list
```

## Why Two Policies?

You might wonder why we need both policies. Here's why:

| Policy | Controls | Example |
|--------|----------|---------|
| **Allowed Locations** | Resources (VMs, VNets, Storage, etc.) | Blocks VM deployment in East US |
| **Allowed RG Locations** | Resource Groups | Blocks creating RG in East US |

**Both are needed** because:
- Someone could create an RG in Sweden Central, then deploy resources to East US ❌
- Having both ensures **complete regional control** at every level ✅

## Integration

This policy set can be combined with other policy categories:

- **Security Baseline**: Add encryption and access control policies
- **Cost Management**: Include resource SKU and tagging policies  
- **Compliance**: Integrate with regulatory compliance frameworks

See the parent `policies/` folder for examples of other policy categories.