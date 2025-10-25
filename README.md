# Fictional Octo System

An Azure infrastructure deployment repository for managing cloud infrastructure resources, monitoring, and security configurations.

## Overview

This repository contains Infrastructure as Code (IaC) templates and configurations for deploying and managing Azure resources, with a focus on secure storage, monitoring, and virtual networking components.

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
│   ├── vm-automation/           # Automated VM deployment with Bastion
│   └── policies/                # Azure Policy templates (ISO 27001)
├── .github/                     # GitHub Actions workflows and templates
│   └── workflows/               # CI/CD pipeline definitions
├── LICENSE                      # MIT License
├── SECURITY.md                  # Security policy
└── README.md                   # This file
```

## Features

### Infrastructure Management
- **Smart IP Management**: Automatic IP whitelisting for dynamic IPs
- **Secure VM Deployment**: Private VMs with Azure Bastion access
- **Automated Scheduling**: VM start/stop automation (7 AM/7 PM Finnish time)
- Azure Virtual Network (VNet) deployment with NAT Gateway
- Remote state management in Azure Storage (`tfstate20251013`)
- Infrastructure as Code using Terraform with wrapper scripts

### Security
- IP-restricted storage account access
- Network security rules
- Azure Monitor integration
- Secure state storage configuration

### Monitoring
- Log Analytics Workspace
- Storage metrics collection
- Availability monitoring
- Alert configurations

## Getting Started

### Prerequisites

- Azure CLI installed and configured
- Terraform (version >= 1.3.0)
- Git for version control
- Appropriate Azure subscription permissions

### Quick Start

#### For Infrastructure Deployment (Dynamic IP)

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
alert_email = "your.email@domain.com"
# No need to manually manage allowed_ip_addresses!
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

📖 **Detailed guides**: 
- [Dynamic IP Quick Start](terraform/QUICKSTART_DYNAMIC_IP.md)
- [VM Automation Guide](deployments/azure/vm-automation/README.md)
- [Terraform State Access](terraform/TERRAFORM_STATE_ACCESS.md)

### Security Features

- **Dynamic IP Management**: Automatic IP whitelisting for Terraform state access
- **Private VM Deployment**: VMs with no public IPs, secured via Azure Bastion
- **Automated VM Lifecycle**: Daily start/stop schedules (7 AM/7 PM Finnish time)
- Azure Monitor integration with comprehensive logging
- Encryption at host for ISO 27001 compliance
- NAT Gateway for secure outbound connectivity
- 30-day log retention policy

## Monitoring Capabilities

- Centralized logging with Log Analytics
- Storage metrics collection
- Availability monitoring
- Email alerts for critical events

## Contributing

Contributions are welcome! Please read our [Security Policy](SECURITY.md) before contributing.

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run `terraform fmt` on any Terraform changes
5. Submit a pull request

## Best Practices

- **Use wrapper scripts** (`tf.sh`/`tf.ps1`) instead of direct `terraform` commands
- Store sensitive data in `terraform.tfvars` (not in version control)
- Use Azure CLI authentication with dynamic IP management
- **Clean up old IPs** periodically using `cleanup-old-ips.sh`
- Keep Terraform provider versions up to date
- Review monitoring thresholds and VM schedules regularly
- Use Azure Bastion for secure VM access (no public IPs)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For questions, issues, or support:
- Create an issue in this repository
- Review our [Security Policy](SECURITY.md) for security-related concerns

## Acknowledgments

- Built by KuduWorks team
- Implements Azure and Terraform best practices
- Part of the organization's cloud infrastructure initiative
