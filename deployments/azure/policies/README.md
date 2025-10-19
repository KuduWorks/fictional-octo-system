# Azure Policies - Recommended Folder Structure

This folder contains Azure Policy definitions, assignments, and initiatives organized by policy category. This structure supports scalable policy management across multiple domains.

## Folder Structure

```
policies/
├── region-control/           # Geographic and compliance policies
│   ├── arm-template.json
│   ├── arm-template.parameters.json
│   ├── deploy-arm.sh
│   ├── deploy-arm.ps1
│   ├── main.parameters.json # Legacy parameters file
│   ├── main.tf              # Alternative: Terraform
│   └── README.md
├── security-baseline/        # Security and compliance policies
│   ├── arm-template.json
│   └── README.md            # (Coming soon)
├── cost-management/          # Cost optimization policies
│   ├── arm-template.json
│   └── README.md            # (Coming soon)
├── shared/                   # Common utilities and scripts
│   └── deploy-all.sh
├── deploy-cli.sh             # Pure Azure CLI deployment (no templates)
├── deploy.sh                 # Legacy deployment script
├── deploy.ps1                # Legacy PowerShell script
├── verify-cli.sh             # CLI verification script
└── README.md                 # This file
```

## Policy Categories

### 1. Region Control (`region-control/`)
- **Purpose**: Geographic restrictions and data residency
- **Policies**: Allowed locations, resource group locations
- **Example**: Restrict deployments to Sweden Central

### 2. Security Baseline (`security-baseline/`)
- **Purpose**: Security hardening and compliance
- **Policies**: Encryption, network security, identity management
- **Examples**: 
  - Require encryption at rest
  - Block public blob access
  - Require Azure Defender
  - Enforce strong passwords

### 3. Cost Management (`cost-management/`)
- **Purpose**: Cost optimization and resource governance
- **Policies**: Resource sizing, spending limits, unused resources
- **Examples**:
  - Limit VM SKUs
  - Require cost center tags
  - Auto-shutdown dev VMs

### 4. Shared (`shared/`)
- **Purpose**: Common utilities and deployment scripts
- **Contents**: Multi-policy deployment scripts, validation tools

## Prerequisites

1. **Azure CLI** installed and configured
2. **Appropriate permissions**:
   - `Policy Contributor` role at subscription level
   - `User Access Administrator` or `Owner` role (for managed identity assignments)
3. **Active Azure subscription**

## Deployment Options

### Option 1: ARM Template Deployment (Recommended)

Deploy specific policy categories using ARM templates:

```bash
# Navigate to specific policy category
cd deployments/azure/policies/region-control

# Deploy using the ARM deployment script
./deploy-arm.sh

# Or deploy manually
az deployment sub create \
    --location swedencentral \
    --template-file arm-template.json \
    --parameters arm-template.parameters.json \
    --name "region-control-$(date +%Y%m%d-%H%M%S)"
```

### Option 2: Pure Azure CLI Deployment

Deploy using direct Azure CLI commands (no templates required):

```bash
# Navigate to the policies directory
cd deployments/azure/policies

# Verify before deploying
chmod +x verify-cli.sh
./verify-cli.sh

# Deploy using CLI commands
chmod +x deploy-cli.sh
./deploy-cli.sh
```

### Option 3: Deploy All Policy Categories

Deploy all available policy categories at once:

```bash
# Navigate to shared utilities
cd deployments/azure/policies/shared

# Deploy all policies
chmod +x deploy-all.sh
./deploy-all.sh
```

### Option 4: Terraform (Alternative)

For infrastructure as code using Terraform:

```bash
cd deployments/azure/policies/region-control
terraform init
terraform plan
terraform apply
```

## Configuration

### Modifying Allowed Regions

To allow additional regions, modify the parameters in the appropriate files:

**For ARM Template:**
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

**For CLI Deployment:**
Edit the `ALLOWED_REGIONS` variable in `deploy-cli.sh`:
```bash
ALLOWED_REGIONS='["swedencentral", "swedensouth"]'
```

### Enforcement Modes

- **Default**: Policy is enforced, non-compliant resources are denied
- **DoNotEnforce**: Policy is evaluated but not enforced (audit mode)

**For ARM Template:**
```json
{
  "parameters": {
    "enforcementMode": {
      "value": "DoNotEnforce"
    }
  }
}
```

**For CLI Deployment:**
Edit the `ENFORCEMENT_MODE` variable in `deploy-cli.sh`:
```bash
ENFORCEMENT_MODE="DoNotEnforce"
```

## Pre-Deployment Verification

Before deploying, it's recommended to verify your configuration:

### Option 1: CLI Verification Script

```bash
# Navigate to the policies directory
cd deployments/azure/policies

# Run comprehensive verification
chmod +x verify-cli.sh
./verify-cli.sh
```

This script checks:
- ✅ Azure CLI installation and login status
- ✅ Required permissions (Policy Contributor role)
- ✅ Existing policies (conflict detection)
- ✅ Policy JSON syntax validation
- ✅ Built-in policy availability
- ✅ Configuration review and impact estimation

### Option 2: ARM Template Validation

For ARM template deployments:

```bash
cd region-control/

# Validate template syntax
az deployment sub validate \
    --location swedencentral \
    --template-file arm-template.json \
    --parameters arm-template.parameters.json

# Preview exact changes (what-if)
az deployment sub what-if \
    --location swedencentral \
    --template-file arm-template.json \
    --parameters arm-template.parameters.json \
    --name "test-$(date +%Y%m%d-%H%M%S)"
```

### Option 3: Quick CLI Checks

```bash
# Check login and permissions
az account show

# Check existing policies
az policy assignment list --query "[?contains(name, 'region')].{Name:name, DisplayName:displayName}" -o table

# Check if built-in policy exists
az policy definition show --name "e56962a6-4747-49cd-b67b-bf8b01975c4c"
```

## Post-Deployment Verification

### 1. List Policy Assignments

```bash
az policy assignment list \
    --query "[?contains(name, 'allowed-regions') || contains(name, 'rg-location') || contains(name, 'region-control')].{Name:name, DisplayName:displayName, Scope:scope, EnforcementMode:enforcementMode}" \
    --output table
```

### 2. Test Policy Enforcement

Try creating a resource in a non-allowed region:

```bash
# This should fail due to policy enforcement
az group create --name test-rg --location "eastus"
```

### 3. Verify Allowed Region Works

```bash
# This should succeed
az group create --name test-rg-sweden --location "swedencentral"
az group delete --name test-rg-sweden --yes --no-wait
```

## Policy Effects Timeline

- **Immediate**: New resource deployments are restricted
- **Existing Resources**: Not affected (policies are not retroactive)
- **Resource Groups**: Must be created in allowed regions
- **Resource Dependencies**: All child resources inherit location restrictions

## Troubleshooting

### Common Issues

1. **Insufficient Permissions**
   ```
   Error: You do not have authorization to perform action 'Microsoft.Authorization/policyAssignments/write'
   ```
   **Solution**: Ensure you have `Policy Contributor` role at subscription level

2. **Template Validation Errors**
   ```
   Error: The template deployment failed with error: 'InvalidTemplate'
   ```
   **Solution**: Check Bicep syntax and parameter values

3. **Policy Conflicts**
   ```
   Error: Resource creation blocked by policy
   ```
   **Solution**: Verify the resource location is in the allowed regions list

### Debugging Commands

```bash
# Check policy compliance
az policy state list --query "[?complianceState=='NonCompliant']"

# View policy assignment details
az policy assignment show --name "allowed-regions-sweden-central"

# Check deployment status (for ARM template deployments)
az deployment sub show --name "your-deployment-name"

# List all custom policy definitions
az policy definition list --query "[?policyType=='Custom'].{Name:name, DisplayName:displayName}" -o table

# List all policy initiatives
az policy set-definition list --query "[?policyType=='Custom'].{Name:name, DisplayName:displayName}" -o table
```

## Cleanup

To remove the policies, choose the appropriate method based on how they were deployed:

### For CLI Deployed Policies

```bash
# Delete policy assignments
az policy assignment delete --name "allowed-regions-sweden-central"
az policy assignment delete --name "rg-location-policy-assignment"
az policy assignment delete --name "region-control-initiative-assignment"

# Delete custom policy definitions
az policy definition delete --name "custom-rg-location-policy"

# Delete policy set definition
az policy set-definition delete --name "region-control-initiative"
```

### For ARM Template Deployed Policies

```bash
# Delete policy assignments (ARM template names may differ)
az policy assignment delete --name "allowed-regions-sweden-central-arm"
az policy assignment delete --name "region-control-initiative-assignment"

# Delete custom policy definitions
az policy definition delete --name "custom-rg-location-policy"

# Delete policy set definition
az policy set-definition delete --name "region-control-initiative"
```

### Clean Up All Region-Related Policies

```bash
# List and delete all region-related policy assignments
az policy assignment list --query "[?contains(name, 'region')].name" -o tsv | xargs -I {} az policy assignment delete --name {}

# List and delete custom policy definitions
az policy definition list --query "[?policyType=='Custom' && contains(name, 'region')].name" -o tsv | xargs -I {} az policy definition delete --name {}

# List and delete custom policy set definitions
az policy set-definition list --query "[?policyType=='Custom' && contains(name, 'region')].name" -o tsv | xargs -I {} az policy set-definition delete --name {}
```

## Security Considerations

1. **Managed Identities**: Policies use system-assigned managed identities for secure operations
2. **Least Privilege**: Custom policies implement minimal required permissions
3. **Audit Trail**: All policy actions are logged in Azure Activity Log
4. **Compliance**: Policies support Azure compliance frameworks

## Additional Resources

- [Azure Policy Documentation](https://docs.microsoft.com/en-us/azure/governance/policy/)
- [Policy Definition Structure](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure)
- [Built-in Policy Definitions](https://docs.microsoft.com/en-us/azure/governance/policy/samples/built-in-policies)
- [Sweden Central Region Overview](https://azure.microsoft.com/en-us/explore/global-infrastructure/geographies/#geographies)

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Azure Activity Logs
3. Consult Azure Policy documentation
4. Contact your Azure administrator