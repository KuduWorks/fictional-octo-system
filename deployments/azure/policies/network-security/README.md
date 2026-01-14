# Azure Network Security Policies

Terraform-managed Azure policies enforcing network security hardening through **NSG requirements on VM network interfaces** and **denying public IPs on VMs** to enforce Azure Bastion for remote access.

## Overview

This module deploys network security policies focused on VM-level protection:

1. **NSG Required on VM Network Interfaces** (Custom Policy)
   - Audits or denies VM NIC creation without an associated NSG
   - Applies to both internet-facing and internal VMs
   - Ensures all VMs have network-level security controls
   - Configurable effect: audit (default) or deny

2. **No Public IPs on VMs** (Built-in Policy)
   - Denies public IP addresses on virtual machines
   - Enforces Azure Bastion for secure remote access
   - Reduces attack surface and internet exposure

Additionally, this module provides:
- **Exemption Framework**: For resources legitimately requiring public IPs (bastion hosts, NAT gateways)
- **Expiration Monitoring**: Automated alerts 60 days before exemptions expire
- **Audit Mode Support**: Deploy in audit-only mode before enforcement

## Policies Enforced

| Policy | Type | Effect | Enforcement Mode | Compliance Standard |
|--------|------|--------|------------------|---------------------|
| VM NICs must have NSG | Custom | Audit/Deny | Configurable | ISO 27001 A.13.1.3 |
| VMs cannot have public IPs | Built-in | Deny | Configurable | ISO 27001 A.13.1.3 |

## Security Considerations

### State File Security
⚠️ **CRITICAL**: Terraform state files may contain sensitive data including:
- Subscription IDs
- Resource IDs
- Exemption metadata

**Best Practices**:
- ✅ Use remote backend (Azure Storage) with encryption
- ✅ Enable soft delete and versioning on state storage
- ✅ Restrict access using RBAC and private endpoints
- ✅ Never commit `backend.tf` or `terraform.tfvars` to public repos

### Public Repository Safety
This is a **public repository**. Before committing:

```bash
# Always run terraform plan and review output for sensitive data
terraform plan | grep -E "subscription|password|secret|key"

# Verify no sensitive values in committed files
git diff --staged
```

**Protected by `.gitignore`**:
- `backend.tf` (contains storage account details)
- `terraform.tfvars` (contains actual resource IDs and emails)
- `*.tfstate` (contains all resource details)
- Credentials and certificates

**Safe to commit**:
- `*.example` files with placeholder values
- Terraform code (`.tf` files)
- Documentation

## Prerequisites

1. **Azure CLI** authenticated and configured:
   ```bash
   az login
   az account set --subscription "your-subscription-id"
   az account show  # Verify correct subscription
   ```

2. **Terraform** >= 1.0:
   ```bash
   terraform --version
   ```

3. **Azure Permissions**:
   - `Policy Contributor` role at subscription level
   - `Resource Policy Contributor` for exemptions

4. **Remote State Storage** (recommended):
   ```bash
   # Create storage account for Terraform state
   az group create --name rg-tfstate --location swedencentral
   az storage account create --name tfstate<unique-id> --resource-group rg-tfstate --sku Standard_LRS
   az storage container create --name tfstate --account-name tfstate<unique-id>
   ```

## Deployment Steps

### 1. Configure Backend (Optional but Recommended)

```bash
cd deployments/azure/policies/network-security

# Copy backend template
cp backend.tf.example backend.tf

# Edit backend.tf with your storage account details
# Update: resource_group_name, storage_account_name
```

### 2. Configure Variables

```bash
# Copy variables template
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars
# Start with enforcement_mode = "DoNotEnforce" for audit-only
# Add exemptions if needed
```

**Key configuration options**:

```hcl
# Start in audit mode (recommended)
enforcement_mode = "DoNotEnforce"

# After 2-4 weeks of validation, switch to enforcement
# enforcement_mode = "Default"

# Optional: target specific subscription
# subscription_id = "00000000-0000-0000-0000-000000000000"

# Email for exemption expiration alerts
alert_email = "security@yourcompany.com"
```

### 3. Initialize Terraform

```bash
terraform init
```

If using remote backend:
```bash
terraform init -migrate-state
```

### 4. Review Planned Changes

```bash
terraform plan

# Save plan for review
terraform plan -out=tfplan
```

### 5. Deploy Policies

```bash
terraform apply tfplan

# Or without saved plan
terraform apply
```

Type `yes` to confirm.

### 6. Verify Deployment

```bash
# Show outputs
terraform output

# Verify policy assignments
az policy assignment list \
  --query "[?contains(name, 'nsg-required') || contains(name, 'deny-vm-public-ip')].{Name:name, DisplayName:displayName, EnforcementMode:enforcementMode}" \
  --output table

# Check custom policy definition
az policy definition show --name "subnet-nsg-required"
```

## Policy Exemptions

### When to Use Exemptions

Use exemptions **sparingly** and only for resources that:
- Legitimately require public IP addresses (bastion hosts, NAT gateways, public load balancers)
- Have documented compensating security controls
- Cannot use Azure Bastion or alternative secure access methods

### Exemption Requirements

All exemptions **must** include:
1. **Justification**: Clear business/technical reason
2. **Expiration Date**: Maximum 12 months from creation
3. **Compensating Controls**: Alternative security measures (NSG rules, MFA, logging)
4. **Approver**: Email of security team member who approved
5. **Ticket Number**: Reference to approval ticket/request

### Adding an Exemption

1. Identify the full resource ID:
   ```bash
   az vm show --resource-group rg-network --name bastion-vm --query id -o tsv
   ```

2. Edit `terraform.tfvars` and add to `exempted_resources`:

   ```hcl
   exempted_resources = {
     bastion-host = {
       resource_id           = "/subscriptions/<sub-id>/resourceGroups/rg-network/providers/Microsoft.Compute/virtualMachines/bastion-vm"
       justification         = "Azure Bastion host requires public IP for remote access gateway"
       expires_on            = "2027-01-14T23:59:00Z"  # ISO 8601 format
       compensating_controls = "NSG with corporate IP whitelist, Azure MFA enforced, audit logging enabled, JIT access configured"
       approved_by           = "security-lead@company.com"
       ticket_number         = "SEC-2026-001"
     }
   }
   ```

3. Apply changes:
   ```bash
   terraform plan
   terraform apply
   ```

### Exemption Expiration

- Exemptions are **automatically monitored**
- Security team receives **email alerts 60 days** before expiration
- Exemptions **must be reviewed and renewed** or removed before expiry

### Quarterly Review Process

1. List all exemptions:
   ```bash
   az policy exemption list \
     --query "[].{Name:name, DisplayName:displayName, ExpiresOn:expiresOn, Category:exemptionCategory}" \
     --output table
   ```

2. Review each exemption:
   - Is it still needed?
   - Are compensating controls still in place?
   - Can Azure Bastion be used instead?

3. Update or remove in `terraform.tfvars` and apply

## Monitoring and Alerts

### Exemption Expiration Monitoring

When exemptions are configured, the module automatically creates:
- **Log Analytics Workspace**: For running expiration queries
- **Action Group**: Email notifications to security team
- **Scheduled Query Alert**: Checks daily for exemptions expiring within 60 days

Alert query checks:
```kql
PolicyResources
| where type == "microsoft.authorization/policyexemptions"
| where properties.expiryTime != ""
| extend expiryDate = todatetime(properties.expiryTime)
| extend daysUntilExpiry = datetime_diff('day', expiryDate, now())
| where daysUntilExpiry <= 60 and daysUntilExpiry >= 0
```

### Compliance Monitoring

```bash
# View compliance state (wait 15-30 minutes after deployment)
az policy state list \
  --filter "PolicyAssignmentName eq 'nsg-required-on-subnets'" \
  --query "[].{Resource:resourceId, State:complianceState}" \
  --output table

# Summary compliance report
az policy state summarize \
  --filter "PolicyAssignmentName eq 'nsg-required-on-subnets' or PolicyAssignmentName eq 'deny-vm-public-ip'"
```

### Azure Portal

View detailed compliance in Azure Portal:
- Navigate to: **Policy** → **Compliance**
- Filter by assignment name: `nsg-required-on-subnets` or `deny-vm-public-ip`
- Review non-compliant resources

## Testing Policy Enforcement

### Before Enforcement (Audit Mode)

With `enforcement_mode = "DoNotEnforce"`:
- Policies **log violations** but **don't block** deployments
- Non-compliant resources are **flagged** in compliance reports
- Gives time to remediate existing resources

### After Enforcement

With `enforcement_mode = "Default"`:

```bash
# Test NSG policy - Should FAIL (subnet without NSG)
az network vnet create \
  --name test-vnet \
  --resource-group test-rg \
  --location swedencentral \
  --address-prefix 10.0.0.0/16 \
  --subnet-name test-subnet \
  --subnet-prefix 10.0.1.0/24

# Expected error: "Resource 'test-subnet' was disallowed by policy"

# Test public IP policy - Should FAIL (VM with public IP)
az vm create \
  --resource-group test-rg \
  --name test-vm \
  --image Ubuntu2204 \
  --public-ip-address test-vm-ip \
  --location swedencentral

# Expected error: "Virtual machines should not have public IP addresses"

# Compliant deployment - Should SUCCEED
# 1. Create NSG
az network nsg create --resource-group test-rg --name test-nsg --location swedencentral

# 2. Create VNet with NSG on subnet
az network vnet create \
  --name test-vnet \
  --resource-group test-rg \
  --location swedencentral \
  --address-prefix 10.0.0.0/16

az network vnet subnet create \
  --vnet-name test-vnet \
  --resource-group test-rg \
  --name test-subnet \
  --address-prefix 10.0.1.0/24 \
  --network-security-group test-nsg

# 3. Create VM without public IP (use Bastion instead)
az vm create \
  --resource-group test-rg \
  --name test-vm \
  --image Ubuntu2204 \
  --vnet-name test-vnet \
  --subnet test-subnet \
  --public-ip-address "" \
  --location swedencentral
```

### Run Test Script

```powershell
# PowerShell test script (creates test resources and validates policies)
.\test-policies.ps1 -ResourceGroupName "policy-test-rg" -Location "swedencentral"
```

## Switching from Audit to Enforcement

**Recommended Timeline**:
1. **Week 0**: Deploy with `enforcement_mode = "DoNotEnforce"`
2. **Weeks 1-4**: Monitor compliance reports, identify non-compliant resources
3. **Weeks 2-4**: Remediate non-compliant resources (add NSGs, remove public IPs, configure Bastion)
4. **Week 4**: Switch to `enforcement_mode = "Default"`

**Process**:

```bash
# 1. Generate compliance report
az policy state list \
  --filter "PolicyAssignmentName eq 'nsg-required-on-subnets'" \
  --query "[?complianceState=='NonCompliant'].resourceId" \
  --output tsv > non-compliant-resources.txt

# 2. Review and remediate each resource

# 3. Update terraform.tfvars
enforcement_mode = "Default"

# 4. Apply changes
terraform apply
```

## Updating Policies

### Add New Exemption

1. Edit `terraform.tfvars` → add to `exempted_resources`
2. Run `terraform plan` to preview
3. Run `terraform apply`

### Remove Exemption

1. Edit `terraform.tfvars` → remove from `exempted_resources`
2. Run `terraform apply`

### Extend Exemption Expiration

1. Edit `terraform.tfvars` → update `expires_on` date
2. Run `terraform apply`

### Change Enforcement Mode

1. Edit `terraform.tfvars` → update `enforcement_mode`
2. Run `terraform apply`

## Compliance Mapping

| Policy | Standard | Control |
|--------|----------|---------|
| NSG Required on Subnets | ISO 27001:2022 | A.13.1.3 - Segregation in networks |
| No Public IPs on VMs | ISO 27001:2022 | A.13.1.3 - Segregation in networks |
| Exemption Monitoring | ISO 27001:2022 | A.12.4.1 - Event logging |

## Troubleshooting

### Issue: "Insufficient permissions to create policy"

**Solution**: Ensure you have `Policy Contributor` role:
```bash
az role assignment create \
  --assignee your-email@company.com \
  --role "Policy Contributor" \
  --scope /subscriptions/<subscription-id>
```

### Issue: "Policy not blocking deployments"

**Possible causes**:
1. Enforcement mode is `DoNotEnforce` (audit-only)
2. Policy evaluation delay (wait 15-30 minutes)
3. Resource has an exemption configured

**Solution**:
```bash
# Check enforcement mode
az policy assignment show --name "deny-vm-public-ip" --query enforcementMode

# Check for exemptions
az policy exemption list --query "[?policyAssignmentId contains 'deny-vm-public-ip']"
```

### Issue: "State file locked"

**Solution**:
```bash
# Force unlock (use with caution)
terraform force-unlock <lock-id>
```

### Issue: "Provider authentication error"

**Solution**:
```bash
az login
az account set --subscription "your-subscription-id"
```

### Issue: "Exemption not working"

**Possible causes**:
1. Incorrect resource ID format
2. Exemption not yet applied (wait 5-10 minutes)
3. Exemption expired

**Solution**:
```bash
# Verify resource ID format
az vm show --name vm-name --resource-group rg-name --query id

# Check exemption status
terraform state show azurerm_resource_policy_exemption.vm_public_ip[\"exemption-name\"]

# Verify exemption in Azure
az policy exemption list --query "[?name=='exemption-name']"
```

## Best Practices

1. **Always start in audit mode** (`DoNotEnforce`) for 2-4 weeks
2. **Use remote state** (Azure Storage) for team collaboration
3. **Document exemptions** with clear justification and compensating controls
4. **Limit exemptions** to absolute minimum (target: zero exemptions)
5. **Review quarterly** - are exemptions still needed?
6. **Use Azure Bastion** instead of public IPs for VM access
7. **Run `terraform plan`** before commits to prevent sensitive data leaks
8. **Automate compliance checks** in CI/CD pipelines

## Alternative Architectures

Instead of exemptions, consider:

1. **Azure Bastion**: Secure RDP/SSH access without public IPs
2. **Azure Firewall**: Centralized outbound internet access
3. **NAT Gateway**: Outbound connectivity without VM public IPs
4. **Private Endpoints**: Private access to Azure PaaS services
5. **VPN Gateway**: Site-to-site connectivity
6. **ExpressRoute**: Private dedicated connection to Azure

## Clean Up

Remove all policies and monitoring:

```bash
terraform destroy
```

Verify cleanup:
```bash
az policy assignment list --query "[?contains(name, 'nsg-required') || contains(name, 'deny-vm-public-ip')]"
```

## Additional Resources

- [Azure Policy Documentation](https://docs.microsoft.com/azure/governance/policy/)
- [Azure Bastion Documentation](https://docs.microsoft.com/azure/bastion/)
- [Network Security Best Practices](https://docs.microsoft.com/azure/security/fundamentals/network-best-practices)
- [ISO 27001 Azure Compliance](https://docs.microsoft.com/azure/compliance/offerings/offering-iso-27001)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

## Support

For issues or questions:
1. Check [Troubleshooting](#troubleshooting) section
2. Review Azure Policy compliance reports in Portal
3. Check Terraform state: `terraform state list`
4. Review exemption configurations: `terraform output`

## Version History

- **1.0.0** (2026-01-14): Initial release
  - NSG required on subnets (custom policy)
  - No public IPs on VMs (built-in policy)
  - Exemption framework with expiration monitoring
  - Audit mode support
