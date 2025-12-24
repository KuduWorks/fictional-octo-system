# Management Account Deployments

This directory contains Terraform configurations for resources deployed to the **AWS Management (Organization) account**.

## Typical Resources

- AWS Organizations configuration
- Organization-wide Service Control Policies (SCPs)
- CloudTrail organization trails
- Consolidated billing and budget alerts
- SNS topics for organization-wide notifications
- Cross-account IAM roles and OIDC providers

## Deployment

This module is deployed via GitHub Actions using the OIDC role defined in `AWS_MGMT_DEPLOY_ROLE_ARN`.

### Local Development

```bash
# Authenticate to management account
export AWS_PROFILE=mgmt  # or use aws-vault, SSO, etc.

# Initialize and plan
terraform init
terraform plan

# Apply changes (or use GitHub Actions)
terraform apply
```

## Backend Configuration

Ensure `backend.tf` points to your management account's Terraform state bucket.

Example:
```hcl
terraform {
  backend "s3" {
    bucket         = "your-mgmt-terraform-state"
    key            = "aws/management/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```
