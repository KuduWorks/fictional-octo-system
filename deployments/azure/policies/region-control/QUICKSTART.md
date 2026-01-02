# Terraform Deployment Guide for Azure Policies

## Prerequisites

1. **Terraform installed** (version >= 1.0)
   ```bash
   terraform --version
   ```
   
2. **Azure CLI authenticated**
   ```bash
   az login
   az account set --subscription "your-subscription-name-or-id"
   ```

3. **Appropriate Azure permissions**
   - Policy Contributor role at subscription level

## Quick Start

### 1. Navigate to the region-control folder
```bash
cd deployments/azure/policies/region-control
```

### 2. Initialize Terraform
```bash
terraform init
```

This downloads the Azure provider and prepares your working directory.

### 3. Review the configuration
```bash
# View what will be created
terraform plan

# Save the plan to a file for review
terraform plan -out=tfplan
```

### 4. Deploy the policies
```bash
terraform apply

# Or use the saved plan
terraform apply tfplan
```

Type `yes` when prompted to confirm deployment.

### 5. Verify deployment
```bash
# Show current Terraform state
terraform show

# List outputs
terraform output
```

## Configuration

### Customize Variables

Edit `terraform.tfvars` to customize your deployment:

```hcl
allowed_regions = ["swedencentral", "swedensouth"]
policy_assignment_name = "my-custom-policy-name"
enforcement_mode = "DoNotEnforce"  # Use for testing
```

### Available Variables

- `allowed_regions` - List of allowed Azure regions (default: `["swedencentral"]`)
- `policy_assignment_name` - Name for policy assignment (default: `"allowed-regions-policy"`)
- `policy_assignment_display_name` - Display name (default: `"Allowed Regions Policy - Sweden Central"`)
- `enforcement_mode` - `"Default"` or `"DoNotEnforce"` (default: `"Default"`)
- `subscription_id` - Target subscription ID (optional, uses current by default)

### Command-line Variable Override

```bash
# Override variables on the command line
terraform apply \
  -var="allowed_regions=[\"swedencentral\",\"swedensouth\"]" \
  -var="enforcement_mode=DoNotEnforce"
```

## What Gets Deployed

Terraform will create **2 built-in policy assignments**:

1. ✅ **Allowed Locations Policy Assignment** - `allowed-regions-sweden-central-tf`
   - Uses built-in policy: `e56962a6-4747-49cd-b67b-bf8b01975c4c`
   - Controls where resources (VMs, VNets, storage, etc.) can be deployed

2. ✅ **Allowed Resource Group Locations Policy Assignment** - `rg-location-policy-assignment`
   - Uses built-in policy: `e765b5de-1225-4ba3-bd56-1ac6695af988`
   - Controls where resource groups can be created

3. ✅ **System-Assigned Managed Identities** for each assignment

**Note:** Both policies use Azure's built-in policy definitions, so no custom policies are created.

## Terraform State Management

### View Current State
```bash
terraform state list
terraform state show azurerm_subscription_policy_assignment.allowed_locations_assignment
terraform state show azurerm_subscription_policy_assignment.rg_location_assignment
```

### Remote State (Recommended for Teams)

For production, use remote state storage:

1. Copy the backend template:
   ```bash
   cp backend.tf.example backend.tf
   ```

2. Edit `backend.tf` with your storage account details:
   ```hcl
   terraform {
     backend "azurerm" {
       resource_group_name  = "<your-rg-name>"
       storage_account_name = "tfstate20251013"
       container_name       = "tfstate"
       key                  = "policies/region-control.tfstate"
     }
   }
   ```

3. Migrate existing state:
   ```bash
   terraform init -migrate-state
   ```

**Note:** `backend.tf` is excluded from git to keep credentials private.

## Validation & Testing

### Validate Configuration
```bash
# Check syntax
terraform validate

# Format code
terraform fmt

# Lint with tflint (if installed)
tflint
```

### Test Policy Enforcement
```bash
# After deployment, WAIT 15-30 MINUTES for policies to take effect

# This should FAIL - resource group in wrong region
az group create --name "test-blocked-rg" --location "eastus"

# This should SUCCEED - resource group in allowed region
az group create --name "test-allowed-rg" --location "swedencentral"

# This should FAIL - VNet in wrong region
az network vnet create \
    --name "test-vnet" \
    --resource-group "test-allowed-rg" \
    --location "eastus" \
    --address-prefix "10.0.0.0/16"

# This should SUCCEED - VNet in allowed region
az network vnet create \
    --name "test-vnet" \
    --resource-group "test-allowed-rg" \
    --location "swedencentral" \
    --address-prefix "10.0.0.0/16"

# Cleanup
az group delete --name "test-allowed-rg" --yes --no-wait
```

## Updating Policies

### Modify Configuration
1. Edit `terraform.tfvars` or `main.tf`
2. Review changes: `terraform plan`
3. Apply updates: `terraform apply`

### Example: Add More Regions
```bash
# Edit terraform.tfvars
allowed_regions = ["swedencentral", "swedensouth", "northeurope"]

# Preview changes
terraform plan

# Apply changes
terraform apply
```

## Cleanup

### Remove All Policies
```bash
# Destroy all resources managed by Terraform
terraform destroy

# Or target specific resources
terraform destroy -target=azurerm_subscription_policy_assignment.allowed_locations_assignment
```

### Verify Cleanup
```bash
# Verify policy assignments are removed
az policy assignment list --query "[?contains(name, 'allowed-regions') || contains(name, 'rg-location')].name" -o table
```

## Troubleshooting

### Common Issues

**Issue: Provider authentication error**
```
Error: building AzureRM Client: obtain subscription() from Azure CLI...
```
**Solution:**
```bash
az login
az account set --subscription "your-subscription-id"
```

**Issue: Insufficient permissions**
```
Error: authorization failed for policy assignment
```
**Solution:** Ensure you have `Policy Contributor` role:
```bash
az role assignment list --assignee "your-email@domain.com" --query "[?roleDefinitionName=='Policy Contributor']"
```

**Issue: State lock error**
```
Error: acquiring lock for workspace
```
**Solution:** If using remote state with lock:
```bash
terraform force-unlock <lock-id>
```

### Debug Mode
```bash
# Enable verbose logging
export TF_LOG=DEBUG
terraform apply

# Save logs to file
export TF_LOG_PATH=./terraform.log
terraform apply
```

## Advantages of Terraform over CLI/PowerShell

| Feature | Terraform | CLI/PowerShell |
|---------|-----------|----------------|
| **State Management** | ✅ Tracks all resources | ❌ No state tracking |
| **Idempotent** | ✅ Safe to re-run | ⚠️ May cause duplicates |
| **Preview Changes** | ✅ `terraform plan` | ⚠️ Limited with `--what-if` |
| **Dependency Management** | ✅ Automatic | ❌ Manual ordering |
| **Version Control** | ✅ Easy to diff changes | ⚠️ Harder to track |
| **Rollback** | ✅ Easy with state | ❌ Manual cleanup |
| **Documentation** | ✅ Self-documenting code | ⚠️ Requires separate docs |

## Best Practices

1. **Always run `terraform plan` first** before applying
2. **Use remote state** for team collaboration
3. **Version control** your `.tf` and `.tfvars` files
4. **Use variables** instead of hardcoding values
5. **Enable detailed logging** for troubleshooting
6. **Regular state backups** (automatic with remote state)
7. **Use workspaces** for multiple environments:
   ```bash
   terraform workspace new dev
   terraform workspace new prod
   terraform workspace select dev
   ```

## Additional Resources

- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Policy with Terraform](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/policy_definition)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)

## Quick Reference Commands

```bash
# Initialize
terraform init

# Validate
terraform validate

# Plan
terraform plan -out=tfplan

# Apply
terraform apply tfplan

# Show outputs
terraform output

# List resources
terraform state list

# Destroy
terraform destroy

# Format code
terraform fmt -recursive
```