# GitHub OIDC - Management Account

Configures GitHub Actions OIDC authentication for the **management account**.

## Deploy

```bash
cd deployments/aws/iam/github-oidc-management

# Authenticate to MANAGEMENT account
export AWS_PROFILE=mgmt  # or your management account profile

# Verify account
aws sts get-caller-identity

# Deploy
terraform init
terraform plan
terraform apply

# Get role ARN for GitHub secrets
terraform output github_actions_deploy_role_arn
```

Add the output ARN to GitHub secrets as `AWS_MGMT_DEPLOY_ROLE_ARN` at:
https://github.com/KuduWorks/fictional-octo-system/settings/secrets/actions

## Resources Created

- OIDC provider for GitHub (if not exists)
- `github-actions-mgmt-readonly` - read-only role (for plan-only workflows)
- `github-actions-mgmt-deploy` - deploy role for org resources (SCPs, CloudTrail, budgets)

## Security

- OIDC trust restricted to `main` and `develop` branches only
- Apply workflows require push to `main` (PRs cannot trigger deploys)
- Configure required reviewers on `aws-management` environment in GitHub for additional protection

## Next Steps

1. Ensure `AWS_MGMT_DEPLOY_ROLE_ARN` secret is set in GitHub
2. Deploy member account OIDC in `../github-oidc-member/`
3. Add Terraform modules to `deployments/aws/management/` folder
4. Workflow will automatically deploy on merge to main
