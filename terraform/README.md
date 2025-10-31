# Terraform Infrastructure for Fictional Octo System

> *"Because clicking through the Azure Portal 47 times per deployment is not a sustainable DevOps strategy"* 🐙

This folder contains Terraform code for deploying and managing Azure resources for the Fictional Octo System project.

## Infrastructure Components

- **Storage Account**: Remote state storage with IP-restricted access
- **Virtual Network**: Basic networking setup with customizable address space
- **Monitoring**: Azure Monitor setup with Log Analytics Workspace
- **Security**: Network rules limiting storage account access to specified IPs

## File Structure

- `main.tf` — Core infrastructure and provider configuration
- `variables.tf` — Input variables definition
- `monitoring.tf` — Monitoring and alerting configuration
- `storage_network.tf` — Storage account network security rules
- `backend.tf` — Remote state configuration
- `terraform.tfvars` — Variable values (not in version control)

## Prerequisites

1. **Azure CLI** installed and configured *(and you've successfully run `az login` without crying)*
2. **Terraform** (version >= 1.3.0) installed *(because we like our HCL modern)*
3. Access to Azure subscription with required permissions *(a.k.a. someone actually trusts you with production)* ☕

## Getting Started

### 🚀 Quick Start with Dynamic IP (Recommended)

> *"For those of us who work from coffee shops, home, the office, and that one spot in the park with good WiFi"*

If your IP address changes frequently (thanks, ISP 🙄), use the provided wrapper scripts:

**Bash (Linux/macOS/Git Bash):**
```bash
# Make scripts executable (first time only)
chmod +x update-ip.sh tf.sh

# Use wrapper for all Terraform commands
./tf.sh init
./tf.sh plan
./tf.sh apply
```

**PowerShell (Windows):**
```powershell
# Use wrapper for all Terraform commands
.\tf.ps1 init
.\tf.ps1 plan
.\tf.ps1 apply
```

The wrapper automatically updates your IP in the storage account firewall before running Terraform. *(It's like magic, but with more bash scripts)*

📖 **See [TERRAFORM_STATE_ACCESS.md](./TERRAFORM_STATE_ACCESS.md) for detailed documentation on dynamic IP handling.**

---

### 📋 Standard Setup

1. **Initialize Terraform**
   ```powershell
   terraform init
   ```

2. **Configure Variables**
   Create a `terraform.tfvars` file with your values *(not `terraform.tfvars.definitely-not-secrets`)*:
   ```hcl
   resource_group_name = "rg-monitoring"
   alert_email = "your.email@domain.com"  # The email that will haunt you at 3 AM
   allowed_ip_addresses = ["YOUR.IP.ADDRESS"]  # Not 0.0.0.0/0, we're not animals
   ```

3. **Deploy Infrastructure**
   ```powershell
   terraform plan
   terraform apply
   ```

## Security Features

> *"Because security through obscurity is not a feature, it's a bug"* 🔐

- Storage account access restricted to specified IP addresses *(your future self will thank you)*
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
  *(If I see secrets in your git history, we can't be friends)*

- Use Azure CLI authentication  
  *(Service principals are for automation, not for your Friday afternoon experiments)*

- Keep Terraform provider and Azure RM versions up to date  
  *(Running on version 1.0 from 2017? That's not vintage, that's technical debt)*

- Review and adjust monitoring thresholds as needed  
  *(Alert fatigue is real, don't make every warning a DEFCON 1)*

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