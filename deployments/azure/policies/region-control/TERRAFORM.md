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

Terraform will create:

1. ✅ **Custom Policy Definition** - `custom-rg-location-policy`
   - Controls where resource groups can be created

2. ✅ **Policy Set Definition** - `region-control-initiative`
   - Groups related region policies together

3. ✅ **Policy Assignments** (3 assignments):
   - Built-in allowed locations policy
   - Custom resource group location policy
   - Policy initiative assignment

4. ✅ **System-Assigned Managed Identities** for each assignment

## Terraform State Management

### View Current State
```bash
terraform state list
terraform state show azurerm_policy_definition.custom_rg_location_policy
```

### Remote State (Recommended for Teams)

For production, use remote state storage:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "tfstate20251013"
    container_name       = "tfstate"
    key                  = "azure-policies.tfstate"
  }
}
```

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
# After deployment, test the policy
az group create --name "test-blocked" --location "eastus"  # Should fail
az group create --name "test-allowed" --location "swedencentral"  # Should succeed
az group delete --name "test-allowed" --yes --no-wait
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
az policy assignment list --query "[?contains(name, 'allowed-regions')].name" -o table
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