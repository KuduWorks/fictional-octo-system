# Network Security Policy - VM NIC NSG Requirement

## Current Policy Configuration

This module enforces NSG requirements at the **VM network interface level** rather than at the subnet level.

### Why VM NIC Level?
- **More flexible**: Not all subnets are used for VMs (storage, databases, etc.)
- **VM-focused**: Protects all VMs regardless of subnet configuration
- **Universal coverage**: Applies to both internet-facing and internal VMs
- **Defense at the right layer**: NSG controls at the VM NIC level where traffic is processed

## Deployed Policies

### 1. VM NIC NSG Requirement (Custom Policy)
**Resource Type:** `Microsoft.Network/networkInterfaces`  
**Effect:** Configurable - `audit` (default) or `deny`  
**Scope:** All VM network interfaces

**Policy Logic:**
```hcl
if = {
  allOf = [
    {
      field  = "type"
      equals = "Microsoft.Network/networkInterfaces"
    },
    {
      anyOf = [
        {
          field  = "Microsoft.Network/networkInterfaces/networkSecurityGroup.id"
          exists = false
        },
        {
          field  = "Microsoft.Network/networkInterfaces/networkSecurityGroup.id"
          equals = ""
        }
      ]
    }
  ]
}
then = {
  effect = var.vm_nic_nsg_effect  # "audit" or "deny"
}
```

### 2. No Public IPs on VMs (Built-in Policy)
**Policy ID:** `83a86a26-fd1f-447c-b59d-e51f44264114`  
**Effect:** Deny  
**Scope:** All virtual machines

## Configuration Options

### terraform.tfvars
```hcl
# Overall policy enforcement mode
enforcement_mode = "DoNotEnforce"  # Start with audit

# VM NIC NSG specific effect
vm_nic_nsg_effect = "audit"  # Start with audit, can switch to "deny"

# Subscription targeting
subscription_id = "your-subscription-id"

# Exemptions for VMs requiring public IPs
exempted_resources = {}

# Monitoring configuration
alert_email = "security@example.com"
monitoring_resource_group_name = "rg-policy-monitoring"
monitoring_location = "swedencentral"
```

## Deployment Steps

### Step 1: Apply Updated Policy
```bash
cd deployments/azure/policies/network-security
terraform plan
terraform apply
```

### Step 2: Wait for Propagation
⚠️ **IMPORTANT:** Wait 20-30 minutes after `terraform apply` before testing
- Azure Policy updates require propagation time
- Immediate testing may show inconsistent results

### Step 3: Run Tests
```bash
pwsh ./test-policies.ps1
```

### Step 4: Verify Enforcement
Try creating a subnet without NSG (should fail):
```bash
az network vnet create \
  --resource-group test-rg \
  --name test-vnet \
  --address-prefix 10.0.0.0/16 \
  --subnet-name test-subnet \
  --subnet-prefix 10.0.1.0/24
```

Expected result:
```
ERROR: Resource 'test-subnet' was disallowed by policy.
Policy: subnet-nsg-required
```

## Technical Details

### Azure Policy Field Reference
The policy uses the field path:
```
Microsoft.Network/virtualNetworks/subnets/networkSecurityGroup.id
```

This references the `networkSecurityGroup` property on subnet resources which contains:
```json
{
  "id": "/subscriptions/.../Microsoft.Network/networkSecurityGroups/my-nsg"
}
```

### Why Both Checks Are Needed
1. **`exists = false`** - Catches subnets created without any NSG reference
2. **`equals = ""`** - Catches subnets where NSG was explicitly set to empty/null

Different deployment methods (ARM, Terraform, CLI) may represent "no NSG" differently.

### Excluded Subnets
The policy automatically excludes Azure-reserved subnets:
- `GatewaySubnet` - VPN/ExpressRoute Gateway
- `AzureFirewallSubnet` - Azure Firewall
- `AzureBastionSubnet` - Azure Bastion

These subnets **cannot** have NSGs attached per Azure requirements.

## Known Issues

### ⚠️ CRITICAL: Portal VM Deployments Bypass Policy
**Issue:** When deploying a VM through Azure Portal, if you create a new VNet/subnet as part of the deployment, the subnet is created **without an NSG** and the policy does **not block** it.

**Root Cause:** The policy targets `Microsoft.Network/virtualNetworks/subnets` resources, but during Portal VM deployments, subnets may be created as nested/child resources within the parent VNet deployment. The policy engine evaluates these differently.

**Impact:** 
- Direct subnet creation via CLI/Portal is blocked ✅
- Subnets in Terraform/ARM templates are blocked ✅  
- Subnets created during Portal VM deployment are **NOT blocked** ❌

**Workaround:**
1. **Pre-create VNets with NSGs** before deploying VMs through Portal
2. **Use policy mode "Indexed"** instead of "All" (may have other side effects)
3. **Create initiative policy** that also targets parent VNet deployments
4. **Deploy VMs via CLI/Terraform** where subnet creation is explicit

**Recommended Fix:**
Update policy to target both standalone subnets AND nested subnet definitions:
```hcl
policy_rule = jsonencode({
  if = {
    anyOf = [
      # Standalone subnet resources
      {
        allOf = [
          {
            field  = "type"
            equals = "Microsoft.Network/virtualNetworks/subnets"
          },
          # ... existing conditions
        ]
      },
      # Nested subnets in VNet deployments
      {
        allOf = [
          {
            field  = "type"
            equals = "Microsoft.Network/virtualNetworks"
          },
          {
            count = {
              field = "Microsoft.Network/virtualNetworks/subnets[*]"
              where = {
                allOf = [
                  {
                    anyOf = [
                      {
                        field  = "Microsoft.Network/virtualNetworks/subnets[*].networkSecurityGroup.id"
                        exists = false
                      },
                      {
                        field  = "Microsoft.Network/virtualNetworks/subnets[*].networkSecurityGroup.id"
                        equals = ""
                      }
                    ]
                  },
                  {
                    field = "Microsoft.Network/virtualNetworks/subnets[*].name"
                    notIn = ["GatewaySubnet", "AzureFirewallSubnet", "AzureBastionSubnet"]
                  }
                ]
              }
            }
            greater = 0
          }
        ]
      }
    ]
  }
  then = {
    effect = "deny"
  }
})
```

## Troubleshooting

### Issue: Policy Still Not Blocking Subnets
**Possible causes:**
1. **Propagation incomplete** - Wait longer (up to 30 minutes)
2. **Enforcement mode** - Verify set to `"Default"` not `"DoNotEnforce"`
3. **Policy assignment scope** - Confirm applied at subscription level
4. **Cached policy state** - Try in different resource group
5. **Portal VM deployment** - See "Known Issues" above for this bypass scenario

**Verification command:**
```bash
az policy assignment show --name "nsg-required-on-subnets" \
  --query "{Name:name, EnforcementMode:enforcementMode, PolicyId:policyDefinitionId}" -o table
```

Expected output:
```
Name                      EnforcementMode    PolicyId
------------------------  -----------------  -----------------------------------------------
nsg-required-on-subnets   Default            /subscriptions/.../policyDefinitions/subnet...
```

### Issue: Policy Blocks Gateway/Bastion Subnets
**Solution:** Check `excluded_subnets` variable includes:
```hcl
excluded_subnets = ["GatewaySubnet", "AzureFirewallSubnet", "AzureBastionSubnet"]
```

### Issue: Test Script Times Out
**Solution:** Increase timeout in test script or reduce wait time if propagation confirmed.

## Validation Checklist

- [ ] `terraform apply` completed successfully
- [ ] Waited 20-30 minutes for propagation
- [ ] Policy assignment shows `EnforcementMode: Default`
- [ ] Test script runs without errors
- [ ] Direct subnet creation without NSG is blocked
- [ ] Subnet creation with NSG succeeds
- [ ] Gateway/Bastion subnets can be created without NSG
- [ ] ⚠️ Portal VM deployment with new VNet/subnet (KNOWN BYPASS - see Known Issues)
- [ ] Pre-created VNet/subnet approach works with Portal VM deployments

## Monitoring Policy Compliance

View compliance status:
```bash
az policy state list \
  --filter "PolicyAssignmentName eq 'nsg-required-on-subnets'" \
  --query "[].{Resource:resourceId, Compliance:complianceState}" -o table
```

Generate compliance report:
```bash
az policy state summarize \
  --policy-assignment-name "nsg-required-on-subnets" \
  --query "policyAssignments[0].results.nonCompliantResources"
```

## References
- [Azure Policy Definition Structure](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure)
- [Azure Policy Effects](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/effects)
- [Network Security Best Practices](https://learn.microsoft.com/en-us/azure/security/fundamentals/network-best-practices)
