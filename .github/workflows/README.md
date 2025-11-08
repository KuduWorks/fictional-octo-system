# GitHub Actions Workflows

This directory contains automated workflows for both Azure and AWS infrastructure management.

## 🔐 Authentication

### Azure Workflows
- **Method**: OIDC (OpenID Connect) via Azure App Registration
- **Action**: `azure/login@v1`
- **Secrets Required**: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`

### AWS Workflows
- **Method**: OIDC (OpenID Connect) via IAM Identity Provider
- **Action**: `aws-actions/configure-aws-credentials@v4`
- **Secrets Required**: `AWS_ROLE_TO_ASSUME` (Uses OIDC role assumption)
- **Roles**:
  - `github-actions-readonly`: Read-only access for checks and reports
  - `github-actions-deploy`: Deployment access for infrastructure changes

## 📋 Available Workflows

### Azure Workflows

#### `azure-auth.yml`
Tests Azure OIDC authentication on main branch pushes and PRs.

#### `deploy-vnet-azure.yml`
Manually deploys Azure VNet infrastructure.
- **Trigger**: `workflow_dispatch` (manual)
- **Role**: Deployment

#### `blank.yml`
PR-triggered Azure login test.
- **Trigger**: Pull requests to main
- **Role**: Testing authentication

### AWS Workflows

#### `aws-cost-check.yml` 
Weekly AWS cost and resource report.
- **Trigger**: Every Monday at 9am UTC, or manual
- **Role**: `github-actions-readonly`
- **Reports**:
  - Current month costs
  - Budget status
  - Active resources (S3, EC2, Config)

#### `terraform-plan-aws.yml`
Runs Terraform plan on PRs for AWS infrastructure changes.
- **Trigger**: PRs that modify `deployments/aws/**/*.tf`
- **Role**: `github-actions-readonly`
- **Modules Checked**:
  - Encryption Baseline
  - Cost Management
  - GitHub OIDC
- **Output**: Comments plan results on PR

#### `deploy-aws.yml`
Deploys AWS infrastructure changes to production.
- **Trigger**: 
  - Push to main branch (auto)
  - Manual trigger with module selection
- **Role**: `github-actions-deploy`
- **Modules**:
  - Encryption Baseline
  - Cost Management
  - GitHub OIDC (manual only)

#### `aws-compliance-check.yml`
Daily AWS Config compliance report.
- **Trigger**: Daily at 8am UTC, or manual
- **Role**: `github-actions-readonly`
- **Checks**:
  - AWS Config rule compliance
  - Encryption rule status
  - Non-compliant resources

### Security Scanning

#### `tfsec.yml`
Scans Terraform files for security issues.
- **Trigger**: Push or PR with `*.tf` changes
- **Tool**: tfsec (Aqua Security)
- **Scope**: All Terraform files in repo

## 🚀 Usage Examples

### Running a Cost Report Manually
1. Go to **Actions** tab
2. Select **AWS Cost Report**
3. Click **Run workflow**
4. View the results in the workflow run

### Deploying Specific AWS Module
1. Go to **Actions** tab
2. Select **Deploy AWS Infrastructure**
3. Click **Run workflow**
4. Choose module from dropdown
5. Click **Run workflow**

### Testing Infrastructure Changes
1. Create a branch: `git checkout -b feature/my-change`
2. Modify Terraform files in `deployments/aws/`
3. Push and create PR
4. `terraform-plan-aws.yml` will automatically run
5. Review the plan in PR comments
6. Merge to main to deploy (if using auto-deploy)

## 🔒 Security Best Practices

### ✅ Do's
- Use OIDC for all cloud authentication
- Restrict workflows to specific branches when needed
- Use read-only roles for checks and reports
- Use deployment roles only for actual deployments
- Review Terraform plans before merging PRs

### ❌ Don'ts
- Never commit AWS access keys or Azure secrets
- Don't use admin roles unless absolutely necessary
- Don't skip the PR review process
- Don't disable security scanning

## 📊 Workflow Permissions

| Workflow | Permissions | AWS Role | Why? |
|----------|-------------|----------|------|
| aws-cost-check.yml | `id-token: write`<br>`contents: read` | readonly | Cost data is read-only |
| terraform-plan-aws.yml | `id-token: write`<br>`contents: read`<br>`pull-requests: write` | readonly | Plan doesn't modify resources; needs PR comment access |
| deploy-aws.yml | `id-token: write`<br>`contents: read` | deploy | Needs write access to create/modify resources |
| aws-compliance-check.yml | `id-token: write`<br>`contents: read` | readonly | Compliance status is read-only |
| tfsec.yml | `contents: read` | None | Just scans local code |

## 🆘 Troubleshooting

### "Not authorized to perform sts:AssumeRoleWithWebIdentity"
- Check that OIDC provider is deployed: `deployments/aws/iam/github-oidc/`
- Verify role ARN in workflow matches Terraform output
- Ensure workflow has `permissions: id-token: write`

### Terraform Plan Fails
- Check backend configuration points to correct S3 bucket
- Verify AWS credentials are working
- Ensure Terraform state exists for the module

### Workflow Doesn't Trigger
- Check file paths in `on.paths` match your changes
- Verify branch restrictions
- Check if workflow is disabled in repo settings

## 🔗 Related Documentation

- **AWS OIDC Setup**: `deployments/aws/iam/github-oidc/README.md`
- **Terraform State**: `deployments/aws/terraform-state-bootstrap/README.md`
- **Encryption Baseline**: `deployments/aws/policies/encryption-baseline/README.md`
- **Cost Management**: `deployments/aws/budgets/cost-management/README.md`

## 📞 Support

For issues with:
- **Azure workflows**: Check Azure app registration and OIDC setup
- **AWS workflows**: Check AWS IAM OIDC provider and roles
- **Terraform**: Review module-specific README files
- **GitHub Actions**: Check Actions tab for detailed logs
