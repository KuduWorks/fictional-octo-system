# Network Security Policies - Quick Start

Deploy network security policies requiring NSG on VM network interfaces and denying public IPs on VMs in **5 minutes**.

## Prerequisites

- Azure CLI authenticated: `az login`
- Terraform >= 1.0 installed
- Policy Contributor role at subscription level

## Quick Deploy

### 1. Navigate to directory
```bash
cd deployments/azure/policies/network-security
```

### 2. Copy configuration files
```bash
cp backend.tf.example backend.tf
cp terraform.tfvars.example terraform.tfvars
```

### 3. Edit terraform.tfvars (optional)
```hcl
# Start in audit mode (recommended)
enforcement_mode = "DoNotEnforce"

# VM NIC NSG effect - start with audit
vm_nic_nsg_effect = "audit"

# Add exemptions if needed (see terraform.tfvars.example for format)
```

### 4. Initialize and deploy
```bash
terraform init
terraform plan
terraform apply
```

Type `yes` to confirm.

## What Gets Deployed

✅ **Custom Policy**: NSG required on all VM network interfaces (audit mode by default)  
✅ **Built-in Policy**: Deny public IPs on VMs (enforces Azure Bastion usage)  
✅ **Exemption Framework**: For VMs legitimately requiring public IPs  
✅ **Expiration Monitoring**: Email alerts 60 days before exemptions expire

## Verify Deployment

```bash
# List policy assignments
az policy assignment list \
  --query "[?contains(name, 'vm-nic-nsg') || contains(name, 'public-ip')].{Name:name, DisplayName:displayName, EnforcementMode:enforcementMode}" \
  --output table

# Check compliance status (wait 15-30 minutes after deployment)
az policy state list \
  --filter "PolicyAssignmentName eq 'vm-nic-nsg-required' or PolicyAssignmentName eq 'deny-vm-public-ip'" \
  --query "[].{Resource:resourceId, State:complianceState, Policy:policyDefinitionName}" \
  --output table
```

## Test Policy Enforcement

```bash
# Run the test script
pwsh ./test-policies.ps1

# Or manually test - This should be AUDITED (VM NIC without NSG)
az network nic create \
  --name test-nic \
  --resource-group test-rg \
  --vnet-name test-vnet \
  --subnet default

# This should FAIL - VM with public IP
az vm create \
  --resource-group test-rg \
  --name test-vm \
  --image Ubuntu2204 \
  --public-ip-address test-vm-ip \
  --location swedencentral
```

## Switch to Enforcement Mode

After auditing compliance for 2-4 weeks:

1. Edit `terraform.tfvars`:
   ```hcl
   # Enable enforcement of no-public-IP policy
   enforcement_mode = "Default"
   
   # Optionally switch VM NIC NSG from audit to deny
   vm_nic_nsg_effect = "deny"
   ```

2. Apply changes:
   ```bash
   terraform apply
   ```

## Add Exemptions

Edit `terraform.tfvars` and add to `exempted_resources`:

```hcl
exempted_resources = {
  my-bastion = {
    resource_id           = "/subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.Compute/virtualMachines/<vm-name>"
    justification         = "Bastion host requires public IP"
    expires_on            = "2027-12-31T23:59:00Z"
    compensating_controls = "NSG IP whitelist, MFA, audit logging"
    approved_by           = "security@example.com"
    ticket_number         = "SEC-2026-001"
  }
}
```

Then run `terraform apply`.

## Monitoring

Exemption expiration alerts are automatically configured. Security team will receive email 60 days before exemptions expire.

## Need More Details?

See [README.md](README.md) for comprehensive documentation including:
- Detailed policy descriptions
- Security considerations
- Exemption approval process
- Quarterly review requirements
- Troubleshooting guide
- Compliance mapping

## Cleanup

```bash
terraform destroy
```

## Quick Reference

```bash
# View outputs
terraform output

# List exemptions
terraform state list | grep exemption

# Show specific exemption
terraform state show azurerm_resource_policy_exemption.vm_public_ip[\"bastion-host\"]
```
