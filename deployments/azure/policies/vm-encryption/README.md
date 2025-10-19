# VM Encryption Policies

This folder contains Azure Policy assignments to enforce encryption on all virtual machines. These policies ensure that every VM deployed must have **either Azure Disk Encryption or EncryptionAtHost enabled**.

## Overview

This deployment creates **2 built-in policy assignments**:

1. **Windows VM Encryption Policy** - Enforces encryption on Windows VMs
2. **Linux VM Encryption Policy** - Enforces encryption on Linux VMs

Both policies use Azure's built-in policy definitions with the **Deny** effect, meaning any VM deployment without proper encryption will be blocked.

## What Gets Enforced

### Encryption Requirements
Virtual machines must have **at least ONE** of the following:

1. ✅ **Azure Disk Encryption (ADE)**
   - Full disk encryption using BitLocker (Windows) or dm-crypt (Linux)
   - Encryption keys managed in Azure Key Vault
   
2. ✅ **EncryptionAtHost**
   - Encryption at the host level
   - Encrypts temp disks and OS/data disk caches
   - Simpler to implement than ADE

### What Gets Blocked

❌ VMs without any encryption enabled  
❌ VMs with only platform-managed encryption (default storage encryption)  
✅ VMs with Azure Disk Encryption  
✅ VMs with EncryptionAtHost enabled  
✅ VMs with both ADE and EncryptionAtHost

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

After deployment, **wait 15-30 minutes** for policies to take effect.

### Test 1: Deploy VM WITHOUT Encryption (Should FAIL)

```bash
# Create resource group
az group create --name "rg-vm-encryption-test" --location "swedencentral"

# Try to deploy VM without encryption - THIS SHOULD FAIL
az vm create \
    --resource-group "rg-vm-encryption-test" \
    --name "vm-no-encryption" \
    --image "Ubuntu2204" \
    --admin-username "azureuser" \
    --generate-ssh-keys \
    --size "Standard_D2s_v3"
```

**Expected Result:** ❌ Deployment blocked with policy violation error

### Test 2: Deploy VM WITH EncryptionAtHost (Should SUCCEED)

```bash
# Deploy VM with EncryptionAtHost enabled - THIS SHOULD SUCCEED
az vm create \
    --resource-group "rg-vm-encryption-test" \
    --name "vm-with-encryption" \
    --image "Ubuntu2204" \
    --admin-username "azureuser" \
    --generate-ssh-keys \
    --size "Standard_D2s_v3" \
    --encryption-at-host true
```

**Expected Result:** ✅ VM deployed successfully

### Test 3: Deploy Windows VM WITHOUT Encryption (Should FAIL)

```bash
# Try to deploy Windows VM without encryption - THIS SHOULD FAIL
az vm create \
    --resource-group "rg-vm-encryption-test" \
    --name "vm-windows-no-enc" \
    --image "Win2022Datacenter" \
    --admin-username "azureuser" \
    --admin-password "YourPassword123!" \
    --size "Standard_D2s_v3"
```

**Expected Result:** ❌ Deployment blocked with policy violation error

### Cleanup

```bash
# Remove test resources
az group delete --name "rg-vm-encryption-test" --yes --no-wait
```

## Verification

Check deployed policies:

```bash
# List encryption policy assignments
az policy assignment list \
    --query "[?contains(name, 'vm-encryption')].{Name:name, DisplayName:displayName, EnforcementMode:enforcementMode}" \
    --output table

# Check compliance state
az policy state list \
    --filter "policyDefinitionId eq '/providers/Microsoft.Authorization/policyDefinitions/3dc5edcd-002d-444c-b216-e123bbfa37c0' or policyDefinitionId eq '/providers/Microsoft.Authorization/policyDefinitions/ca88aadc-6e2b-416c-9de2-5a0f01d1693f'" \
    --query "[].{ResourceId:resourceId, ComplianceState:complianceState}" \
    --output table
```

## Policy Details

### Windows VM Encryption Policy
- **Policy ID**: `3dc5edcd-002d-444c-b216-e123bbfa37c0`
- **Display Name**: "Windows virtual machines should enable Azure Disk Encryption or EncryptionAtHost"
- **Effect**: Deny
- **Scope**: All Windows VMs in the subscription

### Linux VM Encryption Policy
- **Policy ID**: `ca88aadc-6e2b-416c-9de2-5a0f01d1693f`
- **Display Name**: "Linux virtual machines should enable Azure Disk Encryption or EncryptionAtHost"
- **Effect**: Deny
- **Scope**: All Linux VMs in the subscription

## Exclusions

The policies automatically exclude:
- ❌ Basic/A0/A1 VM sizes (not supported)
- ❌ VMs with Ultra SSD enabled (not compatible)
- ❌ Confidential VMs (already encrypted)
- ❌ AKS node VMs (managed by AKS)
- ❌ Azure Databricks VMs (managed service)

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
