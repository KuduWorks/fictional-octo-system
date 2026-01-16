# ISO 27001 Cryptography Policies

Azure Policy configuration for ISO 27001 Control A.10.1.1 (Cryptographic Controls). Enforces encryption-at-host on VMs while accepting both Customer-Managed Keys (CMK) and Platform-Managed Keys (PMK) for most services.

## 🎯 Key Principles

- **VM Encryption**: Encryption-at-Host **required** (deny mode) - accepts both PMK and CMK
- **Disk Encryption**: CMK recommended but PMK accepted (audit mode) - Encryption-at-Host provides encryption without CMK
- **Other Services**: Most policies enforced (deny), some audit only

## ⚠️ Security Notice

**This is a public repository.** The `.gitignore` file protects:
- `terraform.tfvars` - Contains subscription IDs
- `backend.tf` - Contains storage account details
- `*.tfstate` - Contains all resource details

**Never commit these files to version control.**

## 📋 Prerequisites

### 1. Enable Encryption-at-Host Feature

**Required at subscription level before deploying VMs:**

```bash
# Register the feature (takes 15-30 minutes)
az feature register --namespace Microsoft.Compute --name EncryptionAtHost

# Check registration status
az feature show --namespace Microsoft.Compute --name EncryptionAtHost

# Once registered, propagate the change
az provider register --namespace Microsoft.Compute
```

### 2. Azure Permissions

- `Policy Contributor` role at subscription level
- `Resource Policy Contributor` for exemptions

### 3. VM SKU Compatibility

⚠️ **Not all VM sizes support encryption-at-host.** Use **D-series and higher:**

| VM Series | Minimum SKU | Examples |
|-----------|-------------|----------|
| **D-series** | Dv3 | Standard_D2s_v3, Standard_D4s_v3 |
| **D-series** | Dv4 | Standard_D2ds_v4, Standard_D4ds_v4 |
| **E-series** | Ev3 | Standard_E2s_v3, Standard_E4s_v3 |
| **E-series** | Ev4 | Standard_E2ds_v4, Standard_E4ds_v4 |
| **F-series** | Fsv2 | Standard_F2s_v2, Standard_F4s_v2 |
| **M-series** | All | Standard_M8ms, Standard_M16ms |

**Not supported**: A-series, Basic, Burstable (B-series), older generations

## 📊 What's Deployed

### Enforced Policies (Deny - Block Deployment) - 17 Policies
- ✅ **VM Encryption-at-Host required** (VMs)
- ✅ **HTTPS/SSL required** (Storage, MySQL, PostgreSQL, App Services, Application Gateway)
- ✅ **TLS 1.2+ required** (Storage Accounts, App Service, Functions)
- ✅ **TLS 1.3 required** (Application Gateway)
- ✅ **No anonymous blob access** (Storage Accounts)
- ✅ **CMK required** (Cosmos DB, Data Explorer, Service Bus, Event Hub, Container Registry, ML Workspace)
- ✅ **AKS encryption at host** (Kubernetes)

### Audit Policies (Report Only) - 8 Policies
- 📊 **Managed disk CMK usage** (audit only - encryption-at-host provides encryption without CMK)
- 📊 **Storage CMK usage** (audit only)
- 📊 **SQL TDE encryption** (audit only)
- 📊 **Key Vault protection** (soft delete, purge protection)
- 📊 **Cognitive Services CMK** (audit only)

**Total: 25 policies** (17 deny, 8 audit)

## 🚀 Quick Start

```bash
cd deployments/azure/policies/iso27001-crypto

# Copy example config
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your subscription ID
# Set enforcement_mode = "DoNotEnforce" for initial testing

terraform init
terraform apply
```

**Wait 15-30 minutes** for policy propagation, then **24 hours** for initial compliance evaluation.

## 📈 View Compliance

### Azure Portal
**Policy** → **Compliance** → Filter: `ISO 27001 - Cryptography`

### Azure CLI
```bash
# Summary
az policy state summarize

# Details
az policy state list --filter "policyDefinitionName like 'iso27001%'" --output table
```

## 🔐 CMK vs PMK Decision

| Use Case | Recommendation | Why |
|----------|---------------|-----|
| VM Encryption | Encryption-at-Host (PMK or CMK) | Required by policy, both accepted |
| Managed Disks | PMK via Encryption-at-Host | Simpler, no DES needed |
| Dev/Test | PMK | Zero overhead, free |
| Production (general) | PMK | Sufficient security |
| Regulated data (HIPAA, PCI-DSS) | CMK | Compliance requirement |
| Need key revocation | CMK | Full control |
| Cost sensitive | PMK | No additional charges |

## 🛠️ Remediation Guide

### Enable Encryption-at-Host on Existing VMs

⚠️ **REQUIRES DOWNTIME** - VMs must be deallocated (stopped) to enable encryption-at-host.

#### Azure CLI
```bash
# 1. Deallocate the VM (CAUSES DOWNTIME)
az vm deallocate --resource-group <rg-name> --name <vm-name>

# 2. Enable encryption-at-host
az vm update \
  --resource-group <rg-name> \
  --name <vm-name> \
  --set securityProfile.encryptionAtHost=true

# 3. Restart the VM
az vm start --resource-group <rg-name> --name <vm-name>

# 4. Verify encryption is enabled
az vm show --resource-group <rg-name> --name <vm-name> \
  --query "securityProfile.encryptionAtHost"
```

#### PowerShell
```powershell
# 1. Deallocate the VM (CAUSES DOWNTIME)
Stop-AzVM -ResourceGroupName "<rg-name>" -Name "<vm-name>" -Force

# 2. Get VM configuration
$vm = Get-AzVM -ResourceGroupName "<rg-name>" -Name "<vm-name>"

# 3. Enable encryption-at-host
$vm.SecurityProfile = @{
    EncryptionAtHost = $true
}

# 4. Update the VM
Update-AzVM -ResourceGroupName "<rg-name>" -VM $vm

# 5. Restart the VM
Start-AzVM -ResourceGroupName "<rg-name>" -Name "<vm-name>"

# 6. Verify encryption is enabled
(Get-AzVM -ResourceGroupName "<rg-name>" -Name "<vm-name>").SecurityProfile.EncryptionAtHost
```

#### Terraform
```hcl
resource "azurerm_linux_virtual_machine" "example" {
  name                = "example-vm"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_D2s_v3"  # Must support encryption-at-host
  
  # Enable encryption-at-host
  encryption_at_host_enabled = true
  
  # ... rest of VM configuration
}

resource "azurerm_windows_virtual_machine" "example" {
  name                = "example-vm"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_D2s_v3"  # Must support encryption-at-host
  
  # Enable encryption-at-host
  encryption_at_host_enabled = true
  
  # ... rest of VM configuration
}
```

### Fix Other Common Issues

### Enable HTTPS on Storage
```bash
az storage account update --name <name> --resource-group <rg> --https-only true
```

### Update App Service TLS
```bash
az webapp config set --name <name> --resource-group <rg> --min-tls-version 1.2
az webapp update --name <name> --resource-group <rg> --https-only true
```

### Configure Application Gateway TLS 1.3
```bash
az network application-gateway ssl-policy set \
  --gateway-name <name> --resource-group <rg> \
  --policy-type Predefined \
  --policy-name AppGwSslPolicy20220101S
```

### Update Storage Account TLS
```bash
az storage account update --name <name> --resource-group <rg> --min-tls-version TLS1_2
```

## 📚 Configuration

### Variables (`terraform.tfvars`)
```hcl
subscription_id  = "your-subscription-id"      # Required
enforcement_mode = "DoNotEnforce"              # Start in audit mode, change to "Default" for enforcement
location         = "swedencentral"             # Region for policy assignments with identity
```

### Backend Configuration (Optional)
```bash
# Copy backend example
cp backend.tf.example backend.tf

# Edit backend.tf with your storage account details
# NOTE: backend.tf is in .gitignore - do not commit
```

## 🧪 Testing

Run the provided test script to validate policies:

```powershell
pwsh ./test-policies.ps1
```

Tests include:
- Function App HTTPS enforcement
- Storage TLS 1.2+ requirement
- **VM encryption-at-host enforcement (deny mode)**
- Application Gateway HTTPS/TLS requirements
- Policy compliance checks

## 📖 ISO 27001 Mapping

All policies implement **ISO 27001:2013 Control A.10.1.1 - Cryptographic Controls**:

> "A policy on the use of cryptographic controls for protection of information shall be developed and implemented."

## 🤝 Contributing

See [CONTRIBUTING.md](../../../../CONTRIBUTING.md)

## 📜 License

See [LICENSE](../../../../LICENSE)
