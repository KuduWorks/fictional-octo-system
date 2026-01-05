# GitHub OIDC - Member Account

Configures GitHub Actions OIDC authentication for the **member account** with separate roles for read-only (plan) and deployment operations.

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

# Get role ARNs for GitHub secrets
terraform output readonly_role_arn
terraform output deploy_role_arn
```

Add the output ARNs to GitHub secrets at:
https://github.com/<your-org>/<your-repo>/settings/secrets/actions

- `AWS_MEMBER_READONLY_ROLE_ARN` → Use for PRs and plan operations
- `AWS_MEMBER_DEPLOY_ROLE_ARN` → Use for deployments from `main` branch

## Resources Created

- OIDC provider for GitHub (if not exists)
- **Read-Only Role** (`github-actions-readonly` by default) - For all branches and PRs (plan, validate, lint)
- **Deploy Role** (`github-actions-deploy` by default) - For `main` branch only (terraform apply)
- **Admin Role** (optional) - For `main` branch only (full admin access)

## Security

### Trust Policies
- **Read-Only Role**: Allows all branches (`ref:refs/heads/*`) and tags
  - Explicitly blocks fork pull requests via `repository_owner` check
  - Attached policy: `ReadOnlyAccess`
  
- **Deploy Role**: Restricted to `main` branch only
  - Pattern: `repo:<org>/<repo>:ref:refs/heads/main`
  - Custom policy with deployment permissions

- **Admin Role**: Restricted to `main` branch only
  - Attached policy: `AdministratorAccess`

### GitHub Actions Workflow Pattern
```yaml
# PRs/feature branches use read-only role
- name: Configure AWS (Read-only)
  if: github.event_name == 'pull_request'
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_MEMBER_READONLY_ROLE_ARN }}
    aws-region: us-east-1  # Replace with your AWS region
    role-session-name: GitHubActions-${{ github.repository }}-${{ github.run_id }}

# Main branch uses deploy role
- name: Configure AWS (Deploy)
  if: github.ref == 'refs/heads/main'
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_MEMBER_DEPLOY_ROLE_ARN }}
    aws-region: us-east-1  # Replace with your AWS region
    role-session-name: GitHubActions-${{ github.repository }}-${{ github.run_id }}
```

### Additional Hardening
- Configure branch protection on `main` (required reviews, status checks)
- Use GitHub Environments with required reviewers for production
- Set GitHub Actions: "Require approval for all outside collaborators"
- Enable AWS CloudTrail and GuardDuty for monitoring

## Next Steps

1. Add both secrets to GitHub repository settings
2. Add Terraform modules to `deployments/aws/member/` folder
3. Configure branch protection rules on `main`
4. Workflow will automatically plan on PRs, deploy on merge to main
