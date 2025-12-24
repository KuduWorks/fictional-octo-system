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

Add the output ARN to GitHub secrets as `AWS_MEMBER_DEPLOY_ROLE_ARN`.

## Resources Created

- OIDC provider for GitHub (if not exists)
- `github-actions-member-readonly` - read-only role
- `github-actions-member-deploy` - deploy role for workload resources

## Next Steps

After deployment, update `.github/workflows/deploy-aws.yml` to use `AWS_MEMBER_DEPLOY_ROLE_ARN`.
