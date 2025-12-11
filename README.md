# Fictional Octo System

Multi-cloud Terraform modules and deployment examples for Azure, AWS, and GCP. Pick a cloud, follow its README.

## Table of Contents

- [Quick Links](#quick-links)
- [Features](#features)
- [Getting Started](#getting-started)
- [Contributing](#contributing)

## Quick Links

- **Azure** 💠: [deployments/azure/](deployments/azure/) — app registration, Key Vault, modules
- **AWS** 🟠: [deployments/aws/](deployments/aws/) — state bootstrap, budgets, IAM, networking
- **GCP** 🔴: [deployments/gcp/](deployments/gcp/) — bootstrap, workload identity, security
- **Terraform root**: [terraform/](terraform/) — shared state backend and VNet examples


## Features

- **Multi-cloud IaC**: Terraform modules for Azure, AWS, and GCP
- **Security**: OIDC authentication, Key Vault/Secrets Manager patterns
- **Cost management**: Budget alerts and monitoring examples
- **State backends**: Bootstrap modules for each cloud provider

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
