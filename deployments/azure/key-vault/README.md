# Azure Key Vault with RBAC

> *"Because storing secrets in environment variables is like hiding your house key under the doormat"* 🔐

Terraform module for deploying Azure Key Vault with **RBAC (Role-Based Access Control)** instead of the legacy access policy model. This provides better security, integration with Privileged Identity Management (PIM), and follows Microsoft's latest best practices.

## 🎯 Overview

This module creates a production-ready Azure Key Vault with:
- **RBAC authorization** (not access policies!)
- Comprehensive security settings (purge protection, soft delete)
- Network isolation options (private endpoints, IP restrictions)
- Integrated monitoring and diagnostics
- Multiple role assignments for different access patterns

## ⚡ Quick Start

```bash
# 1. Copy the example configuration
cp terraform.tfvars.example terraform.tfvars

# 2. Edit your configuration
vim terraform.tfvars

# 3. Deploy
terraform init
terraform plan
terraform apply
```

## 📋 Prerequisites

> *"The stuff you need before you can have nice things"* ☕

- **Azure CLI** installed and authenticated (`az login`)
- **Terraform** >= 1.3.0
- Appropriate Azure permissions:
  - `Owner` or `User Access Administrator` role (for RBAC assignments)
  - `Contributor` role (for resource creation)
- Your **Object ID** (find it with: `az ad signed-in-user show --query id -o tsv`)

## 🏗️ What Gets Created

| Resource | Purpose | Optional |
|----------|---------|----------|
| **Key Vault** | Main vault with RBAC enabled | Required |
| **RBAC Role Assignments** | Access control for users/apps | Required |
| **Log Analytics Workspace** | Centralized logging | Optional |
| **Diagnostic Settings** | Audit and metrics collection | Optional |
| **Private Endpoint** | Private network connectivity | Optional |
| **Resource Group** | Container for resources | Optional |

## 🔑 RBAC Roles Explained

### Built-in Key Vault Roles

| Role | What They Can Do | Who Should Get It |
|------|------------------|-------------------|
| **Key Vault Administrator** | Full control (like Owner) | Platform admins, automation accounts |
| **Key Vault Secrets Officer** | Create, read, update, delete secrets | DevOps engineers, deployment pipelines |
| **Key Vault Secrets User** | Read secrets only | Applications, services |
| **Key Vault Crypto Officer** | Manage keys and crypto operations | Security team |
| **Key Vault Crypto User** | Use keys for encryption/decryption | Applications needing encryption |
| **Key Vault Certificates Officer** | Manage certificates | Certificate admins |
| **Key Vault Certificates User** | Read certificates | Applications using TLS/SSL |
| **Key Vault Reader** | View metadata (not secrets!) | Auditors, monitoring systems |

> 💡 **Pro tip**: Start with least privilege! Most apps only need "Secrets User" or "Crypto User"

### Why RBAC Instead of Access Policies?

> *"Because the old way had more holes than Swiss cheese"* 🧀

**Access Policies (Legacy)** ❌
- Anyone with `Contributor` role can grant themselves access
- No Privileged Identity Management (PIM) support
- Difficult to audit and manage at scale
- Microsoft says: "Don't use this anymore"

**RBAC (Modern)** ✅
- Only `Owner`/`User Access Administrator` can assign roles
- Full PIM support for just-in-time access
- Consistent with other Azure services
- Centralized access management
- Better security posture

## 📖 Usage Examples

### Basic Key Vault with Admin Access

```hcl
key_vault_name      = "kv-myapp-prod"
resource_group_name = "rg-production"
location            = "swedencentral"

# You get admin access automatically
assign_deployer_admin = true

# Basic security (good for dev/test)
purge_protection_enabled   = false
network_acls_default_action = "Allow"
```

### Production Key Vault with Multiple Roles

```hcl
key_vault_name      = "kv-myapp-prod"
resource_group_name = "rg-production"

# Grant admin access to deployment pipeline
assign_deployer_admin = true

# DevOps team gets full secrets management
secrets_officer_principal_ids = [
  "12345678-abcd-1234-abcd-123456789012",  # DevOps SP
]

# Applications get read-only access
secrets_user_principal_ids = [
  "87654321-dcba-4321-dcba-210987654321",  # App Service MI
  "11111111-2222-3333-4444-555555555555",  # Function App MI
]

# Security team manages encryption keys
crypto_officer_principal_ids = [
  "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",  # Security team
]

# Production security settings
purge_protection_enabled      = true
soft_delete_retention_days    = 90
network_acls_default_action   = "Deny"
allowed_ip_addresses          = ["203.0.113.0/24"]

tags = {
  Environment = "production"
  CostCenter  = "engineering"
  Compliance  = "ISO27001"
}
```

### Private Key Vault (No Public Access)

```hcl
key_vault_name      = "kv-private-prod"
resource_group_name = "rg-production"

# Disable public access entirely
public_network_access_enabled = false

# Enable private endpoint
enable_private_endpoint = true
private_endpoint_subnet_id = "/subscriptions/.../subnets/subnet-pe"
private_dns_zone_id = "/subscriptions/.../privateDnsZones/privatelink.vaultcore.azure.net"

# Only Azure services can bypass
network_acls_bypass = "AzureServices"
network_acls_default_action = "Deny"
```

### Key Vault with Monitoring

```hcl
key_vault_name = "kv-monitored-prod"

# Enable comprehensive logging
enable_diagnostics = true
log_retention_days = 30

diagnostic_logs = [
  "AuditEvent",                      # Who accessed what
  "AzurePolicyEvaluationDetails",    # Policy compliance
]

diagnostic_metrics = [
  "AllMetrics",  # Performance and availability
]
```

## 🔐 Security Best Practices

> *"Because hoping nobody finds your secrets is not a security strategy"* 🛡️

### 1. Enable Purge Protection (Production)

```hcl
purge_protection_enabled   = true
soft_delete_retention_days = 90  # Max protection
```

**Why?** Prevents malicious or accidental permanent deletion. Even admins can't bypass this!

### 2. Restrict Network Access

```hcl
network_acls_default_action = "Deny"
allowed_ip_addresses = [
  "203.0.113.0/24",  # Your office
]
```

**Why?** Limits attack surface. If your vault is breached, attackers need your IP too.

### 3. Use Managed Identities

```hcl
# Get app's managed identity object ID
data "azurerm_linux_web_app" "app" {
  name                = "my-app"
  resource_group_name = "rg-apps"
}

# Grant access to the managed identity
secrets_user_principal_ids = [
  data.azurerm_linux_web_app.app.identity[0].principal_id
]
```

**Why?** No credentials to leak! Apps authenticate automatically.

### 4. Use Least Privilege

```hcl
# ❌ DON'T: Give everyone admin
secrets_officer_principal_ids = [everyone]

# ✅ DO: Give minimum needed access
secrets_user_principal_ids = [apps]      # Read only
secrets_officer_principal_ids = [devops] # Full access
```

**Why?** Limits blast radius if an account is compromised.

### 5. Enable Monitoring

```hcl
enable_diagnostics = true
```

**Why?** Know who accessed what and when. Essential for incident response and compliance.

### 6. Use Private Endpoints (Production)

```hcl
enable_private_endpoint       = true
public_network_access_enabled = false
```

**Why?** Keeps traffic on Azure backbone. Internet can't even see your vault exists.

## 🔍 Finding Principal IDs

### For Users

```bash
# Your own user
az ad signed-in-user show --query id -o tsv

# Another user
az ad user show --id user@domain.com --query id -o tsv

# A group
az ad group show --group "DevOps Team" --query id -o tsv
```

### For Service Principals

```bash
# By application name
az ad sp list --display-name "My App" --query "[0].id" -o tsv

# By application ID
az ad sp show --id <app-id> --query id -o tsv
```

### For Managed Identities

```bash
# System-assigned (from the resource)
az webapp identity show \
  --name my-app \
  --resource-group rg-apps \
  --query principalId -o tsv

# User-assigned
az identity show \
  --name my-managed-identity \
  --resource-group rg-identity \
  --query principalId -o tsv
```

## 📊 Post-Deployment

### Verify RBAC Is Enabled

```bash
# Check Key Vault properties
az keyvault show --name kv-myapp-prod --query enableRbacAuthorization

# Should return: true
```

### List Role Assignments

```bash
# See who has what access
az role assignment list \
  --scope /subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.KeyVault/vaults/kv-myapp-prod \
  --output table
```

### Test Access

```bash
# Try to set a secret (requires Secrets Officer or Admin)
az keyvault secret set \
  --vault-name kv-myapp-prod \
  --name test-secret \
  --value "Hello World"

# Try to read a secret (requires Secrets User, Officer, or Admin)
az keyvault secret show \
  --vault-name kv-myapp-prod \
  --name test-secret
```

### Common Issues

#### "Access Denied" After Deployment

**Problem**: RBAC propagation takes 2-5 minutes

**Solution**: Wait a bit, then try again. *(Azure's eventually consistent, not instantly consistent)*

```bash
# Check if your role is assigned
az role assignment list \
  --assignee $(az ad signed-in-user show --query id -o tsv) \
  --scope /subscriptions/.../providers/Microsoft.KeyVault/vaults/kv-myapp-prod
```

#### "Vault Name Already Exists"

**Problem**: Key Vault names are globally unique

**Solution**: Choose a different name. Try adding a region or random suffix.

```hcl
key_vault_name = "kv-myapp-prod-swe-001"  # Add region and number
```

#### "Can't Delete Key Vault"

**Problem**: Purge protection is enabled

**Solution**: This is by design! You must wait 90 days (or your retention period).

```bash
# List soft-deleted vaults
az keyvault list-deleted

# Recover instead of deleting (if you made a mistake)
az keyvault recover --name kv-myapp-prod
```

## 🔄 Migration from Access Policies

> *"Upgrading from the Stone Age to the Cloud Age"* 🦕➡️☁️

If you have an existing Key Vault with access policies:

### 1. Check Current Configuration

```bash
az keyvault show --name your-vault --query enableRbacAuthorization
# Returns: false (using access policies)
```

### 2. Document Existing Access

```bash
# Export access policies before migration
az keyvault show --name your-vault --query properties.accessPolicies > access-policies-backup.json
```

### 3. Enable RBAC (Can't Be Undone!)

```bash
az keyvault update \
  --name your-vault \
  --enable-rbac-authorization true
```

⚠️ **WARNING**: This immediately disables all access policies! Make sure RBAC roles are assigned first.

### 4. Map Access Policies to RBAC Roles

| Old Access Policy | New RBAC Role |
|-------------------|---------------|
| Secrets: Get | Key Vault Secrets User |
| Secrets: Get, List, Set, Delete | Key Vault Secrets Officer |
| Keys: Get, List, Create, Delete, etc. | Key Vault Crypto Officer |
| Keys: Encrypt, Decrypt, Sign, Verify | Key Vault Crypto User |
| Full permissions | Key Vault Administrator |

## 📁 Module Structure

```
key-vault/
├── main.tf                      # Core Key Vault and RBAC resources
├── variables.tf                 # Input variables
├── outputs.tf                   # Output values
├── terraform.tfvars.example     # Example configuration
├── .gitignore                   # Ignore sensitive files
└── README.md                    # This file
```

## 📖 Variables Reference

### Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `key_vault_name` | string | Globally unique vault name (3-24 chars) |
| `resource_group_name` | string | Resource group name |

### Security Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `purge_protection_enabled` | bool | `true` | Prevent permanent deletion |
| `soft_delete_retention_days` | number | `90` | Days to retain deleted items (7-90) |
| `network_acls_default_action` | string | `"Deny"` | Default network access |
| `allowed_ip_addresses` | list(string) | `[]` | Allowed IPs |

### RBAC Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `assign_deployer_admin` | bool | `true` | Give deployer admin access |
| `secrets_officer_principal_ids` | list(string) | `[]` | Full secrets management |
| `secrets_user_principal_ids` | list(string) | `[]` | Read-only secrets |
| `crypto_officer_principal_ids` | list(string) | `[]` | Full key management |
| `crypto_user_principal_ids` | list(string) | `[]` | Crypto operations only |

See `variables.tf` for complete list.

## 📤 Outputs

| Output | Description |
|--------|-------------|
| `key_vault_id` | Full resource ID |
| `key_vault_name` | Vault name |
| `key_vault_uri` | Vault URI (https://...) |
| `rbac_authorization_enabled` | Always `true` |
| `role_assignments_created` | Summary of assigned roles |

## 🤝 Contributing

> *"PRs welcome! Especially if they include security improvements"* 🚀

1. Fork the repository
2. Create a feature branch *(not `fix-stuff`)*
3. Make your changes *(with meaningful commits)*
4. Run `terraform fmt` *(because formatting matters)*
5. Submit a pull request *(bonus points for security enhancements)*

## 📄 License

This module is part of the fictional-octo-system repository and follows the same MIT License.

## 📚 Additional Resources

- [Azure Key Vault Best Practices](https://learn.microsoft.com/en-us/azure/key-vault/general/best-practices)
- [Azure RBAC for Key Vault](https://learn.microsoft.com/en-us/azure/key-vault/general/rbac-guide)
- [Migrate from Access Policies to RBAC](https://learn.microsoft.com/en-us/azure/key-vault/general/rbac-migration)
- [Key Vault Security Features](https://learn.microsoft.com/en-us/azure/key-vault/general/security-features)
- [Managed Identities](https://learn.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/overview)

---

> *"Remember: A secret in Key Vault is worth two in environment variables"* 🎭
