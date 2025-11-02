# ISO 27001 Cryptography Compliance Policies

This folder contains Azure Policy definitions and assignments to enforce ISO 27001 A.10.1.1 (Cryptographic Controls) compliance across Azure resources.

## Overview

Comprehensive policy set covering encryption requirements for:

1. ✅ **Storage Accounts** - HTTPS, CMK, disable public access
2. ✅ **SQL Databases** - TDE with customer-managed keys
3. ✅ **Key Vault** - Soft delete, purge protection
4. ✅ **Disk Encryption Sets** - Managed disks with CMK
5. ✅ **Azure Data Explorer (Kusto)** - Cluster encryption with CMK
6. ✅ **Azure Kubernetes Service (AKS)** - Policy addon, host encryption
7. ✅ **Virtual Machines** - EncryptionAtHost or Azure Disk Encryption

## ISO 27001 A.10.1.1 Requirements

**Cryptographic Controls** - Policy on the use of cryptographic controls for protection of information:

- ✅ Encryption at rest for all data
- ✅ Encryption in transit (TLS/HTTPS)
- ✅ Customer-managed keys (CMK) where applicable
- ✅ Key lifecycle management
- ✅ Access controls for cryptographic keys
- ✅ Audit logging for key operations

## Folder Structure

```
iso27001-crypto/
├── main.tf                  # Combined Terraform configuration for all policies
├── terraform.tfvars         # Variable customization
├── README.md               # This file
└── COMPLIANCE.md           # ISO 27001 compliance mapping
```

## Quick Start

### Deploy All Policies

```bash
# Navigate to the folder
cd deployments/azure/policies/iso27001-crypto

# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Deploy all policies
terraform apply
```

### Deploy in Audit Mode (Recommended First)

Edit `terraform.tfvars`:
```hcl
enforcement_mode = "DoNotEnforce"  # Audit only, no blocking
```

Then deploy to assess current compliance before enforcing.

## Policies Included

### 1. Storage Account Policies (3 policies)
- **Secure Transfer Required** - Enforce HTTPS-only access
- **Customer-Managed Keys** - Require CMK encryption
- **Disable Public Blob Access** - Prevent anonymous access

### 2. SQL Database Policies (1 policy)
- **TDE with CMK** - Require customer-managed Transparent Data Encryption

### 3. Database Encryption Policies (4 policies) **NEW**
- **MySQL SSL Enforcement** - Require SSL/TLS for MySQL connections
- **PostgreSQL SSL Enforcement** - Require SSL/TLS for PostgreSQL connections
- **Cosmos DB CMK** - Require customer-managed keys for Cosmos DB
- **Azure Database for MariaDB SSL** - Enforce SSL connections

### 4. Key Vault Policies (2 policies)
- **Soft Delete Enabled** - Protect against accidental deletion
- **Purge Protection** - Prevent permanent key deletion

### 5. Disk Encryption Policies (1 policy)
- **Managed Disks with CMK** - Require disk encryption sets

### 6. Data Explorer (Kusto) Policies (2 policies)
- **Cluster Disk Encryption** - Enable disk encryption on clusters
- **Customer-Managed Keys** - Require CMK for Kusto databases

### 7. AKS Policies (2 policies)
- **Azure Policy Add-on** - Ensure policy enforcement in clusters
- **Host Encryption** - Require encryption at host for node pools

### 8. Virtual Machine Policies (1 policy)
- **VM Encryption Audit** - Require VMs to have either EncryptionAtHost OR Azure Disk Encryption (ADE)

### 9. Networking & Communication Encryption (3 policies) **NEW**
- **API Management TLS 1.2+** - Enforce modern TLS versions for APIM
- **App Service TLS 1.2+** - Require TLS 1.2 or higher for web apps
- **Function App TLS 1.2+** - Require TLS 1.2 or higher for functions

### 10. Messaging Services Encryption (2 policies) **NEW**
- **Service Bus CMK** - Require customer-managed keys for Service Bus
- **Event Hub CMK** - Require customer-managed keys for Event Hub

### 11. Container Services Encryption (1 policy) **NEW**
- **Container Registry CMK** - Require CMK for Azure Container Registry

### 12. AI & Machine Learning Encryption (2 policies) **NEW**
- **ML Workspace CMK** - Require CMK for Machine Learning workspaces
- **Cognitive Services CMK** - Require CMK for Cognitive Services

**Total: 24 policies** (10 built-in, 14 custom)

## Configuration

### Variable Customization

Edit `terraform.tfvars`:

```hcl
# Enforcement mode
enforcement_mode = "Default"      # Enforce policies (deny/audit)
# enforcement_mode = "DoNotEnforce"  # Audit-only mode

# Key Vault for CMK (optional - for reference)
# key_vault_id = "/subscriptions/.../resourceGroups/.../providers/Microsoft.KeyVault/vaults/..."
```

## Compliance Validation

### Check Policy Compliance

```bash
# View all ISO 27001 crypto policy assignments
az policy assignment list \
    --query "[?contains(name, 'iso27001') || contains(displayName, 'ISO 27001')].{Name:name, DisplayName:displayName, EnforcementMode:enforcementMode}" \
    --output table

# Check compliance summary
az policy state summarize \
    --filter "policyDefinitionCategory eq 'ISO 27001 - Cryptography'"

# List non-compliant resources
az policy state list \
    --filter "complianceState eq 'NonCompliant' and policyDefinitionCategory eq 'ISO 27001 - Cryptography'" \
    --query "[].{Resource:resourceId, Policy:policyDefinitionName, Reason:complianceReasonCode}" \
    --output table

# Trigger on-demand compliance scan
az policy state trigger-scan --no-wait
```

### Generate Compliance Report

```bash
# Export compliance data
az policy state list \
    --filter "policyDefinitionCategory eq 'ISO 27001 - Cryptography'" \
    --query "[].{Resource:resourceId, Policy:policyDefinitionName, State:complianceState, Timestamp:timestamp}" \
    --output json > iso27001-compliance-report.json
```

## Phased Rollout Strategy

### Phase 1: Assessment (Week 1)
```bash
# Deploy in audit mode
enforcement_mode = "DoNotEnforce"
terraform apply

# Wait 24-48 hours for compliance evaluation
# Review non-compliant resources
az policy state list --filter "complianceState eq 'NonCompliant'"
```

### Phase 2: Communication (Week 2)
- Share compliance gaps with teams
- Provide remediation guidance
- Set deadlines for compliance

### Phase 3: Enforcement (Week 3-4)
```bash
# Enable enforcement
enforcement_mode = "Default"
terraform apply

# Monitor for deployment failures
# Provide support for blocked deployments
```

## Remediation Guidance

### Storage Accounts

**Issue**: Storage account without HTTPS enforcement
```bash
# Enable secure transfer
az storage account update \
    --name mystorageaccount \
    --resource-group myResourceGroup \
    --https-only true
```

**Issue**: Storage account without CMK
```bash
# Configure customer-managed key
az storage account update \
    --name mystorageaccount \
    --resource-group myResourceGroup \
    --encryption-key-source Microsoft.Keyvault \
    --encryption-key-vault <key-vault-uri> \
    --encryption-key-name <key-name>
```

### SQL Databases

**Issue**: SQL Database without TDE CMK
```bash
# Enable TDE with customer-managed key
az sql server tde-key set \
    --resource-group myResourceGroup \
    --server myServer \
    --kid <key-identifier>
```

### Key Vault

**Issue**: Key Vault without soft delete
```bash
# Enable soft delete and purge protection
az keyvault update \
    --name myKeyVault \
    --resource-group myResourceGroup \
    --enable-soft-delete true \
    --enable-purge-protection true
```

### Managed Disks

**Issue**: Managed disk without encryption set
```bash
# Create disk encryption set
az disk-encryption-set create \
    --name myDiskEncryptionSet \
    --resource-group myResourceGroup \
    --key-url <key-vault-key-url>

# Update disk to use encryption set
az disk update \
    --name myDisk \
    --resource-group myResourceGroup \
    --encryption-type EncryptionAtRestWithCustomerKey \
    --disk-encryption-set myDiskEncryptionSet
```

### AKS

**Issue**: AKS cluster without encryption at host
```bash
# Enable encryption at host for node pool
az aks nodepool update \
    --cluster-name myAKSCluster \
    --resource-group myResourceGroup \
    --name mynodepool \
    --enable-encryption-at-host
```

## Testing

### Test Storage Account Policy

```bash
# This should FAIL/AUDIT - storage without HTTPS
az storage account create \
    --name testnostoragehttp \
    --resource-group test-rg \
    --location swedencentral \
    --https-only false

# This should SUCCEED - storage with HTTPS
az storage account create \
    --name teststoragehttps \
    --resource-group test-rg \
    --location swedencentral \
    --https-only true
```

### Test SQL Database Policy

```bash
# Check TDE status
az sql db tde show \
    --resource-group myResourceGroup \
    --server myServer \
    --database myDatabase
```

## Monitoring & Alerts

### Set Up Compliance Alerts

```bash
# Create action group for alerts
az monitor action-group create \
    --name "iso27001-compliance-alerts" \
    --resource-group "monitoring-rg" \
    --short-name "iso27001" \
    --email-receiver name="SecurityTeam" email="security@company.com"

# Create alert for non-compliance
# (Use Azure Portal or ARM template for policy compliance alerts)
```

### Regular Compliance Reviews

**Weekly**:
- Review new non-compliant resources
- Track remediation progress

**Monthly**:
- Generate compliance reports
- Review policy effectiveness
- Update policies as needed

**Quarterly**:
- ISO 27001 audit preparation
- Policy coverage assessment
- Emerging threat review

## Cleanup

### Remove All Policies

```bash
# Destroy all ISO 27001 crypto policies
terraform destroy
```

### Remove Specific Policy

```bash
# Target specific policy assignment
terraform destroy -target=azurerm_subscription_policy_assignment.storage_https_required
```

## Troubleshooting

### Policy Not Taking Effect

```bash
# Wait time: Policies take 15-30 minutes to propagate
# Trigger manual scan
az policy state trigger-scan --no-wait

# Check assignment status
az policy assignment show --name <policy-name>
```

### False Positives

Some resources may show as non-compliant incorrectly:
- Wait for policy evaluation cycle (every 24 hours)
- Trigger manual compliance scan
- Check resource tags for exemptions

### Exemptions

Create policy exemptions for specific resources:
```bash
az policy exemption create \
    --name "dev-environment-exemption" \
    --policy-assignment <assignment-id> \
    --resource-group "dev-rg" \
    --exemption-category "Waiver" \
    --expires-on "2025-12-31"
```

## Best Practices

1. ✅ **Start with audit mode** - Assess impact before enforcement
2. ✅ **Communicate early** - Give teams time to prepare
3. ✅ **Provide remediation scripts** - Make compliance easy
4. ✅ **Monitor compliance trends** - Track improvement over time
5. ✅ **Review policies regularly** - Keep up with Azure changes
6. ✅ **Document exemptions** - Maintain audit trail
7. ✅ **Automate remediation** - Use Azure Policy remediation tasks

## Additional Resources

- [ISO 27001:2022 Standard](https://www.iso.org/standard/27001)
- [Azure Policy Documentation](https://learn.microsoft.com/azure/governance/policy/)
- [Azure Encryption Overview](https://learn.microsoft.com/azure/security/fundamentals/encryption-overview)
- [Customer-Managed Keys](https://learn.microsoft.com/azure/security/fundamentals/encryption-models#customer-managed-keys)
- [Azure Key Vault Best Practices](https://learn.microsoft.com/azure/key-vault/general/best-practices)

## Support

For questions or issues:
- Review policy definitions in `main.tf`
- Check compliance with `az policy state list`
- See `COMPLIANCE.md` for ISO 27001 mapping
- Contact security team for exemptions

---

**Compliance Note**: These policies help achieve ISO 27001 compliance but should be part of a broader information security management system (ISMS).
