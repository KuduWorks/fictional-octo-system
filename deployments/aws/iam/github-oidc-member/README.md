# GitHub OIDC - Member Account

Configures GitHub Actions OIDC authentication for the **member account**.

## Deploy

```bash
cd deployments/aws/iam/github-oidc-member

# Authenticate to MEMBER account
export AWS_PROFILE=member  # or your member account profile

# Verify account
aws sts get-caller-identity

# Deploy
terraform init
terraform plan
terraform apply

# Get role ARN for GitHub secrets
terraform output github_actions_deploy_role_arn
```

Add the output ARN to GitHub secrets as `AWS_MEMBER_DEPLOY_ROLE_ARN` at:
https://github.com/<your-org>/<your-repo>/settings/secrets/actions

## Resources Created

- OIDC provider for GitHub (if not exists)
- `github-actions-member-readonly` - read-only role (for plan-only workflows)
- `github-actions-member-deploy` - deploy role for workload resources (VPC, apps, tagging)

## Security

- OIDC trust restricted to `main` and `develop` branches only
- Apply workflows require push to `main` (PRs cannot trigger deploys)
- Configure required reviewers on `aws-member` environment in GitHub for additional protection

## Next Steps

1. Ensure `AWS_MEMBER_DEPLOY_ROLE_ARN` secret is set in GitHub
2. Add Terraform modules to `deployments/aws/member/` folder
3. Workflow will automatically deploy on merge to main
