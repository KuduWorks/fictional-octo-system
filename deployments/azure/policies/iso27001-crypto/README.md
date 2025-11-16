# ISO 27001 Cryptography Policies

Azure Policy configuration for ISO 27001 Control A.10.1.1 (Cryptographic Controls). Provides visibility into encryption usage while accepting both Customer-Managed Keys (CMK) and Platform-Managed Keys (PMK).

## 🎯 Key Principle

**Both CMK and PMK are compliant.** These policies audit encryption usage without blocking deployments.

## 📊 What's Deployed

### Enforced Policies (Block non-compliant)
- ✅ HTTPS/SSL required (Storage, MySQL, PostgreSQL)
- ✅ TLS 1.2+ required (App Service, Functions)
- ✅ Key Vault protection (soft delete, purge protection)
- ✅ Disk encryption (deny if not using CMK)
- ✅ Cosmos DB encryption (deny if not using CMK)
- ✅ Data Explorer encryption (deny if not using CMK)
- ✅ Service Bus, Event Hub, Container Registry, ML Workspace, AKS encryption (deny if not using CMK)

### Audit Policies (Report only)
- 📊 VM encryption method (audit only)
- 📊 SQL TDE encryption type

**Total: 15+ policies** (most enforced, some audit)

## 🚀 Quick Start

```bash
cd deployments/azure/policies/iso27001-crypto
terraform init
terraform apply
```

**Wait 24 hours** for initial compliance evaluation.

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
| Dev/Test | PMK | Zero overhead, free |
| Production (general) | PMK | Sufficient security |
| Regulated data (HIPAA, PCI-DSS) | CMK | Compliance requirement |
| Need key revocation | CMK | Full control |
| Cost sensitive | PMK | No additional charges |

## 🛠️ Fix Common Issues

### Enable HTTPS on Storage
```bash
az storage account update --name <name> --resource-group <rg> --https-only true
```

### Update App Service TLS
```bash
az webapp config set --name <name> --resource-group <rg> --min-tls-version 1.2
```

### Enable MySQL SSL
```bash
az mysql server update --name <name> --resource-group <rg> --ssl-enforcement Enabled
```

## 📚 Configuration

### Variables (`terraform.tfvars`)
```hcl
enforcement_mode        = "DoNotEnforce"  # Start in audit mode
subscription_id         = null            # Uses current subscription
require_encryption      = true            # Encryption required (CMK or PMK)
audit_encryption_type   = true            # Report on encryption type
```

### Examples

**Storage with PMK (compliant)**
```hcl
resource "azurerm_storage_account" "example" {
  name                     = "mystorageaccount"
  enable_https_traffic_only = true
  # Uses PMK by default - compliant ✅
}
```

**Storage with CMK (also compliant)**
```hcl
resource "azurerm_storage_account" "example" {
  name                     = "mystorageaccount"
  enable_https_traffic_only = true
  
  identity {
    type = "SystemAssigned"
  }
  
  customer_managed_key {
    key_vault_key_id = azurerm_key_vault_key.example.id
  }
  # Also compliant ✅
}
```

## 🎓 Understanding Results

### Compliant ✅
- Resources with HTTPS/SSL enabled
- Resources with TLS 1.2+
- Resources with encryption (CMK **or** PMK) where allowed
- Key Vaults with soft delete and purge protection

### Non-Compliant ❌
- HTTPS/SSL disabled
- TLS version < 1.2
- No encryption (rare - Azure encrypts by default)
- Key Vault without protection
- Storage, SQL, Cosmos DB, Data Explorer, Service Bus, Event Hub, Container Registry, ML Workspace, AKS without CMK (where required)

## 📋 Policy List

| # | Policy | Type | Effect | Accepts CMK | Accepts PMK |
|---|--------|------|--------|-------------|-------------|
| 1 | Storage HTTPS | Built-in | Deny | N/A | N/A |
| 2 | Storage Encryption | Built-in | Deny | ✅ | ✅ |
| 3 | Storage CMK Required | Built-in | Deny | ✅ | ✅ |
| 4 | SQL TDE Enabled | Built-in | Audit | ✅ | ✅ |
| 5 | Key Vault Soft Delete | Built-in | Audit | N/A | N/A |
| 6 | Key Vault Purge Protection | Built-in | Audit | N/A | N/A |
| 7 | Disk Encryption (CMK) | Custom | Deny | ✅ |  |
| 8 | Cosmos DB Encryption (CMK) | Custom | Deny | ✅ |  |
| 9 | MySQL SSL | Custom | Deny | N/A | N/A |
| 10 | PostgreSQL SSL | Custom | Deny | N/A | N/A |
| 11 | App Service TLS 1.2+ | Built-in | Deny | N/A | N/A |
| 12 | Function App TLS 1.2+ | Built-in | Deny | N/A | N/A |
| 13 | Data Explorer Disk Encryption | Custom | Deny | ✅ |  |
| 14 | Data Explorer CMK Required | Custom | Deny | ✅ |  |
| 15 | Service Bus CMK Required | Custom | Deny | ✅ |  |
| 16 | Event Hub CMK Required | Custom | Deny | ✅ |  |
| 17 | Container Registry CMK Required | Custom | Deny | ✅ |  |
| 18 | ML Workspace CMK Required | Custom | Deny | ✅ |  |
| 19 | AKS Encryption at Host | Custom | Deny |  |  |
| 20 | VM Encryption Audit | Custom | AuditIfNotExists |  |  |

## 🔄 Next Steps

1. **Deploy policies** (5 minutes)
2. **Wait for evaluation** (24 hours)
3. **Review compliance** in Azure Portal
4. **Remediate issues** using CLI commands above
5. **Optional:** Switch to enforcement mode

## 📖 Additional Documentation

- [Quick Start Guide](QUICKSTART.md) - 5-minute setup
- [CMK vs PMK Decision Guide](CMK-vs-PMK-DECISION-GUIDE.md) - Detailed comparison
- [Azure Policy Docs](https://docs.microsoft.com/azure/governance/policy/)

## 📝 Support

Questions? Check the compliance dashboard or review policy evaluation logs in Azure Portal.

---

**Deployment:** 5 minutes | **First Report:** 24 hours | **Enforcement:** Audit mode
