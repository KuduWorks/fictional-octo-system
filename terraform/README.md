# Terraform Infrastructure for Fictional Octo System

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

1. **Azure CLI** installed and configured
2. **Terraform** (version >= 1.3.0) installed
3. Access to Azure subscription with required permissions

## Getting Started

1. **Initialize Terraform**
   ```powershell
   terraform init
   ```

2. **Configure Variables**
   Create a `terraform.tfvars` file with your values:
   ```hcl
   resource_group_name = "rg-monitoring"
   alert_email = "your.email@domain.com"
   allowed_ip_addresses = ["YOUR.IP.ADDRESS"]
   ```

3. **Deploy Infrastructure**
   ```powershell
   terraform plan
   terraform apply
   ```

## Security Features

- Storage account access restricted to specified IP addresses
- Azure services bypass enabled for monitoring
- Diagnostic settings configured for auditing
- 30-day retention policy for logs and metrics

## Monitoring Setup

- Log Analytics Workspace for centralized logging
- Storage account metrics collection
- Availability monitoring and alerting
- Email notifications for critical events

## Best Practices

- Store sensitive data in `terraform.tfvars` (not in version control)
- Use Azure CLI authentication
- Keep Terraform provider and Azure RM versions up to date
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

1. Create a feature branch
2. Make your changes
3. Run `terraform fmt` before committing
4. Submit a pull request

## Maintenance

- Regularly update provider versions
- Review and adjust IP allowlists as needed
- Monitor storage metrics and adjust thresholds
- Update email recipients for alerts as team changes