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
│   ├── main.bicep           # Alternative: Bicep template
│   ├── main.tf              # Alternative: Terraform
│   └── README.md
├── security-baseline/        # Security and compliance policies
│   ├── arm-template.json
│   ├── parameters/
│   │   ├── prod.parameters.json
│   │   ├── dev.parameters.json
│   │   └── test.parameters.json
│   └── README.md
├── cost-management/          # Cost optimization policies
│   ├── arm-template.json
│   ├── parameters/
│   └── README.md
├── shared/                   # Common utilities and scripts
│   ├── deploy-all.sh
│   ├── validate-all.sh
│   └── policy-utilities.ps1
└── README.md                # This file
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

### Option 1: Using Bash Script (Recommended for Linux/macOS/WSL)

```bash
# Navigate to the policies directory
cd deployments/azure/policies

# Make the script executable
chmod +x deploy.sh

# Run the deployment
./deploy.sh
```

### Option 2: Using PowerShell Script (Recommended for Windows)

```powershell
# Navigate to the policies directory
Set-Location deployments\azure\policies

# Run the deployment
.\deploy.ps1

# For what-if analysis only (preview changes)
.\deploy.ps1 -WhatIf

# For automated deployment without confirmation
.\deploy.ps1 -Force
```

### Option 3: Manual Azure CLI Deployment

```bash
# Set variables
SUBSCRIPTION_ID="your-subscription-id"
LOCATION="swedencentral"
DEPLOYMENT_NAME="azure-policy-sweden-central-$(date +%Y%m%d-%H%M%S)"

# Set subscription
az account set --subscription $SUBSCRIPTION_ID

# Validate template
az deployment sub validate \
    --location $LOCATION \
    --template-file main.bicep \
    --parameters main.parameters.json

# Preview deployment
az deployment sub what-if \
    --location $LOCATION \
    --template-file main.bicep \
    --parameters main.parameters.json \
    --name $DEPLOYMENT_NAME

# Deploy
az deployment sub create \
    --location $LOCATION \
    --template-file main.bicep \
    --parameters main.parameters.json \
    --name $DEPLOYMENT_NAME
```

## Configuration

### Modifying Allowed Regions

To allow additional regions, modify the `allowedRegions` parameter in `main.parameters.json`:

```json
{
  "allowedRegions": {
    "value": [
      "swedencentral",
      "swedensouth"
    ]
  }
}
```

### Enforcement Modes

- **Default**: Policy is enforced, non-compliant resources are denied
- **DoNotEnforce**: Policy is evaluated but not enforced (audit mode)

Modify the `enforcementMode` parameter in `main.parameters.json`:

```json
{
  "enforcementMode": {
    "value": "DoNotEnforce"
  }
}
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

# Check deployment status
az deployment sub show --name "your-deployment-name"
```

## Cleanup

To remove the policies:

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