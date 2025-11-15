# Fictional Octo System

> *"Because managing multi-cloud infrastructure should feel less like wrestling an octopus and more like conducting an orchestra"* 🐙🎵

A multi-cloud infrastructure deployment repository for managing Azure, AWS, and GCP resources, monitoring, and security configurations. *(Why choose one cloud when you can complicate your life with all three?)* ☁️☁️☁️

## Overview

This repository contains Infrastructure as Code (IaC) templates and configurations for deploying and managing **Azure**, **AWS**, and **Google Cloud Platform (GCP)** resources, with a focus on secure storage, monitoring, and virtual networking components. *(In other words: Everything you need to run tri-cloud infrastructure like a boss, with triple the complexity and triple the buzzwords)*

**Multi-Cloud Strategy**: We deploy similar infrastructure patterns across Azure, AWS, and GCP, allowing for:
- 🎯 **Vendor flexibility** *(when one cloud provider has an outage, you have... two other cloud providers with outages)*
- 💼 **Team skill development** *(because learning two cloud platforms wasn't challenging enough)*
- 📊 **Cost optimization** *(use the cheapest option for each service, if you can figure out all their pricing models)*
- 🌍 **Geographic reach** *(Azure in some places, AWS in others, GCP everywhere, sanity nowhere)*
- 🔐 **Authentication mastery** *(Azure CLI, AWS CLI, gcloud CLI - collect them all!)*

## Repository Structure

```
fictional-octo-system/
├── terraform/                    # Core Terraform configurations (Azure)
│   ├── main.tf                  # Core infrastructure setup
│   ├── variables.tf             # Variable definitions
│   ├── monitoring.tf            # Azure Monitor configuration
│   ├── backend.tf               # State storage configuration
│   ├── tf.sh / tf.ps1           # Dynamic IP wrapper scripts
│   ├── update-ip.sh / update-ip.ps1  # IP management utilities
│   ├── QUICKSTART_DYNAMIC_IP.md # Quick start guide for dynamic IPs
│   ├── TERRAFORM_STATE_ACCESS.md # Comprehensive state access guide
│   └── README.md                # Terraform-specific documentation
├── deployments/
│   ├── azure/                   # 🔵 Azure Infrastructure
│   │   ├── app-registration/    # Azure AD app registration automation
│   │   ├── key-vault/           # Azure Key Vault with RBAC
│   │   ├── vm-automation/       # Automated VM deployment with Bastion
│   │   └── policies/            # Azure Policy templates (ISO 27001)
│   ├── aws/                     # 🟠 AWS Infrastructure
│   │   ├── terraform-state-bootstrap/  # S3 + DynamoDB for state management
│   │   ├── budgets/             # AWS Budgets and cost management
│   │   ├── policies/            # AWS Config rules for compliance
│   │   ├── iam/                 # IAM roles and OIDC providers
│   │   ├── kms/                 # KMS key management
│   │   ├── secrets/             # Secrets Manager configuration
│   │   ├── compute/             # EC2 Systems Manager automation
│   │   ├── networking/          # VPC and networking components
│   │   └── README.md            # AWS-specific documentation
│   └── gcp/                     # 🔴 Google Cloud Platform Infrastructure
│       ├── bootstrap/           # GCS bucket + Workload Identity for state
│       ├── iam/                 # IAM roles and Workload Identity Federation
│       ├── security/            # Organization policies and encryption
│       ├── secrets/             # Google Secret Manager
│       ├── cost-management/     # GCP budgets and billing alerts
│       ├── compute/             # GCE and GKE configurations
│       ├── networking/          # VPC and firewall rules
│       ├── storage/             # Cloud Storage and Cloud SQL
│       ├── monitoring/          # Cloud Logging and Monitoring
│       └── README.md            # GCP-specific documentation
├── .github/                     # GitHub Actions workflows and templates
│   └── workflows/               # CI/CD pipeline definitions
├── LICENSE                      # MIT License
├── SECURITY.md                  # Security policy
└── README.md                   # This file (you are here 📍)
```

## Features

> *"All the things you wish Azure, AWS, AND GCP did automatically, now actually automated"* 🚀

### Multi-Cloud Infrastructure
- **Tri-Cloud Deployment**: Parallel infrastructure patterns across Azure, AWS, and GCP *(because one cloud provider is too easy, two is getting there, three is just showing off)*
- **Unified Terraform State**: Separate state backends per cloud (Azure Blob Storage, S3, and GCS) *(organized chaos across three dimensions)*
- **Nordic Region Strategy**: 
  - **AWS**: Stockholm (`eu-north-1`) *(keeping latency low and Swedes happy)*
  - **Azure**: Sweden Central (`swedencentral`) *(because why not double down on Sweden)*
  - **GCP**: Finland (`europe-north1`) *(spreading the Nordic love to Finland)*
- **Policy Mirroring**: ISO 27001 compliance patterns across all three clouds *(triple the compliance, triple the fun)*
- **OIDC Authentication**: Passwordless GitHub Actions across all platforms *(no more secret keys lying around)*

### Infrastructure Management (Azure)
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

**Azure:**
- Log Analytics Workspace *(all your logs in one place, like a well-organized filing cabinet)*
- Storage metrics collection *(because storage costs can sneak up on you)*
- Availability monitoring *(the early warning system you actually need)*
- Alert configurations *(emails that matter, not spam)*

**AWS:**
- AWS Config for compliance monitoring *(the robot that checks your homework)*
- AWS Budgets for cost tracking and alerts *(emails when you're about to exceed your limit)*
- CloudWatch for logs and metrics *(like Log Analytics, but with more confusing pricing)*
- SNS for alerting *(because your phone needs more notifications at 3 AM)*
- Config rules for encryption enforcement *(encrypt all the things!)*

**GCP:**
- Cloud Monitoring for metrics and alerting *(the Google way of saying "your stuff is broken")*
- Cloud Logging for centralized log management *(like the other two, but with better search)*
- Security Command Center for security insights *(Google's security PhD telling you what's wrong)*
- Cloud Billing budgets and alerts *(because even Google doesn't want you to go bankrupt)*
- Organization policies for compliance *(constraints that prevent you from doing stupid things)*

### Infrastructure Management (AWS)
- **Terraform State Backend**: S3 bucket with DynamoDB locking in eu-north-1 *(because Stockholm > Virginia for Finnish users)*
- **AWS Budgets & Cost Management**: Automated spending limits with email alerts *(know before you owe)*
- **AWS Config Rules**: Automated compliance checking (encryption, HTTPS, KMS) *(robots enforcing security policies)*
- **IAM OIDC Integration**: Passwordless GitHub Actions authentication *(no more AWS access keys!)*
- **Secrets Manager**: AWS equivalent to Key Vault *(planned)*
- **Systems Manager**: EC2 automation and patch management *(planned)*

### Infrastructure Management (GCP)
- **Terraform State Backend**: GCS bucket with built-in locking in europe-north1 *(Finland > Virginia for Finnish users)*
- **Workload Identity Federation**: Passwordless GitHub Actions authentication *(the Google way of saying "no service account keys")*
- **Cloud Billing Budgets**: Automated spending limits with email alerts *(because even Google knows cloud costs can surprise you)*
- **Organization Policies**: Automated compliance and security constraints *(Google's way of preventing you from shooting yourself in the foot)*
- **Secret Manager**: Google's take on secret storage *(like the others, but with Google-scale reliability)*
- **Cloud IAM**: Fine-grained permissions with custom roles *(because sometimes you need exactly 47 permissions, not 46 or 48)*

## Getting Started

### Prerequisites

> *"The bare minimum you need before embarking on this tri-cloud adventure"* 🎒

- **Azure CLI** installed and configured *(bonus points if `az login` works on the first try)*
- **AWS CLI** installed and configured *(because `aws configure` is totally intuitive)*
- **Google Cloud CLI** installed and configured *(gcloud: the CLI with the most subcommands)*
- **Terraform** (version >= 1.3.0) *(keeping it modern, unlike that Jenkins server from 2014)*
- **Git** for version control *(you are using version control, right? RIGHT?)*
- Appropriate cloud subscription permissions:
  - **Azure**: Subscription Contributor *(a.k.a. someone trusts you with the keys to the kingdom)*
  - **AWS**: Administrative access or PowerUserAccess *(with great power comes great responsibility)*
  - **GCP**: Project Editor or custom IAM roles *(Google's way of saying "you can break things")*

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

#### For GCP Bootstrap and Workload Identity

> *"The Google way of saying 'trust us with your infrastructure'"* ☁️

```bash
# Step 1: Authenticate with GCP
gcloud auth login
gcloud auth application-default login
gcloud config set project YOUR-PROJECT-ID

# Step 2: Bootstrap GCS state storage first
cd deployments/gcp/bootstrap/state-storage/
terraform init
terraform apply

# Step 3: Migrate state to GCS (follow prompts)
terraform init -migrate-state

# Step 4: Set up Workload Identity Federation
cd ../iam/workload-identity/
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars  # Configure your GitHub repositories

terraform init
terraform apply

# Step 5: Add GitHub secrets (output will show you what to add)
terraform output github_secrets_config
```

📖 **Detailed guides**: 

**Azure Deployments:**
- [Dynamic IP Quick Start](terraform/QUICKSTART_DYNAMIC_IP.md)
- [VM Automation Guide](deployments/azure/vm-automation/README.md)
- [Azure AD App Registration](deployments/azure/app-registration/README.md)
- [Azure Key Vault with RBAC](deployments/azure/key-vault/README.md)
- [Terraform State Access](terraform/TERRAFORM_STATE_ACCESS.md)

**AWS Deployments:**
- [AWS Infrastructure Overview](deployments/aws/README.md) *(Start here for AWS setup)*
- [Terraform State Bootstrap](deployments/aws/terraform-state-bootstrap/README.md) *(Do this first)*
- [AWS Budget & Cost Management](deployments/aws/budgets/cost-management/QUICKSTART.md) *(Set spending limits before you deploy)*
- [Encryption Baseline Policies](deployments/aws/policies/encryption-baseline/README.md)

**GCP Deployments:**
- [GCP Infrastructure Overview](deployments/gcp/README.md) *(Start here for GCP setup)*
- [GCP Bootstrap Quick Start](deployments/gcp/QUICKSTART.md) *(5-minute setup guide)*
- [State Storage Bootstrap](deployments/gcp/bootstrap/state-storage/README.md) *(Do this first)*
- [Workload Identity Federation](deployments/gcp/iam/workload-identity/README.md) *(Passwordless GitHub Actions)*

### Security Features

> *"Layered security: Because one wall is never enough when protecting your multi-cloud kingdom"* 🏰

**Multi-Cloud Security:**
- **Passwordless Authentication**: OIDC/Workload Identity Federation across all three clouds *(the future is now, old man)*
- **No Long-Lived Secrets**: No access keys, service account keys, or client secrets in GitHub *(security by design)*
- **Short-Lived Tokens**: All authentication tokens expire within 1 hour *(even if compromised, damage is limited)*
- **Repository-Scoped Access**: Each GitHub repo only gets access to what it needs *(principle of least privilege)*

**Azure-Specific:**
- **Key Vault with RBAC**: Centralized secrets management with modern RBAC authorization *(not the legacy access policies that let Contributors grant themselves access)*
- **Purge Protection**: Prevent accidental or malicious deletion of secrets *(even admins can't bypass this)*
- **Azure AD App Registration**: Automated service principal creation and management *(no more "I forgot where I put that client secret")*
- **Dynamic IP Management**: Automatic IP whitelisting for Terraform state access *(works from home, office, or that coffee shop with the good WiFi)*
- **Private VM Deployment**: VMs with no public IPs, secured via Azure Bastion *(because exposing SSH to the internet is a bold strategy)*
- **Automated VM Lifecycle**: Daily start/stop schedules (7 AM/7 PM Finnish time) *(your VMs keep better hours than you do)*

**AWS-Specific:**
- **IAM OIDC Provider**: GitHub Actions authentication without access keys *(no more AWS_ACCESS_KEY_ID in your environment)*
- **AWS Config Rules**: Automated compliance checking for encryption and security *(robots enforcing your security policies)*
- **KMS Integration**: Customer-managed encryption keys for all services *(your data, your keys)*

**GCP-Specific:**
- **Workload Identity Federation**: Google's approach to keyless authentication *(no service account keys anywhere)*
- **Organization Policies**: Preventive security controls at the organization level *(Google preventing you from doing stupid things)*
- **Secret Manager**: Secure secrets storage with automatic encryption *(like the others, but with Google-grade security)*
- **Cloud IAM Custom Roles**: Fine-grained permissions tailored to your needs *(because sometimes you need exactly 47 permissions, not 46 or 48)*

**Compliance & Monitoring:**
- **ISO 27001 Patterns**: Security policies and controls across all clouds *(checking boxes AND securing data)*
- **Comprehensive Logging**: Centralized logging and monitoring across platforms *(Big Brother, but for infrastructure)*
- **Encryption Everywhere**: Data encrypted at rest and in transit across all platforms *(encrypt all the things!)*
- **Audit Trails**: Complete audit logs for all infrastructure changes *(because compliance teams love paperwork)*

## Monitoring Capabilities

**Multi-Cloud Observability:**
- **Azure**: Log Analytics Workspace, Storage metrics, Azure Monitor alerts
- **AWS**: CloudWatch logs and metrics, AWS Config compliance monitoring, SNS alerting
- **GCP**: Cloud Logging, Cloud Monitoring, Security Command Center, Billing alerts
- **Unified Alerting**: Email notifications for critical events across all platforms
- **Cost Monitoring**: Budget alerts and spending tracking in all three clouds

## Multi-Cloud Comparison

> *"Choose your poison: All clouds are great until you see the bill"* 💸

| Feature | Azure | AWS | GCP |
|---------|--------|-----|-----|
| **State Storage** | Blob Storage | S3 + DynamoDB | Cloud Storage (built-in locking) |
| **Nordic Region** | Sweden Central | eu-north-1 (Stockholm) | europe-north1 (Finland) |
| **Authentication** | Managed Identity/OIDC | IAM OIDC Provider | Workload Identity Federation |
| **Secrets Management** | Key Vault | Secrets Manager | Secret Manager |
| **Cost Control** | Cost Management | Budgets + Billing Alarms | Billing Budgets |
| **Monitoring** | Azure Monitor | CloudWatch | Cloud Monitoring |
| **Compliance** | Azure Policy | AWS Config | Organization Policies |
| **Free Tier** | 12 months + always free | 12 months + always free | Always free (most generous) |
| **CLI Quality** | Decent (`az`) | Functional (`aws`) | Excellent (`gcloud`) |
| **Documentation** | Good | Comprehensive | Outstanding |
| **Pricing Complexity** | High | Very High | Moderate |

## Contributing

> *"We accept PRs, bug reports, and well-structured complaints about all three cloud pricing models"* 🤝

Contributions are welcome! Please read our [Security Policy](SECURITY.md) before contributing. *(Yes, we actually have one)*

1. Fork the repository *(the GitHub way of saying "take a copy")*
2. Create a feature branch *(not called `fix-stuff` or `test123`, please)*
3. Make your changes *(with commit messages that explain WHY, not just WHAT)*
4. Run `terraform fmt` on any Terraform changes *(because consistent formatting matters)*
5. Submit a pull request *(include memes for faster review)*

## Best Practices

> *"Best practices: Because 'it works on my machine' is not a deployment strategy"* 🌟

### General (All Clouds)

- Store sensitive data in `terraform.tfvars` (not in version control)  
  *(if I see secrets in your git history, we're having a conversation)*

- Keep Terraform provider versions up to date  
  *(version 1.0 from 2017 is not "stable", it's ancient)*

- Review monitoring thresholds and schedules regularly  
  *(what made sense in January is chaos by December)*

- Use `.gitignore` to exclude state files and secrets  
  *(each module has one, use it)*

- Always run `terraform plan` before `apply`  
  *(surprises are for birthdays, not production deployments)*

- Use consistent naming conventions across all clouds  
  *(your future self will thank you)*

- Test authentication before starting deployments  
  *(az login && aws sts get-caller-identity && gcloud auth list)*

### Azure-Specific

- **Use wrapper scripts** (`tf.sh`/`tf.ps1`) instead of direct `terraform` commands  
  *(they're there for a reason, not just decoration)*

- Use Azure CLI authentication with dynamic IP management  
  *(because your IP changes more than your mind)*

- **Clean up old IPs** periodically using `cleanup-old-ips.sh`  
  *(digital hoarding is still hoarding)*

- Use Azure Bastion for secure VM access (no public IPs)  
  *(exposing port 22 to the internet is how you make friends with hackers)*

### AWS-Specific

- **Always deploy state backend first** (terraform-state-bootstrap)  
  *(you need somewhere to store your state before creating other resources)*

- Use `eu-north-1` (Stockholm) region for consistency  
  *(unless you have a good reason, stick with the plan)*

- Leverage AWS Config for compliance automation  
  *(let robots enforce your security policies)*

- Use IAM roles with OIDC instead of long-lived credentials  
  *(passwordless is the way, grasshopper)*

### GCP-Specific

- **Bootstrap first, then deploy** (bootstrap/state-storage → iam/workload-identity)  
  *(you need GCS bucket and Workload Identity pool before anything else)*

- Use `europe-north1` (Finland) region for Nordic consistency  
  *(keeping the infrastructure close to Nokia's homeland)*

- **Use Application Default Credentials** for local development  
  *(gcloud auth application-default login is your friend)*

- **Never create service account keys** - use Workload Identity Federation  
  *(if Google doesn't recommend it, neither should you)*

- Leverage Organization Policies for preventive security  
  *(let Google prevent you from making expensive mistakes)*

- Enable Cloud Audit Logs for all services  
  *(because compliance teams need to know who touched what and when)*

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

> *"We're here to help (during business hours, mostly)"* 💬

For questions, issues, or support:
- Create an issue in this repository *(use the template, please)*
- Review our [Security Policy](SECURITY.md) for security-related concerns *(don't put credentials in issue titles, it's happened)*

## Acknowledgments

> *"Standing on the shoulders of giants, with a generous helping of StackOverflow and three different cloud documentation sites"* 🙏

- Built by KuduWorks team *(with love, coffee, and occasional frustration with cloud pricing)*
- Implements Azure, AWS, and GCP Terraform best practices *(learned the hard way so you don't have to)*
- Demonstrates passwordless authentication across all major cloud providers *(because service account keys are so 2019)*
- Part of the organization's multi-cloud infrastructure initiative *(fancy words for "we're taking this cloud thing very seriously")*
- Inspired by Nordic efficiency and the desire to avoid vendor lock-in *(diversification is key)*
