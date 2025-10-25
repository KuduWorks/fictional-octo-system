# Storage Account Access Options - Dynamic IP Problem

## The Problem

Your IP address keeps changing, making IP-based firewall rules impractical. You need secure access to your Azure Storage Account without constantly updating IP whitelist.

## Solution Options

### ⭐ **Option 1: Private Endpoint (Most Secure - Recommended)**

**Best for**: Production environments, changing IPs, maximum security

#### How it works:
- Storage account gets a private IP in your VNet
- No internet exposure - all traffic stays on Azure backbone
- Access from any VNet-connected resource (VM, VPN, ExpressRoute)
- Works from anywhere via VPN or Azure Bastion

#### Setup:

```hcl
# In terraform.tfvars
storage_access_method = "private_endpoint"
```

```bash
terraform apply
```

#### Access from your machine:
You need to be connected to the Azure VNet:

**Option A: Using Azure Bastion + VM**
1. Deploy VM with Bastion (already done in `/deployments/azure/vm-automation`)
2. Connect to VM via Bastion
3. Access storage from VM using Azure CLI or Storage Explorer
4. VM is in same VNet, so it can reach private endpoint

**Option B: Point-to-Site VPN**
1. Set up P2S VPN Gateway in your VNet (~$27/month)
2. Connect to Azure via VPN client
3. Access storage directly from your laptop

**Option C: Azure Cloud Shell**
- Use Azure Cloud Shell (free)
- Automatically connected to Azure network
- Can access storage via az CLI or PowerShell

#### Pros:
- ✅ No IP management needed
- ✅ Works from any connected location
- ✅ Maximum security (no internet exposure)
- ✅ Compliant with enterprise security standards
- ✅ Supports all storage account features

#### Cons:
- ⚠️ Requires VPN or Bastion/VM for access
- ⚠️ More complex setup
- 💰 Additional cost if using VPN Gateway (~$27/month)

#### Cost:
- Private Endpoint: ~$7/month
- Data processing: ~$0.01 per GB
- Optional VPN Gateway: ~$27/month

---

### 🔐 **Option 2: Managed Identity (Best for Azure Resources)**

**Best for**: Access from Azure VMs, App Services, Azure DevOps, GitHub Actions

#### How it works:
- Azure resources get automatic identity
- No credentials to manage
- Resource authenticates using Azure AD
- Firewall allows "Azure Services"

#### Setup:

```hcl
# In terraform.tfvars
storage_access_method = "managed_identity"
```

Your VM already has managed identity enabled. Grant it access:

```bash
# Get VM's managed identity principal ID
VM_IDENTITY=$(az vm show --resource-group rg-vm-automation-dev --name dev-vm-01 --query identity.principalId -o tsv)

# Grant Storage Blob Data Contributor role
az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee $VM_IDENTITY \
  --scope /subscriptions/<subscription-id>/resourceGroups/rg-tfstate/providers/Microsoft.Storage/storageAccounts/tfstate20251013
```

#### Access from VM:

```bash
# Connect via Bastion
az network bastion ssh ...

# Login with managed identity
az login --identity

# Access storage
az storage blob list \
  --account-name tfstate20251013 \
  --container-name tfstate \
  --auth-mode login
```

#### Pros:
- ✅ No credential management
- ✅ Perfect for automation (GitHub Actions, Azure DevOps)
- ✅ Works with Azure services (VMs, App Service, Functions)
- ✅ Free (no additional cost)
- ✅ Automatic credential rotation

#### Cons:
- ⚠️ Doesn't help with access from your local machine
- ⚠️ Requires Azure AD integration
- ⚠️ Need to grant permissions for each resource

---

### 🔓 **Option 3: Shared Access Signature (SAS) Token**

**Best for**: Temporary access, sharing with external users, specific operations

#### How it works:
- Generate time-limited access token
- Token grants specific permissions
- No need to update firewall
- Can be used from anywhere

#### Generate SAS token:

```bash
# Generate SAS token valid for 30 days
az storage account generate-sas \
  --account-name tfstate20251013 \
  --services b \
  --resource-types sco \
  --permissions rwdlac \
  --expiry $(date -u -d "30 days" '+%Y-%m-%dT%H:%MZ') \
  --https-only \
  --output tsv
```

#### Use SAS token:

```bash
# Set SAS token
export AZURE_STORAGE_SAS_TOKEN="your-sas-token-here"

# Access storage
az storage blob list \
  --account-name tfstate20251013 \
  --container-name tfstate \
  --sas-token $AZURE_STORAGE_SAS_TOKEN
```

#### Pros:
- ✅ Works from anywhere (no VPN needed)
- ✅ Time-limited access
- ✅ Granular permissions
- ✅ Easy to revoke (regenerate storage keys)
- ✅ No infrastructure changes

#### Cons:
- ⚠️ Token can be stolen/leaked
- ⚠️ Need to regenerate periodically
- ⚠️ Still requires firewall rule "Allow Azure Services"
- ⚠️ Less secure than Private Endpoint

---

### 🌐 **Option 4: Azure Cloud Shell (Simplest)**

**Best for**: Quick access, administration tasks, no local setup

#### How it works:
- Use browser-based Azure Cloud Shell
- Automatically authenticated
- Can access storage via Azure CLI/PowerShell
- No configuration needed

#### Access:

1. Go to https://shell.azure.com
2. Choose Bash or PowerShell
3. Use Azure CLI:

```bash
# List blobs
az storage blob list \
  --account-name tfstate20251013 \
  --container-name tfstate \
  --auth-mode login

# Download blob
az storage blob download \
  --account-name tfstate20251013 \
  --container-name tfstate \
  --name terraform.tfstate \
  --file ./terraform.tfstate \
  --auth-mode login
```

#### Pros:
- ✅ Zero setup required
- ✅ Always available
- ✅ No IP restrictions
- ✅ Free to use
- ✅ Built-in authentication

#### Cons:
- ⚠️ Browser-based only
- ⚠️ Limited to 5 GB storage
- ⚠️ Session timeout after 20 minutes
- ⚠️ Not suitable for automation

---

## Recommended Solution for Your Scenario

Since your IP keeps changing, I recommend:

### **Hybrid Approach:**

1. **Primary Access: Private Endpoint + Azure Bastion/VM**
   - Use your VM (with Bastion) as jump box
   - VM has private endpoint access
   - Secure, no IP management
   - Already set up!

2. **Quick Access: Azure Cloud Shell**
   - For quick admin tasks
   - No setup needed
   - Access from any browser

3. **Automation: Managed Identity**
   - For CI/CD pipelines
   - GitHub Actions / Azure DevOps
   - No credentials to manage

### **Quick Win Setup:**

```hcl
# 1. Keep current IP whitelist for now
storage_access_method = "ip_whitelist"

# 2. Access via Azure Cloud Shell when IP changes:
# https://shell.azure.com

# 3. Update IP from Cloud Shell:
az storage account network-rule add \
  --account-name tfstate20251013 \
  --resource-group rg-tfstate \
  --ip-address $(curl -s ifconfig.me)

# Remove old IP:
az storage account network-rule remove \
  --account-name tfstate20251013 \
  --resource-group rg-tfstate \
  --ip-address <old-ip>
```

---

## Migration Path

### Phase 1: Keep IP Whitelist (Current)
```hcl
storage_access_method = "ip_whitelist"
```
- Use Azure Cloud Shell when IP changes
- Quick fix, minimal changes

### Phase 2: Add Private Endpoint
```hcl
storage_access_method = "private_endpoint"
```
```bash
terraform apply
```
- Deploy private endpoint
- Access via Bastion/VM
- More secure, no IP management

### Phase 3: Enable Managed Identity
- Grant your VM access to storage
- Use for automation scripts
- Remove IP whitelist completely

---

## Security Comparison

| Method | Security | Convenience | Cost | Best For |
|--------|----------|-------------|------|----------|
| **Private Endpoint** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ~$7/mo | Production |
| **Managed Identity** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Free | Azure resources |
| **SAS Token** | ⭐⭐⭐ | ⭐⭐⭐⭐ | Free | Temporary access |
| **Cloud Shell** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Free | Admin tasks |
| **IP Whitelist** | ⭐⭐ | ⭐⭐ | Free | Static IPs only |

---

## Quick Commands

### Update IP Whitelist (Current Method)
```bash
# From Azure Cloud Shell or current whitelisted IP
az storage account network-rule add \
  --account-name tfstate20251013 \
  --resource-group rg-tfstate \
  --ip-address $(curl -s ifconfig.me)
```

### Deploy Private Endpoint
```bash
cd /c/Repos/fictional-octo-system/terraform
echo 'storage_access_method = "private_endpoint"' >> terraform.tfvars
terraform apply
```

### Access via VM with Managed Identity
```bash
# Connect to VM via Bastion
# Then from VM:
az login --identity
az storage blob list --account-name tfstate20251013 --container-name tfstate --auth-mode login
```

---

## Troubleshooting

### Cannot access storage after deploying private endpoint

1. **Check private endpoint status**:
```bash
az network private-endpoint show \
  --resource-group rg-tfstate \
  --name pe-tfstate20251013 \
  --query "provisioningState"
```

2. **Verify DNS resolution**:
```bash
# From VM or connected device
nslookup tfstate20251013.blob.core.windows.net
# Should return private IP (10.0.x.x)
```

3. **Check you're connected to VNet**:
- Via Bastion/VM
- Via VPN
- Via Cloud Shell

### Access denied even with correct permissions

1. **Check firewall rules**:
```bash
az storage account show \
  --name tfstate20251013 \
  --resource-group rg-tfstate \
  --query "networkRuleSet"
```

2. **Verify managed identity has role**:
```bash
az role assignment list \
  --scope /subscriptions/<sub-id>/resourceGroups/rg-tfstate/providers/Microsoft.Storage/storageAccounts/tfstate20251013 \
  --query "[].{Principal:principalName, Role:roleDefinitionName}"
```

---

## Next Steps

1. **Immediate**: Use Azure Cloud Shell for access when IP changes
2. **Short-term**: Deploy Private Endpoint for secure access
3. **Long-term**: Use Managed Identity for all Azure resource access

Need help deciding? Consider:
- **Budget**: Cloud Shell (free) or Managed Identity (free)
- **Security**: Private Endpoint (most secure)
- **Convenience**: Private Endpoint + Bastion (access from anywhere via VPN)
