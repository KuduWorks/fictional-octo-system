# AWS Infrastructure Deployment

This directory contains Terraform configurations for AWS infrastructure that mirrors the Azure setup in `deployments/azure/`.

## Structure

- **policies/** - AWS Config rules, Service Control Policies (SCPs), and compliance configurations
  - `encryption-baseline/` - Encryption and cryptography policies (mirrors Azure ISO 27001 crypto)
  - `region-control/` - Region restriction policies
  - `resource-tagging/` - Tagging enforcement policies
  
- **iam/** - IAM roles, policies, and identity configurations
  - `github-oidc/` - GitHub Actions OIDC provider setup (mirrors Azure app-registration)
  - `service-roles/` - Cross-service IAM roles
  
- **kms/** - AWS KMS key management (mirrors Azure Key Vault)
  - `key-management/` - KMS keys, aliases, and policies
  
- **secrets/** - AWS Secrets Manager configurations
  - `secret-rotation/` - Automated secret rotation
  
- **compute/** - EC2 and compute automation
  - `ssm-automation/` - Systems Manager automation documents (mirrors Azure vm-automation)
  
- **networking/** - VPC and networking configurations
  - `vpc-baseline/` - VPC setup (mirrors Azure vnet)

## Prerequisites

1. AWS CLI installed and configured
2. Terraform >= 1.0
3. AWS credentials configured (via `aws configure` or environment variables)

## Getting Started

Each subdirectory contains its own Terraform configuration. Navigate to the specific module and run:

```bash
terraform init
terraform plan
terraform apply
```

## Azure vs AWS Service Mapping

| Azure Service | AWS Equivalent |
|--------------|----------------|
| Azure Policy | AWS Config Rules + SCPs |
| App Registration | IAM Roles + OIDC Provider |
| Key Vault | KMS + Secrets Manager |
| VM Automation | Systems Manager Automation |
| Management Groups | AWS Organizations |
| Resource Groups | Tags + Resource Groups |

## Multi-Cloud Strategy

This AWS infrastructure complements the Azure setup and demonstrates:
- Cross-cloud policy enforcement patterns
- Identity federation approaches
- Secret management strategies
- Compliance in heterogeneous environments
