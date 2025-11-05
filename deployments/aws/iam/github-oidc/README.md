# GitHub Actions OIDC for AWS

This module sets up OpenID Connect (OIDC) federation between GitHub Actions and AWS, eliminating the need for long-lived AWS credentials in GitHub secrets.

## What This Creates

- IAM OIDC provider for GitHub
- IAM roles for GitHub Actions workflows
- Trust policies restricting access to specific repositories
- Example IAM policies for common deployment scenarios

## Azure Equivalent

This mirrors the Azure app-registration setup but is simpler:
- No app registration needed
- No client secrets to manage
- Direct trust relationship via OIDC
- Role assumption instead of service principal login

## Usage in GitHub Actions

```yaml
name: Deploy to AWS
on: push

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::ACCOUNT_ID:role/github-actions-deploy
          aws-region: us-east-1
      
      - name: Deploy with Terraform
        run: |
          terraform init
          terraform apply -auto-approve
```

## Prerequisites

- GitHub repository with Actions enabled
- AWS account with IAM permissions
- Repository secrets configured (if using private repos)

## Security Features

- Scoped to specific GitHub repositories
- Subject claims validate repository and branch
- Time-limited credentials (1 hour default)
- No long-lived secrets in GitHub
