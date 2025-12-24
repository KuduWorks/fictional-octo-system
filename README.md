# Fictional Octo System

Multi-cloud Terraform modules and deployment examples for Azure, AWS, and GCP. Pick a cloud, follow its README.

## Table of Contents

- [Quick Links](#quick-links)
- [Features](#features)
- [Getting Started](#getting-started)
- [Contributing](#contributing)

## Quick Links

- **Azure** 🔵: [deployments/azure/](deployments/azure/) — app registration, Key Vault, policies, communication services, reporting
- **AWS** 🟠: [deployments/aws/](deployments/aws/) — state bootstrap, budgets, SCPs, FinOps Lambda, CloudTrail, GitHub OIDC
- **GCP** 🔴: [deployments/gcp/](deployments/gcp/) — bootstrap, workload identity, security, cost management
- **Terraform root**: [terraform/](terraform/) — shared state backend and VNet examples


## Features

### Security & Compliance
- **Preventive enforcement**: Service Control Policies (AWS) and Azure Policies with Deny effects
- **OIDC authentication**: GitHub Actions integration without secrets (because math > secrets)
- **Encryption baselines**: S3, EBS, RDS, DynamoDB encryption requirements
- **Region controls**: Geographic restrictions (Stockholm for AWS, configurable for Azure)
- **Organization-level CloudTrail**: Centralized audit logging across AWS accounts
- **Key management**: Azure Key Vault and AWS KMS/Secrets Manager patterns

### Cost Management
- **Budget monitoring**: Multi-tier alerting for AWS and GCP with email notifications
- **FinOps automation**: Lambda functions for cost optimization and reporting
- **SNS notifications**: Real-time budget alerts (before the CFO finds out)
- **Cost allocation**: Tagging strategies and reporting templates

### Infrastructure as Code
- **Multi-cloud modules**: Reusable Terraform for Azure, AWS, and GCP
- **State management**: Remote backend bootstrap for all three clouds
- **Policy as Code**: ISO 27001-aligned security baselines
- **Automated compliance**: AWS Config rules and Azure Policy continuous monitoring

See individual cloud folders for detailed documentation.

## Getting Started

### Prerequisites

- Azure CLI, AWS CLI, or gcloud CLI (depending on your target cloud)
- Terraform >= 1.3.0
- Appropriate cloud permissions (Contributor/Admin level)

### Quick Start

**Azure:**
```bash
az login
cd deployments/azure/key-vault  # or app-registration
terraform init && terraform apply
```

**AWS:**
```bash
aws configure
cd deployments/aws/terraform-state-bootstrap
terraform init && terraform apply
```

**GCP:**
```bash
gcloud auth application-default login
cd deployments/gcp/bootstrap/state-storage
terraform init && terraform apply
```

Read the cloud-specific README in each `deployments/` folder for detailed setup.

## Contributing

Read [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md), then open a PR.

---

**License**: MIT | **Security**: [SECURITY.md](SECURITY.md)
