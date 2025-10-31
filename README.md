# Fictional Octo System

> *"Because managing Azure infrastructure should feel less like wrestling an octopus and more like conducting an orchestra"* 🐙🎵

An Azure infrastructure deployment repository for managing cloud infrastructure resources, monitoring, and security configurations.

## Overview

This repository contains Infrastructure as Code (IaC) templates and configurations for deploying and managing Azure resources, with a focus on secure storage, monitoring, and virtual networking components. *(In other words: Everything you need to run Azure like a boss, minus the existential dread of manual deployments)*

## Repository Structure

```
fictional-octo-system/
├── terraform/                    # Core Terraform configurations
│   ├── main.tf                  # Core infrastructure setup
│   ├── variables.tf             # Variable definitions
│   ├── monitoring.tf            # Azure Monitor configuration
│   ├── backend.tf               # State storage configuration
│   ├── tf.sh / tf.ps1           # Dynamic IP wrapper scripts
│   ├── update-ip.sh / update-ip.ps1  # IP management utilities
│   ├── QUICKSTART_DYNAMIC_IP.md # Quick start guide for dynamic IPs
│   ├── TERRAFORM_STATE_ACCESS.md # Comprehensive state access guide
│   └── README.md                # Terraform-specific documentation
├── deployments/azure/
│   ├── app-registration/        # Azure AD app registration automation
│   ├── key-vault/               # Azure Key Vault with RBAC
│   ├── vm-automation/           # Automated VM deployment with Bastion
│   └── policies/                # Azure Policy templates (ISO 27001)
├── .github/                     # GitHub Actions workflows and templates
│   └── workflows/               # CI/CD pipeline definitions
├── LICENSE                      # MIT License
├── SECURITY.md                  # Security policy
└── README.md                   # This file
```

## Features

> *"All the things you wish Azure did automatically, now actually automated"* 🚀

### Infrastructure Management
- **Smart IP Management**: Automatic IP whitelisting for dynamic IPs *(because nobody likes manually updating firewall rules at 9 PM)*
- **Secure VM Deployment**: Private VMs with Azure Bastion access *(no public IPs here, we're not savages)*
- **Automated Scheduling**: VM start/stop automation (7 AM/7 PM Finnish time) *(saving money while you sleep)*
- **Azure AD Integration**: App registration automation with secret rotation *(passwords that change themselves, living the dream)*
- Azure Virtual Network (VNet) deployment with NAT Gateway
- Remote state management in Azure Storage (`tfstate20251013`)
- Infrastructure as Code using Terraform with wrapper scripts

### Security & Identity
> *"Security so good, even your paranoid CISO will approve"* 🔐

- **Key Vault with RBAC**: Secure secrets management using modern role-based access control *(not the legacy access policies with security holes)*
- **App Registration Automation**: Service principals with automated secret rotation *(because manual rotation is how security breaches happen)*
- **Federated Identity**: Passwordless authentication via OIDC (GitHub Actions, Kubernetes) *(passwords are so 2015)*
- **Permission Management**: Graph vs. resource-specific scope guidance *(not just "give it Owner and hope for the best")*
- IP-restricted storage account access *(your state file isn't open to the entire internet)*
- Network security rules *(because defense in depth is not just a buzzword)*
- Azure Monitor integration *(so you know when things go wrong before your manager does)*
- Secure state storage configuration *(your terraform.tfstate is safe and sound)*

### Monitoring
> *"If it's not monitored, it doesn't exist (until it breaks at 3 AM)"* 📊

- Log Analytics Workspace *(all your logs in one place, like a well-organized filing cabinet)*
- Storage metrics collection *(because storage costs can sneak up on you)*
- Availability monitoring *(the early warning system you actually need)*
- Alert configurations *(emails that matter, not spam)*

## Getting Started

### Prerequisites

> *"The bare minimum you need before embarking on this cloud adventure"* 🎒

- Azure CLI installed and configured *(bonus points if `az login` works on the first try)*
- Terraform (version >= 1.3.0) *(keeping it modern, unlike that Jenkins server from 2014)*
- Git for version control *(you are using version control, right? RIGHT?)*
- Appropriate Azure subscription permissions *(a.k.a. someone trusts you with the keys to the kingdom)*

### Quick Start

#### For Infrastructure Deployment (Dynamic IP)

> *"For those of us whose ISP thinks IP addresses are like Pokemon cards - gotta catch 'em all (but never the same one twice)"* 🎲

1. Clone the repository:
```bash
git clone https://github.com/kudu-star/fictional-octo-system.git
cd fictional-octo-system/terraform
```

2. Use dynamic IP wrapper scripts (recommended):
```bash
# Make scripts executable (Linux/macOS/Git Bash)
chmod +x tf.sh update-ip.sh

# Or use PowerShell scripts on Windows
# No setup needed for .ps1 files

# Deploy with automatic IP management
./tf.sh init     # or .\tf.ps1 init
./tf.sh plan     # or .\tf.ps1 plan
./tf.sh apply    # or .\tf.ps1 apply
```

3. Configure your variables in `terraform.tfvars`:
```hcl
resource_group_name = "your-rg-name"
alert_email = "your.email@domain.com"  # Where the 3 AM alerts will arrive
# No need to manually manage allowed_ip_addresses!  # Magic! ✨
```

#### For VM Deployment with Automation

```bash
cd deployments/azure/vm-automation

# Configure your SSH key in terraform.tfvars
vim terraform.tfvars

# Deploy VM with Bastion and automation
./tf.sh init
./tf.sh apply
```

#### For Azure AD App Registration

```bash
cd deployments/azure/app-registration

# Configure app settings in terraform.tfvars
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars

# Deploy app registration with service principal
terraform init
terraform apply
```

#### For Azure Key Vault with RBAC

```bash
cd deployments/azure/key-vault

# Configure Key Vault settings in terraform.tfvars
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars

# Deploy Key Vault with RBAC authorization
terraform init
terraform apply
```

📖 **Detailed guides**: 
- [Dynamic IP Quick Start](terraform/QUICKSTART_DYNAMIC_IP.md)
- [VM Automation Guide](deployments/azure/vm-automation/README.md)
- [Azure AD App Registration](deployments/azure/app-registration/README.md)
- [Azure Key Vault with RBAC](deployments/azure/key-vault/README.md)
- [Terraform State Access](terraform/TERRAFORM_STATE_ACCESS.md)

### Security Features

> *"Layered security: Because one wall is never enough when protecting your Azure kingdom"* 🏰

- **Key Vault with RBAC**: Centralized secrets management with modern RBAC authorization *(not the legacy access policies that let Contributors grant themselves access)*
- **Purge Protection**: Prevent accidental or malicious deletion of secrets *(even admins can't bypass this)*
- **Azure AD App Registration**: Automated service principal creation and management *(no more "I forgot where I put that client secret")*
- **Secret Rotation**: Configurable automatic rotation (90-180 days) *(like changing your passwords, but actually happening)*
- **Passwordless Auth**: OIDC federated credentials for GitHub Actions and Kubernetes *(the future is now, old man)*
- **Dynamic IP Management**: Automatic IP whitelisting for Terraform state access *(works from home, office, or that coffee shop with the good WiFi)*
- **Private VM Deployment**: VMs with no public IPs, secured via Azure Bastion *(because exposing SSH to the internet is a bold strategy)*
- **Automated VM Lifecycle**: Daily start/stop schedules (7 AM/7 PM Finnish time) *(your VMs keep better hours than you do)*
- Azure Monitor integration with comprehensive logging *(Big Brother, but for infrastructure)*
- Encryption at host for ISO 27001 compliance *(checking boxes AND securing data)*
- NAT Gateway for secure outbound connectivity *(VMs can call out, but nobody can call in)*
- 30-day log retention policy *(long enough to debug, cheap enough to afford)*

## Monitoring Capabilities

- Centralized logging with Log Analytics
- Storage metrics collection
- Availability monitoring
- Email alerts for critical events

## Contributing

> *"We accept PRs, bug reports, and well-structured complaints about Azure's pricing model"* 🤝

Contributions are welcome! Please read our [Security Policy](SECURITY.md) before contributing. *(Yes, we actually have one)*

1. Fork the repository *(the GitHub way of saying "take a copy")*
2. Create a feature branch *(not called `fix-stuff` or `test123`, please)*
3. Make your changes *(with commit messages that explain WHY, not just WHAT)*
4. Run `terraform fmt` on any Terraform changes *(because consistent formatting matters)*
5. Submit a pull request *(include memes for faster review)*

## Best Practices

> *"Best practices: Because 'it works on my machine' is not a deployment strategy"* 🌟

- **Use wrapper scripts** (`tf.sh`/`tf.ps1`) instead of direct `terraform` commands  
  *(they're there for a reason, not just decoration)*

- Store sensitive data in `terraform.tfvars` (not in version control)  
  *(if I see secrets in your git history, we're having a conversation)*

- Use Azure CLI authentication with dynamic IP management  
  *(because your IP changes more than your mind)*

- **Clean up old IPs** periodically using `cleanup-old-ips.sh`  
  *(digital hoarding is still hoarding)*

- Keep Terraform provider versions up to date  
  *(version 1.0 from 2017 is not "stable", it's ancient)*

- Review monitoring thresholds and VM schedules regularly  
  *(what made sense in January is chaos by December)*

- Use Azure Bastion for secure VM access (no public IPs)  
  *(exposing port 22 to the internet is how you make friends with hackers)*

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

> *"We're here to help (during business hours, mostly)"* 💬

For questions, issues, or support:
- Create an issue in this repository *(use the template, please)*
- Review our [Security Policy](SECURITY.md) for security-related concerns *(don't put credentials in issue titles, it's happened)*

## Acknowledgments

> *"Standing on the shoulders of giants, with a generous helping of StackOverflow"* 🙏

- Built by KuduWorks team *(with love, coffee, and occasional frustration)*
- Implements Azure and Terraform best practices *(learned the hard way so you don't have to)*
- Part of the organization's cloud infrastructure initiative *(fancy words for "we're taking this cloud thing seriously")*
