# VM Encryption Policies

This folder contains an Azure Policy that **audits** virtual machines to ensure they have **either EncryptionAtHost OR Azure Disk Encryption** enabled.

## Overview

This deployment creates **1 audit policy** that checks for encryption compliance:

**VM Encryption Audit Policy** - Audits VMs to ensure they have at least one encryption method

## ✅ What This Policy Does

The policy uses **AuditIfNotExists** effect to check VMs for encryption compliance:

1. **If a VM has EncryptionAtHost enabled** → ✅ **Compliant** (no further checks needed)
2. **If a VM does NOT have EncryptionAtHost** → Checks for Azure Disk Encryption extension
   - **If ADE extension is present and successful** → ✅ **Compliant**
   - **If no ADE extension found** → ❌ **Non-Compliant** (flagged for audit)

## 🎯 Policy Behavior

| Scenario | EncryptionAtHost | Azure Disk Encryption | Result |
|----------|------------------|----------------------|---------|
| VM deployed with encryption at host | ✅ Enabled | N/A | ✅ **Compliant** |
| VM deployed without encryption at host, ADE applied later | ❌ Not enabled | ✅ Extension present | ✅ **Compliant** |
| VM deployed without any encryption | ❌ Not enabled | ❌ No extension | ❌ **Non-Compliant** |
| VM with both encryption methods | ✅ Enabled | ✅ Extension present | ✅ **Compliant** |

## 🚀 Key Features

✅ **Does NOT block VM deployment** - VMs can be created without EncryptionAtHost  
✅ **Allows Azure Disk Encryption** - Checks for ADE extension as alternative  
✅ **Supports both Windows and Linux** - Single policy covers both OS types  
✅ **Audit-only enforcement** - Flags non-compliant VMs but doesn't prevent creation  
✅ **Flexible workflow** - Teams can choose their preferred encryption method

## Files

```
vm-encryption/
├── main.tf                  # Terraform configuration
├── terraform.tfvars         # Variable customization
└── README.md               # This file
```

## Deployment

### Quick Start with Terraform

```bash
# Navigate to the vm-encryption folder
cd deployments/azure/policies/vm-encryption

# Initialize Terraform
terraform init

# Preview the changes
terraform plan

# Deploy the policies
terraform apply
```

Type `yes` when prompted to confirm.

## Configuration

Edit `terraform.tfvars` to customize:

```hcl
# Enforcement mode
enforcement_mode = "Default"      # Denies non-compliant VMs
# enforcement_mode = "DoNotEnforce"  # Audit mode only (for testing)
```

### Enforcement Modes

| Mode | Behavior | Use Case |
|------|----------|----------|
| **Default** | Blocks VM deployment without encryption | Production enforcement |
| **DoNotEnforce** | Logs non-compliance but allows deployment | Testing before enforcement |

## Testing

After deployment, **wait 15-30 minutes** for policies to take effect and run compliance scan.

### Test 1: Deploy VM WITH EncryptionAtHost (Compliant)

```bash
# Create resource group
az group create --name "rg-vm-encryption-test" --location "swedencentral"

# Deploy VM with EncryptionAtHost - COMPLIANT
az vm create \
    --resource-group "rg-vm-encryption-test" \
    --name "vm-with-enchost" \
    --image "Ubuntu2204" \
    --admin-username "azureuser" \
    --generate-ssh-keys \
    --size "Standard_D2s_v3" \
    --encryption-at-host true
```

**Expected Result:** ✅ VM deploys successfully and shows as **Compliant**

### Test 2: Deploy VM WITHOUT Encryption (Non-Compliant, but allowed)

```bash
# Deploy VM without any encryption - ALLOWED but flagged as non-compliant
az vm create \
    --resource-group "rg-vm-encryption-test" \
    --name "vm-no-encryption" \
    --image "Ubuntu2204" \
    --admin-username "azureuser" \
    --generate-ssh-keys \
    --size "Standard_D2s_v3"
```

**Expected Result:** ✅ VM deploys successfully but shows as **Non-Compliant** in policy compliance

### Test 3: Apply Azure Disk Encryption to Non-Compliant VM

```bash
# This would require Key Vault setup - see Azure Disk Encryption documentation
# After applying ADE, the VM will become compliant
```

**Expected Result:** ✅ After ADE is applied, VM becomes **Compliant**

### Check Compliance Status

```bash
# Wait a few minutes after deployment, then check compliance
az policy state list \
    --filter "policyDefinitionName eq 'custom-vm-encryption-audit'" \
    --query "[].{Resource:resourceId, ComplianceState:complianceState, Timestamp:timestamp}" \
    --output table
```

### Cleanup

```bash
# Remove test resources
az group delete --name "rg-vm-encryption-test" --yes --no-wait
```

## Verification

Check policy compliance:

```bash
# List all policy assignments
az policy assignment list \
    --query "[?contains(name, 'vm-encryption')].{Name:name, DisplayName:displayName}" \
    --output table

# Check compliance state for VMs
az policy state list \
    --resource-type "Microsoft.Compute/virtualMachines" \
    --filter "policyDefinitionName eq 'custom-vm-encryption-audit'" \
    --query "[].{ResourceName:resourceId, ComplianceState:complianceState, Reason:policyDefinitionAction}" \
    --output table

# Trigger on-demand compliance scan
az policy state trigger-scan --no-wait

# Get compliance summary
az policy state summarize \
    --filter "policyDefinitionName eq 'custom-vm-encryption-audit'"
```

## Policy Details

### VM Encryption Audit Policy
- **Policy Name**: `custom-vm-encryption-audit`
- **Display Name**: "Audit VMs without EncryptionAtHost or Azure Disk Encryption"
- **Effect**: AuditIfNotExists
- **Scope**: All VMs (Windows and Linux) in the subscription

### How It Works

The policy evaluates VMs in this order:

1. **Check EncryptionAtHost property**
   - If `securityProfile.encryptionAtHost = true` → **Compliant** ✅
   - If not enabled or doesn't exist → Continue to step 2

2. **Check for Azure Disk Encryption Extension**
   - Looks for extension publisher: `Microsoft.Azure.Security`
   - Looks for extension types: `AzureDiskEncryption` (Windows) or `AzureDiskEncryptionForLinux` (Linux)
   - Checks extension status is `Succeeded`
   - If found → **Compliant** ✅
   - If not found → **Non-Compliant** ❌

## Exclusions

No automatic exclusions - all VMs are evaluated.

## Compliance vs. Enforcement

This policy uses **Audit** mode, not **Deny** mode:

| Mode | Effect | Use Case |
|------|--------|----------|
| **Audit** (Current) | Flags non-compliant resources | Visibility & gradual adoption |
| **Deny** (Alternative) | Blocks resource creation | Strict enforcement |

**Why Audit?**
- ✅ Allows teams to deploy VMs with either encryption method
- ✅ Azure Disk Encryption can be applied post-deployment
- ✅ Provides visibility without blocking workflows
- ✅ Teams can remediate at their own pace

**When to use Deny?**
- Only if you want to force EncryptionAtHost at deployment (cannot check ADE at deployment time)

## How to Enable Encryption on VMs

### Option 1: EncryptionAtHost (Recommended - Simpler)

**During VM Creation:**
```bash
az vm create \
    --encryption-at-host true \
    [other parameters...]
```

**For Existing VM:**
```bash
# Stop the VM
az vm deallocate --resource-group "myRG" --name "myVM"

# Enable encryption at host
az vm update \
    --resource-group "myRG" \
    --name "myVM" \
    --set securityProfile.encryptionAtHost=true

# Start the VM
az vm start --resource-group "myRG" --name "myVM"
```

**In Terraform:**
```hcl
resource "azurerm_linux_virtual_machine" "example" {
  # ... other configuration ...
  
  encryption_at_host_enabled = true
}
```

### Option 2: Azure Disk Encryption (More Complex)

Requires Azure Key Vault setup. See: https://learn.microsoft.com/azure/virtual-machines/disk-encryption-overview

## Cleanup

### Terraform Cleanup

```bash
# Remove all policies
terraform destroy
```

### Manual Cleanup

```bash
# Delete policy assignments
az policy assignment delete --name "windows-vm-encryption-required"
az policy assignment delete --name "linux-vm-encryption-required"
```

## Troubleshooting

### Common Issues

**Issue: Policy not blocking unencrypted VMs**
- **Wait time**: Policies take 15-30 minutes to take effect after deployment
- **Check enforcement mode**: Must be "Default" not "DoNotEnforce"
- **Verify assignment**: Run `az policy assignment show --name "windows-vm-encryption-required"`

**Issue: Cannot deploy any VMs**
- **Check encryption flag**: Ensure `--encryption-at-host true` is set
- **VM size compatibility**: Some older VM sizes don't support encryption at host
- **Subscription feature**: EncryptionAtHost feature must be registered

**Issue: EncryptionAtHost not available**
```bash
# Register the feature (one-time per subscription)
az feature register --namespace Microsoft.Compute --name EncryptionAtHost

# Wait for registration (check status)
az feature show --namespace Microsoft.Compute --name EncryptionAtHost

# Re-register the provider
az provider register --namespace Microsoft.Compute
```

### Debug Commands

```bash
# Check policy assignment details
az policy assignment show --name "windows-vm-encryption-required" -o json

# List all VM-related policy states
az policy state list --resource-type "Microsoft.Compute/virtualMachines"

# Check if EncryptionAtHost feature is enabled
az feature show --namespace Microsoft.Compute --name EncryptionAtHost
```

## Integration with Other Policies

This encryption policy complements:
- **Region Control Policies** - Ensures VMs are in approved regions AND encrypted
- **Security Baseline Policies** - Part of comprehensive security posture
- **Compliance Frameworks** - Supports HIPAA, PCI-DSS, and other compliance requirements

## Best Practices

1. ✅ **Test in audit mode first** - Use `enforcement_mode = "DoNotEnforce"` initially
2. ✅ **Enable EncryptionAtHost feature** - Register it before enforcing policy
3. ✅ **Communicate with teams** - Ensure developers know about encryption requirement
4. ✅ **Update VM templates** - Add encryption flags to ARM/Terraform templates
5. ✅ **Monitor compliance** - Regularly check policy compliance dashboard

## Additional Resources

- [Azure Disk Encryption Overview](https://learn.microsoft.com/azure/virtual-machines/disk-encryption-overview)
- [Encryption at Host](https://learn.microsoft.com/azure/virtual-machines/disk-encryption#encryption-at-host---end-to-end-encryption-for-your-vm-data)
- [Azure Policy for VMs](https://learn.microsoft.com/azure/virtual-machines/security-policy)
- [Encryption Comparison](https://aka.ms/diskencryptioncomparison)

## Quick Reference

```bash
# Deploy policies
terraform init && terraform apply

# Test VM with encryption
az vm create --encryption-at-host true [...]

# Check policy compliance
az policy state list --filter "complianceState eq 'NonCompliant'"

# Remove policies
terraform destroy
```
