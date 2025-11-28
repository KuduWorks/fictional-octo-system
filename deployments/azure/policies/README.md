# Azure Policies - Terraform-Based Policy Management

This folder contains Azure Policy definitions and assignments organized by policy category. All policies are deployed using **Terraform** for infrastructure as code consistency.

## Folder Structure

```
policies/
├── region-control/           # ✅ Geographic restrictions (Terraform)
│   ├── main.tf
│   ├── terraform.tfvars
│   ├── TERRAFORM.md
│   └── README.md
├── iso27001-crypto/          # ✅ ISO 27001 A.10.1.1 Cryptography Compliance (Terraform)
│   ├── main.tf              # 12 encryption policies (Storage, SQL, KeyVault, VMs, Disks, Kusto, AKS)
│   ├── terraform.tfvars
│   └── README.md
├── vm-encryption/            # ⚠️ DEPRECATED - Moved to iso27001-crypto/
│   └── MOVED.md             # Migration instructions
├── security-baseline/        # 🚧 Planned - Security hardening policies
├── cost-management/          # 🚧 Planned - Cost optimization policies
├── shared/                   # Legacy scripts (not used with Terraform)
└── README.md                 # This file
```

## Policy Categories

### 1. Region Control (`region-control/`) ✅ Active
- **Purpose**: Geographic restrictions and data residency compliance
- **Deployment**: Terraform
- **Policies**: 2 built-in policy assignments
  - Allowed locations for resources
  - Allowed locations for resource groups
- **Target Region**: Sweden Central
- **Status**: Deployed and enforced

### 2. ISO 27001 Cryptography Compliance (`iso27001-crypto/`) ✅ Active
- **Purpose**: ISO 27001 A.10.1.1 Cryptographic Controls compliance
- **Deployment**: Terraform
- **Policies**: 26 policies (11 built-in, 15 custom)
  - **Storage Accounts** (4): HTTPS required, TLS 1.2+, no public access, CMK encryption
  - **Application Gateway** (2): HTTPS only, TLS 1.3 minimum
  - **App Services** (3): HTTPS only, TLS 1.2+ minimum
  - **SQL Databases** (1): TDE with customer-managed keys
  - **Key Vault** (2): Soft delete, purge protection
  - **Managed Disks** (1): Customer-managed key encryption required
  - **Data Explorer/Kusto** (2): Disk encryption, CMK required
  - **Azure Kubernetes Service** (2): Policy add-on, encryption at host
  - **Virtual Machines** (1): EncryptionAtHost OR Azure Disk Encryption
  - **Database Services** (2): MySQL/PostgreSQL SSL enforcement
  - **Other Services** (6): Cosmos DB, Service Bus, Event Hub, Container Registry, ML Workspace, Cognitive Services CMK
- **Status**: Deployed and enforced
- **Compliance Standard**: ISO 27001:2013 A.10.1.1

### 3. VM Encryption (`vm-encryption/`) ⚠️ DEPRECATED
- **Status**: Moved to `iso27001-crypto/`
- **Migration**: See `vm-encryption/MOVED.md` for details
- **Action Required**: Use `iso27001-crypto/` for all encryption policies

### 4. Security Baseline (`security-baseline/`) 🚧 Planned
- **Purpose**: Security hardening and compliance (future)
- **Potential Policies**: 
  - Network security groups required
  - Azure Defender enabled
  - Managed identities for authentication
  - Audit logging enabled

### 5. Cost Management (`cost-management/`) 🚧 Planned
- **Purpose**: Cost optimization and resource governance (future)
- **Potential Policies**:
  - VM SKU restrictions
  - Required cost center tags
  - Auto-shutdown for dev resources

## Prerequisites

1. **Terraform** >= 1.0 installed
2. **Azure CLI** installed and configured (`az login`)
3. **Appropriate permissions**:
   - `Policy Contributor` role at subscription level
   - `User Access Administrator` or `Owner` role (for managed identity assignments)
4. **Active Azure subscription**

## Quick Start

### Deploy Region Control Policies

```bash
cd deployments/azure/policies/region-control
terraform init
terraform plan
terraform apply
```

### Deploy ISO 27001 Cryptography Policies

```bash
cd deployments/azure/policies/iso27001-crypto
terraform init
terraform plan
terraform apply
```

### Deploy All Active Policies

```bash
# Region control
cd deployments/azure/policies/region-control
terraform init && terraform apply -auto-approve

# ISO 27001 crypto compliance
cd ../iso27001-crypto
terraform init && terraform apply -auto-approve
```

## Deployment Options

### Terraform Deployment (Primary Method)

All policies use Terraform for consistent infrastructure as code:

```bash
# Navigate to specific policy category
cd deployments/azure/policies/<policy-category>

# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Deploy policies
terraform apply
```

### Audit Mode Deployment (Recommended First)

Start with audit-only mode to assess compliance without blocking resources:

**Edit `terraform.tfvars`:**
```hcl
enforcement_mode = "DoNotEnforce"  # Audit only, no blocking
```

Then deploy:
```bash
terraform apply
```

Review compliance for 1-2 weeks, then switch to enforcement:
```hcl
enforcement_mode = "Default"  # Enforce policies
```

```bash
terraform apply
```

## Configuration

### Region Control Configuration

**Edit `region-control/terraform.tfvars`:**
```hcl
allowed_regions = ["swedencentral", "swedensouth"]
enforcement_mode = "Default"  # or "DoNotEnforce" for audit mode
# subscription_id = "your-subscription-id"  # Optional, auto-detected if not set
```

### ISO 27001 Crypto Configuration

**Edit `iso27001-crypto/terraform.tfvars`:**
```hcl
enforcement_mode = "DoNotEnforce"  # Start with audit mode
# subscription_id = "your-subscription-id"  # Optional, auto-detected if not set
```

### Understanding Enforcement Modes

- **`Default`**: Policy is enforced
  - `Deny` policies: Block non-compliant resource creation
  - `AuditIfNotExists` policies: Create audit logs for non-compliance
  - `DeployIfNotExists` policies: Auto-remediate resources
  
- **`DoNotEnforce`**: Audit mode only
  - All policies evaluate compliance
  - No resources are blocked or modified
  - Compliance state tracked in Azure Policy dashboard
  - **Recommended for initial deployment**

## Pre-Deployment Verification

### Terraform Validation

Before deploying, validate your Terraform configuration:

```bash
# Navigate to policy folder
cd deployments/azure/policies/region-control  # or iso27001-crypto

# Initialize Terraform
terraform init

# Validate syntax
terraform validate

# Preview changes
terraform plan

# See detailed execution plan
terraform plan -out=tfplan
terraform show tfplan
```

### Azure CLI Verification

Check your Azure environment:

```bash
# Verify login and subscription
az account show

# Check existing policy assignments
az policy assignment list \
  --query "[].{Name:name, DisplayName:displayName, Scope:scope}" \
  -o table

# Check for conflicts with existing policies
az policy assignment list \
  --query "[?contains(name, 'region') || contains(name, 'crypto')].{Name:name, DisplayName:displayName}" \
  -o table
```

## Post-Deployment Verification

### Check Terraform State

```bash
# View deployed resources
terraform show

# List outputs
terraform output

# Check specific output
terraform output policy_assignments
```

### Verify Policy Assignments

```bash
# List all policy assignments
az policy assignment list \
  --query "[].{Name:name, DisplayName:displayName, Scope:scope, EnforcementMode:enforcementMode}" \
  -o table

# Check region control policies
az policy assignment list \
  --query "[?contains(name, 'region')].{Name:name, DisplayName:displayName, EnforcementMode:enforcementMode}" \
  -o table

# Check ISO 27001 crypto policies
az policy assignment list \
  --query "[?contains(displayName, 'ISO 27001')].{Name:name, DisplayName:displayName, EnforcementMode:enforcementMode}" \
  -o table
```

### Test Policy Enforcement

#### Test Region Control

```bash
# This should FAIL (non-allowed region)
az group create --name test-rg-eastus --location "eastus"

# This should SUCCEED (allowed region)
az group create --name test-rg-sweden --location "swedencentral"

# Cleanup
az group delete --name test-rg-sweden --yes --no-wait
```

#### Test VM Encryption Audit

```bash
# Deploy a VM without encryption (will be created but flagged as non-compliant)
az vm create \
  --resource-group test-rg-sweden \
  --name test-vm-no-encryption \
  --image Ubuntu2204 \
  --size Standard_B2s

# Check compliance state (may take 5-10 minutes for evaluation)
az policy state list \
  --resource-group test-rg-sweden \
  --query "[?policyDefinitionName=='custom-vm-encryption-audit'].{Resource:resourceId, ComplianceState:complianceState}" \
  -o table
```

### Monitor Compliance Dashboard

View compliance in Azure Portal:
```
Azure Portal → Policy → Compliance
```

Filter by:
- Assignment: "ISO 27001" or "region"
- Compliance State: "Non-compliant"

## Policy Effects Timeline

- **Immediate**: New resource deployments are restricted
- **Existing Resources**: Not affected (policies are not retroactive)
- **Resource Groups**: Must be created in allowed regions
- **Resource Dependencies**: All child resources inherit location restrictions

## Troubleshooting

### Common Issues

1. **Terraform State Lock**
   ```
   Error: Error acquiring the state lock
   ```
   **Solution**: 
   ```bash
   # Force unlock (use with caution)
   terraform force-unlock <LOCK_ID>
   ```

2. **Insufficient Permissions**
   ```
   Error: You do not have authorization to perform action 'Microsoft.Authorization/policyAssignments/write'
   ```
   **Solution**: Ensure you have `Policy Contributor` role:
   ```bash
   az role assignment list --assignee $(az account show --query user.name -o tsv) \
     --query "[?roleDefinitionName=='Policy Contributor'].{Role:roleDefinitionName, Scope:scope}" -o table
   ```

3. **Policy Requires Managed Identity**
   ```
   Error: The policy assignment requires a managed identity
   ```
   **Solution**: Add `identity` block to policy assignment in Terraform:
   ```hcl
   identity {
     type = "SystemAssigned"
   }
   ```

4. **Region Policy Not Blocking Resources**
   ```
   Resource created in non-allowed region
   ```
   **Solution**: 
   - Check enforcement mode is `Default` (not `DoNotEnforce`)
   - Verify policy assignment scope includes the subscription
   - Wait 10-15 minutes for policy to propagate

5. **Terraform Provider Authentication**
   ```
   Error: Unable to authenticate using the Azure CLI
   ```
   **Solution**:
   ```bash
   az login
   az account set --subscription "your-subscription-id"
   ```

### Debugging Commands

```bash
# Check Terraform state
terraform state list
terraform state show <resource>

# View policy compliance
az policy state list \
  --filter "complianceState eq 'NonCompliant'" \
  --query "[].{Resource:resourceId, Policy:policyDefinitionName, State:complianceState}" \
  -o table

# View specific policy assignment
az policy assignment show --name "allowed-regions-sweden-central"

# Check policy definition
az policy definition show --name "custom-vm-encryption-audit"

# View policy events (recent evaluations)
az policy event list \
  --filter "complianceState eq 'NonCompliant'" \
  --top 20 \
  -o table
```

### Re-deploying Policies

If you need to recreate policies:

```bash
# Destroy current deployment
terraform destroy

# Re-deploy
terraform apply
```

## Cleanup

### Remove Specific Policy Set

#### Region Control Policies
```bash
cd deployments/azure/policies/region-control
terraform destroy
```

#### ISO 27001 Crypto Policies
```bash
cd deployments/azure/policies/iso27001-crypto
terraform destroy
```

### Remove All Policies

```bash
# Region control
cd deployments/azure/policies/region-control
terraform destroy -auto-approve

# ISO 27001 crypto
cd ../iso27001-crypto
terraform destroy -auto-approve
```

### Manual Cleanup (if needed)

If Terraform state is lost or corrupted:

```bash
# List and delete all policy assignments
az policy assignment list \
  --query "[?contains(name, 'iso27001') || contains(name, 'region')].name" \
  -o tsv | while read name; do
    az policy assignment delete --name "$name"
  done

# Delete custom policy definitions
az policy definition list \
  --query "[?policyType=='Custom'].name" \
  -o tsv | while read name; do
    az policy definition delete --name "$name"
  done
```

### Verify Cleanup

```bash
# Check no policies remain
az policy assignment list \
  --query "[?contains(name, 'iso27001') || contains(name, 'region')].{Name:name, DisplayName:displayName}" \
  -o table

# Should return empty or no matching policies
```

## Policy Details by Category

### Region Control
- **Deployment Guide**: [region-control/README.md](region-control/README.md)
- **Terraform Guide**: [region-control/TERRAFORM.md](region-control/TERRAFORM.md)
- **Policies**: 2 built-in assignments
- **Effect**: Deny (blocks non-compliant resources)
- **Scope**: Subscription-level

### ISO 27001 Cryptography Compliance
- **Deployment Guide**: [iso27001-crypto/README.md](iso27001-crypto/README.md)
- **Policies**: 12 policies (7 built-in, 5 custom)
- **Resources Covered**: Storage, SQL, Key Vault, Disks, Kusto, AKS, VMs
- **Effects**: Mixed (Audit, AuditIfNotExists, DeployIfNotExists, Deny)
- **Compliance Standard**: ISO 27001:2013 A.10.1.1
- **Scope**: Subscription-level

## Migration Notes

### VM Encryption Policy Migration
The standalone `vm-encryption/` policy has been consolidated into `iso27001-crypto/` for better organization. 

- **Old location**: `deployments/azure/policies/vm-encryption/`
- **New location**: `deployments/azure/policies/iso27001-crypto/`
- **Migration guide**: [vm-encryption/MOVED.md](vm-encryption/MOVED.md)

If you previously deployed the standalone VM encryption policy:
1. Destroy it: `cd vm-encryption && terraform destroy`
2. Deploy consolidated policies: `cd ../iso27001-crypto && terraform apply`

## Best Practices

1. **Start with Audit Mode**
   - Deploy all policies with `enforcement_mode = "DoNotEnforce"`
   - Monitor compliance for 1-2 weeks
   - Remediate non-compliant resources
   - Switch to `enforcement_mode = "Default"`

2. **Use Terraform Workspaces** (optional)
   ```bash
   # Create separate workspaces for different environments
   terraform workspace new dev
   terraform workspace new prod
   ```

3. **Version Control**
   - Commit `.terraform.lock.hcl` to ensure consistent provider versions
   - Do NOT commit `.terraform/` directory or `*.tfstate` files
   - Store state remotely (Azure Storage) for team collaboration

4. **Policy Testing**
   - Always test in non-production subscription first
   - Use `terraform plan` to preview changes
   - Verify compliance dashboard after deployment

5. **Documentation**
   - Update `terraform.tfvars` with clear comments
   - Document any custom policy modifications
   - Track policy assignments in your CMDB

## Security Considerations

1. **Managed Identities**: Policies with `DeployIfNotExists` effect use system-assigned managed identities for remediation
2. **Least Privilege**: Custom policies implement minimal required permissions
3. **Audit Trail**: All policy actions logged in Azure Activity Log
4. **State File Security**: Terraform state may contain sensitive data - use remote backend with encryption
5. **Compliance Reporting**: Policies support ISO 27001, Azure Security Benchmark, and custom compliance frameworks

## Additional Resources

### Azure Policy Documentation
- [Azure Policy Overview](https://docs.microsoft.com/en-us/azure/governance/policy/overview)
- [Policy Definition Structure](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure)
- [Policy Assignment Structure](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/assignment-structure)
- [Built-in Policy Definitions](https://docs.microsoft.com/en-us/azure/governance/policy/samples/built-in-policies)
- [Policy Effects](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/effects)

### Terraform Azure Provider
- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [azurerm_policy_definition](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/policy_definition)
- [azurerm_subscription_policy_assignment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subscription_policy_assignment)

### Compliance Standards
- [ISO 27001:2013](https://www.iso.org/standard/54534.html)
- [Azure Security Benchmark](https://docs.microsoft.com/en-us/security/benchmark/azure/)
- [Microsoft Cloud Adoption Framework](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/)

### Azure Regions
- [Sweden Central Region Overview](https://azure.microsoft.com/en-us/explore/global-infrastructure/geographies/#geographies)
- [Azure Geographies](https://azure.microsoft.com/en-us/global-infrastructure/geographies/)

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review individual policy folder README files:
   - [region-control/README.md](region-control/README.md)
   - [iso27001-crypto/README.md](iso27001-crypto/README.md)
3. Review Terraform documentation for azurerm provider
4. Check Azure Activity Logs for policy evaluation details
5. Consult Azure Policy documentation
6. Contact your Azure administrator or cloud governance team

## Contributing

When adding new policy categories:
1. Create a new folder under `deployments/azure/policies/`
2. Include these files:
   - `main.tf` - Terraform configuration
   - `terraform.tfvars` - Variable defaults
   - `README.md` - Policy documentation
3. Update this README with new category information
4. Test thoroughly in non-production environment
5. Document compliance standards addressed

---

**Last Updated**: October 19, 2025  
**Terraform Version**: >= 1.0  
**AzureRM Provider**: ~> 3.0  
**Active Policy Sets**: Region Control, ISO 27001 Cryptography