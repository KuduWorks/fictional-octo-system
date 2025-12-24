# Member Account Deployments

This directory contains Terraform configurations for resources deployed to the **AWS Member (Child) account**.

## Typical Resources

- VPCs, subnets, and networking components
- Application workloads (EC2, ECS, Lambda, etc.)
- Account-specific security policies
- Tagging enforcement and compliance resources
- Account-level monitoring and logging

## Deployment

This module is deployed via GitHub Actions using the OIDC role defined in `AWS_MEMBER_DEPLOY_ROLE_ARN`.

### Local Development

```bash
# Authenticate to member account
export AWS_PROFILE=member  # or use aws-vault, SSO, etc.

# Initialize and plan
terraform init
terraform plan

# Apply changes (or use GitHub Actions)
terraform apply
```

## Backend Configuration

Ensure `backend.tf` points to your member account's Terraform state bucket (or shared bucket with unique key).

Example:
```hcl
terraform {
  backend "s3" {
    bucket         = "your-member-terraform-state"
    key            = "aws/member/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

## Testing SCPs

To test Service Control Policies created in the management account, use cross-account role assumption from the management account as documented in [deployments/aws/iam/cross-account-role/README.md](../iam/cross-account-role/README.md).
