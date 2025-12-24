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

Add the output ARN to GitHub secrets as `AWS_MGMT_DEPLOY_ROLE_ARN`.

## Resources Created

- OIDC provider for GitHub (if not exists)
- `github-actions-mgmt-readonly` - read-only role
- `github-actions-mgmt-deploy` - deploy role for org resources

## Next Steps

After deployment, update `.github/workflows/deploy-aws.yml` to use `AWS_MGMT_DEPLOY_ROLE_ARN`.
