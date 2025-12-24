# Terraform Infrastructure for Fictional Octo System.

> *"Because clicking through the Azure Portal 47 times per deployment is not a sustainable DevOps strategy"* 🐙

This folder contains Terraform code for deploying and managing Azure resources for the Fictional Octo System project.

## Infrastructure Components

- **Storage Account**: Remote state in `tfstateprod20251215` / `tfstate-prod` via Azure AD/OIDC (UAMI)
- **Virtual Network**: Basic networking setup with customizable address space
- **Monitoring**: Azure Monitor setup with Log Analytics Workspace
- **Security**: Network rules default deny; private endpoints optional

## File Structure

- `main.tf` — Core infrastructure and provider configuration
- `variables.tf` — Input variables definition
- `monitoring.tf` — Monitoring and alerting configuration
- `storage.tf` — Storage account network security rules
- `backend.tf` — Remote state configuration
- `terraform.tfvars` — Variable values (not in version control)

## Prerequisites

1. **Azure CLI** installed and configured *(and you've successfully run `az login` without crying)*
2. **Terraform** (version >= 1.3.0) installed *(because we like our HCL modern)*
3. Access to Azure subscription with required permissions *(a.k.a. someone actually trusts you with production)* ☕

## Getting Started

### 🚀 Quick Start with OIDC + UAMI (Production)

1) **Authenticate (local):**
```bash
az login
```

2) **Authenticate (GitHub Actions):** configure federated credential for subject `repo:KuduWorks/fictional-octo-system:ref:refs/heads/main` on a user-assigned managed identity with roles:
- `Contributor` on the subscription
- `Storage Blob Data Contributor` on the state storage account

3) **Initialize backend with Azure AD auth:**
```bash
terraform init \
  -backend-config="use_azuread_auth=true"
```

4) **Plan/Apply (main only):**
```bash
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

5) **Approvals:** protect the `main` branch (required review + status checks) and require manual approval via the `production` GitHub environment before deploy.

📖 **See [TERRAFORM_STATE_ACCESS.md](./TERRAFORM_STATE_ACCESS.md) for backend auth, rollback with shared keys, and OIDC notes.**

---

### 📋 Standard Setup (variables)

Create a `terraform.tfvars` file with your values:
```hcl
state_resource_group_name  = "rg-tfstate"
state_storage_account_name = "tfstateprod20251215"
resource_group_name        = "rg-monitoring"
storage_access_method      = "managed_identity" # or "ip_whitelist" while waiting for UAMI
allowed_ip_addresses       = ["203.0.113.10"]   # only if using ip_whitelist
alert_email                = "your.email@domain.com"
```

## Security Features

> *"Because security through obscurity is not a feature, it's a bug"* 🔐

- Storage state access via Azure AD/OIDC (no shared keys; legacy IP scripts archived/disabled under `archive/dynamic-ip-legacy/`)
- Azure services bypass enabled for monitoring *(so Azure can talk to itself without getting lonely)*
- Diagnostic settings configured for auditing *(for when the auditors come knocking)*
- 30-day retention policy for logs and metrics *(long enough to debug, short enough to not bankrupt you)*

## Monitoring Setup

> *"If a service goes down in the cloud and nobody gets an alert, did it really fail?"* 📊

- Log Analytics Workspace for centralized logging *(all your logs in one place, like a digital filing cabinet)*
- Storage account metrics collection *(so you know when things are about to explode)*
- Availability monitoring and alerting *(the early warning system for your infrastructure)*
- Email notifications for critical events *(prepare your inbox... and your on-call rotation)*

## Best Practices

> *"Best practices are called 'best' for a reason, not 'good enough' practices"* 🌟

- Store sensitive data in `terraform.tfvars` (not in version control)
- Use Azure AD/OIDC auth with UAMI; avoid storage keys except for emergency rollback
- Keep Terraform provider and Azure RM versions up to date
- Protect `main` with required reviews + checks; gate deploys via `production` environment approvals
- Review and adjust monitoring thresholds as needed

## Resource Dependencies

```
Storage Account
    └── Network Rules
    └── Diagnostic Settings
    └── Management Policy
Virtual Network
    └── Subnets
Log Analytics
    └── Metrics Collection
    └── Alert Rules
```

## Variables

| Name | Description | Default |
|------|-------------|---------|
| `resource_group_name` | Name of the resource group | `"rg-monitoring"` |
| `location` | Azure region for deployment | `"swedencentral"` |
| `allowed_ip_addresses` | List of IPs allowed to access storage | `[]` |
| `alert_email` | Email for monitoring alerts | - |

## Contributing

> *"Code reviews are like opinions: everyone has one, and yours is probably wrong"* 😄

1. Create a feature branch *(not called `fix-stuff` or `asdfasdf`)*
2. Make your changes *(with actual commit messages, not "updated thing")*
3. Run `terraform fmt` before committing *(because tabs vs spaces is so last decade)*
4. Submit a pull request *(bonus points if you include why, not just what)*

**Pro tip**: PRs with emoji in the description get reviewed 37% faster* 🚀

<sub>*Not scientifically proven, but feels true</sub>

## Maintenance

> *"Technical debt is like regular debt, but with more YAML and fewer collection agencies"* 🔧

- Regularly update provider versions *(before they become "legacy" versions)*
- Review and adjust IP allowlists as needed *(especially after Bob left and took his home IP with him)*
- Monitor storage metrics and adjust thresholds *(because what was normal in January is chaos by December)*
- Update email recipients for alerts as team changes *(RIP that distribution list from 2019)*