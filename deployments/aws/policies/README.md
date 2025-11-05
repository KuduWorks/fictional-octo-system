# AWS Policy Configurations

This directory contains AWS compliance and governance policies that mirror the Azure Policy setup.

## Modules

### encryption-baseline/
Mirrors `azure/policies/iso27001-crypto/`

AWS Config rules and SCPs for:
- S3 bucket encryption enforcement
- EBS volume encryption
- RDS encryption requirements
- KMS CMK usage policies
- TLS/SSL enforcement

### region-control/
Mirrors `azure/policies/region-control/`

Service Control Policies (SCPs) for:
- Restricting resource creation to specific regions
- Preventing cross-region data transfer
- Region-based compliance requirements

### resource-tagging/
AWS tagging policies for:
- Required tag enforcement
- Tag-based access control
- Cost allocation tags

## AWS Config vs Azure Policy

**Detection**: AWS Config rules evaluate resource compliance (similar to Azure Policy audit effect)

**Prevention**: Service Control Policies (SCPs) prevent non-compliant actions at the organization level (similar to Azure Policy deny effect)

**Remediation**: AWS Config can trigger Lambda functions for automatic remediation (similar to Azure Policy deployIfNotExists/modify effects)

## Getting Started

Each subdirectory is a standalone Terraform module. Navigate to the specific module and initialize:

```bash
cd encryption-baseline/
terraform init
terraform plan
```
