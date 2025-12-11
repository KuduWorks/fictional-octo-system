# Fictional Octo System

> *"Because managing multi-cloud infrastructure should feel less like wrestling an octopus and more like conducting an orchestra"* 🐙🎵

A multi-cloud infrastructure deployment repository for managing Azure, AWS, and GCP resources, monitoring, and security configurations. *(Why choose one cloud when you can complicate your life with all three?)* ☁️☁️☁️

## Table of Contents

- [Overview](#overview)
- [Repository Structure](#repository-structure)
- [Docs & Reference](#docs--reference)
- [Features](#features)
- [Getting Started](#getting-started)
- [Security Features](#security-features)
- [Monitoring Capabilities](#monitoring-capabilities)
- [Multi-Cloud Comparison](#multi-cloud-comparison)
- [Best Practices](#best-practices)
- [Contributing](#contributing)
- [Support](#support)
- [License](#license)
- [Acknowledgments](#acknowledgments)

## Overview

This repository contains Infrastructure as Code (IaC) templates and configurations for deploying and managing **Azure**, **AWS**, and **Google Cloud Platform (GCP)** resources, with a focus on secure storage, monitoring, and virtual networking components. *(In other words: Everything you need to run tri-cloud infrastructure like a boss, with triple the complexity and triple the buzzwords)*

**Multi-Cloud Strategy**: We deploy similar infrastructure patterns across Azure, AWS, and GCP, allowing for:
- 🎯 **Vendor flexibility** *(when one cloud provider has an outage, you have... two other cloud providers with outages)*
- 💼 **Team skill development** *(because learning two cloud platforms wasn't challenging enough)*
- 📊 **Cost optimization** *(use the cheapest option for each service, if you can figure out all their pricing models)*
- 🌍 **Geographic reach** *(Azure in some places, AWS in others, GCP everywhere, sanity nowhere)*
- 🔐 **Authentication mastery** *(Azure CLI, AWS CLI, gcloud CLI - collect them all!)*

## Repository Structure

- [terraform/](terraform/README.md) — Core Terraform configs (Azure) + scripts and storage docs *(organized chaos, but tidy)*
  - [QUICKSTART_DYNAMIC_IP.md](terraform/QUICKSTART_DYNAMIC_IP.md) — Dynamic IP quick start
  - [TERRAFORM_STATE_ACCESS.md](terraform/TERRAFORM_STATE_ACCESS.md) / [STORAGE_ACCESS.md](terraform/STORAGE_ACCESS.md) — State access playbooks
- deployments/ — Cloud-specific payloads
  - [azure/](deployments/azure/README.md) 🔵 — app registration, Key Vault, VM automation, policies, reporting, and the [naming-convention module](deployments/azure/modules/naming-convention/README.md)
    - [policies](deployments/azure/policies/README.md): [cost-management](deployments/azure/policies/cost-management/), [iso27001-crypto](deployments/azure/policies/iso27001-crypto/), [region-control](deployments/azure/policies/region-control/), [security-baseline](deployments/azure/policies/security-baseline/), [vm-encryption](deployments/azure/policies/vm-encryption/)
    - [reporting](deployments/azure/reporting/README.md) — export scripts for IAM
  - [aws/](deployments/aws/README.md) 🟠 — state bootstrap, budget monitoring, CloudTrail org setup, IAM, KMS, networking, secrets, SNS
    - [terraform-state-bootstrap](deployments/aws/terraform-state-bootstrap/README.md) — S3 + DynamoDB backend
    - [budget-monitoring](deployments/aws/budget-monitoring/README.md) — keep spend honest
    - [cloudtrail-organization](deployments/aws/cloudtrail-organization/README.md) — org-wide trails
    - [compute](deployments/aws/compute/) — SSM automation
    - [finops-lambda](deployments/aws/finops-lambda/) — cost-minded Lambdas
    - [iam](deployments/aws/iam/) — roles and OIDC
    - [kms](deployments/aws/kms/) — key management
    - [networking](deployments/aws/networking/) — VPC bits
    - [secrets](deployments/aws/secrets/) — Secrets Manager setup
    - [sns-notifications](deployments/aws/sns-notifications/) — alerts that actually alert
    - [policies](deployments/aws/policies/README.md): [region-control](deployments/aws/policies/region-control/), [encryption-baseline](deployments/aws/policies/encryption-baseline/), [organization-protection](deployments/aws/policies/organization-protection/)
  - [gcp/](deployments/gcp/README.md) 🔴 — bootstrap, IAM, security, cost, monitoring, networking, storage, compute
    - [QUICKSTART](deployments/gcp/QUICKSTART.md) — 5-minute setup
    - [AUTHENTICATION_SETUP](deployments/gcp/AUTHENTICATION_SETUP.md) — auth prep
    - [bootstrap/state-storage](deployments/gcp/bootstrap/state-storage/) — GCS state bucket
    - [iam/workload-identity](deployments/gcp/iam/workload-identity/) — keyless GitHub Actions
    - [security](deployments/gcp/security/) — org policies & encryption
    - [cost-management](deployments/gcp/cost-management/) — budgets
    - [monitoring](deployments/gcp/monitoring/) — logging/metrics
    - [networking](deployments/gcp/networking/) — VPC + firewalls
    - [storage](deployments/gcp/storage/) — GCS/SQL
    - [compute](deployments/gcp/compute/) — GCE/GKE
- [.github/workflows](.github/workflows/) — CI/CD pipelines *(robots doing the chores)*
- [LICENSE](LICENSE) — MIT
- [SECURITY.md](SECURITY.md) — Policies you should actually read
- [README.md](README.md) — This file (you are here 📍)

## Docs & Reference

- [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) — be excellent to each other
- [CONTRIBUTING.md](CONTRIBUTING.md) — PR etiquette + guardrails
- [PERFORMANCE_IMPROVEMENTS.md](PERFORMANCE_IMPROVEMENTS.md) — where to squeeze speed
- [deployments/STATE_MANAGEMENT.md](deployments/STATE_MANAGEMENT.md) — how we wrangle Terraform state across clouds

## Features

Concise overview — see per-cloud docs and `terraform/` for full details.

- **Multi-Cloud strategy**: Tri-cloud IaC patterns with per-cloud state backends and a Nordic region strategy. See [deployments/azure/](deployments/azure/), [deployments/aws/](deployments/aws/), [deployments/gcp/](deployments/gcp/) and [terraform/](terraform/).
- **Security & Identity**: OIDC / Workload Identity Federation, Key Vault / Secrets Manager patterns, and organization-level policies for prevention and compliance.
- **Infrastructure Management**: Reusable modules, automated VM scheduling, IP management utilities, and per-cloud state bootstraps.
- **Cost & Governance**: Budget alerts, SCPs/org policies, and monitoring playbooks to manage spend and compliance.

## Monitoring

Monitoring summary — detailed monitoring configs live under each cloud folder.

- **Azure**: Centralized logs and alerts via Log Analytics and Azure Monitor. See [deployments/azure/](deployments/azure/).
- **AWS**: Compliance & observability with AWS Config, CloudWatch, Budgets, and SNS alerting. See [deployments/aws/](deployments/aws/).
- **GCP**: Cloud Monitoring/Logging and Security Command Center for insights and alerts. See [deployments/gcp/](deployments/gcp/).
- **Unified**: Email-based alerting and cost alerts across clouds; integrate with your PagerDuty/Slack as needed.

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

#### For Azure Naming Convention Module

```bash
# Use the naming convention module in any Azure Terraform deployment
cd your-azure-project/

# Reference the module in your main.tf
cat << 'EOF' > main.tf
module "naming" {
  source = "../../deployments/azure/modules/naming-convention"
  
  workload    = "myapp"
  environment = "prod"
  region      = "eastus"
  instance    = "01"
  
  additional_tags = {
    CostCenter = "Engineering"
    Owner      = "YourTeam"
  }
}

resource "azurerm_resource_group" "example" {
  name     = module.naming.resource_group_name  # rg-myapp-prod-eus
  location = "eastus"
  tags     = module.naming.common_tags
}

resource "azurerm_storage_account" "example" {
  name                     = module.naming.storage_account_name  # stmyappprodeus01
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = module.naming.common_tags
}
EOF

terraform init
terraform plan
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
- [Azure Naming Convention Module](deployments/azure/modules/naming-convention/README.md) *(Consistent naming across all Azure resources)*
- [Terraform State Access](terraform/TERRAFORM_STATE_ACCESS.md)

**AWS Deployments:**
- [AWS Infrastructure Overview](deployments/aws/README.md) *(Start here for AWS setup)*
- [Terraform State Bootstrap](deployments/aws/terraform-state-bootstrap/README.md) *(Do this first)*
- [AWS Budget Monitoring](deployments/aws/budget-monitoring/README.md) *(Set spending limits before you deploy)*
- [Region Control SCPs](deployments/aws/policies/region-control/README.md) *(✅ Active: Stockholm-only enforcement)*
- [Encryption Baseline SCPs](deployments/aws/policies/encryption-baseline/README.md) *(✅ Active: S3 public access blocking)*

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
- **Service Control Policies**: ✅ **ACTIVE** - Organization-level preventive controls
  - RegionRestriction SCP blocks non-Stockholm deployments *(no more "oops, wrong region")*
  - DenyS3PublicAccess SCP prevents public buckets *(hard block, no exceptions)*
  - Global services exempted (IAM, Route53, CloudFront) *(because some services don't have regions)*
- **Account-Level S3 Blocks**: All four public access settings enforced *(belts and suspenders approach)*
- **IAM OIDC Provider**: GitHub Actions authentication without access keys *(no more AWS_ACCESS_KEY_ID in your environment)*
- **AWS Config Rules**: Automated compliance monitoring (9 rules) *(detection layer for continuous visibility)*
- **KMS Integration**: Customer-managed encryption keys for all services *(your data, your keys)*

**GCP-Specific:**
- **Workload Identity Federation**: Google's approach to keyless authentication *(no service account keys anywhere)*
- **Organization Policies**: Preventive security controls at the organization level *(Google preventing you from doing stupid things)*
- **Secret Manager**: Secure secrets storage with automatic encryption *(like the others, but with Google-grade security)*
- **Cloud IAM Custom Roles**: Fine-grained permissions tailored to your needs *(because sometimes you need exactly 47 permissions, not 46 or 48)*

**Compliance & Monitoring:**
- **ISO 27001 Patterns**: Security policies and controls across all clouds *(checking boxes AND securing data)*
- **Preventive Controls**: ✅ AWS SCPs actively blocking non-compliant actions *(prevention > detection)*
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
| **Compliance** | Azure Policy | ✅ SCPs + AWS Config | Organization Policies |
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

- **Use the naming convention module** for all Azure resources  
  *(consistent names = happy teams, no more "was it rg-prod or prod-rg?")*

- **Increment instance numbers** for multiple resources of the same type  
  *(stmyappprodeus01, stmyappprodeus02 - sequential and sensible)*

### AWS-Specific

- **Always deploy state backend first** (terraform-state-bootstrap)  
  *(you need somewhere to store your state before creating other resources)*

- **Deploy policies in order**: region-control → encryption-baseline  
  *(establish geographic boundaries before enforcing security controls)*

- **Wait for SCP propagation**: Allow 5-15 minutes after deploying SCPs  
  *(AWS needs time to distribute policies globally)*

- Use `eu-north-1` (Stockholm) region for consistency  
  *(SCPs enforce this, but good to know anyway)*

- **SCPs are organization-level**: Requires AWS Organizations with SCPs enabled  
  *(if you don't have an organization, start there)*

- Leverage AWS Config for compliance **monitoring** (SCPs handle **prevention**)  
  *(defense in depth: block + detect)*

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
