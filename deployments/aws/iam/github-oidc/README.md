# GitHub Actions OIDC for AWS 🔐

This module sets up **OpenID Connect (OIDC) federation** between GitHub Actions and AWS, eliminating the need for long-lived AWS credentials stored in GitHub secrets.

## 🎯 What is OIDC and Why Use It?

### The Old Way (Don't Do This)
```yaml
# BAD: Long-lived credentials in GitHub secrets
- name: Configure AWS
  env:
    AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}         # ❌ Can be stolen
    AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }} # ❌ Never expires
```

**Problems:**
- Access keys never expire unless manually rotated
- If leaked, attacker has unlimited time to use them
- Hard to audit who's using what
- Need to store secrets in GitHub

### The New Way (OIDC - Much Better)
```yaml
# GOOD: Short-lived tokens via OIDC
- name: Configure AWS
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::YOUR-ACCOUNT-ID:role/github-actions-deploy  # ✅ No secrets!
    aws-region: eu-north-1
```

**Benefits:**
- ✅ **No secrets in GitHub** - Uses cryptographic tokens instead
- ✅ **Automatic expiration** - Tokens valid for 1 hour only
- ✅ **Better audit trail** - See exactly which repo/branch/run used credentials
- ✅ **Restricted access** - Can limit to specific repos, branches, or even PR events

## 🔍 How OIDC Works (The Magic Explained)

Here's the flow when your GitHub Action runs:

```
┌─────────────────┐                    ┌──────────────────┐                    ┌─────────────┐
│ GitHub Actions  │                    │  GitHub OIDC     │                    │     AWS     │
│   Workflow      │                    │   Provider       │                    │             │
└────────┬────────┘                    └────────┬─────────┘                    └──────┬──────┘
         │                                      │                                      │
         │ 1. Request OIDC token               │                                      │
         ├────────────────────────────────────>│                                      │
         │    (I'm from KuduWorks/fictional-   │                                      │
         │     octo-system, main branch)       │                                      │
         │                                      │                                      │
         │ 2. Return signed JWT token          │                                      │
         │<────────────────────────────────────┤                                      │
         │    {                                 │                                      │
         │      "sub": "repo:KuduWorks/...",   │                                      │
         │      "aud": "sts.amazonaws.com"     │                                      │
         │    }                                 │                                      │
         │                                      │                                      │
         │ 3. Request to assume IAM role        │                                      │
         │    with OIDC token                   │                                      │
         ├──────────────────────────────────────────────────────────────────────────>│
         │                                      │                                      │
         │                                      │  4. AWS validates token with GitHub  │
         │                                      │<─────────────────────────────────────┤
         │                                      │                                      │
         │                                      │  5. Confirms token is genuine        │
         │                                      ├─────────────────────────────────────>│
         │                                      │                                      │
         │ 6. Return temporary AWS credentials  │                                      │
         │    (valid for 1 hour)                │                                      │
         │<─────────────────────────────────────────────────────────────────────────┤
         │    AWS_ACCESS_KEY_ID=ASIATEMP...    │                                      │
         │    AWS_SECRET_ACCESS_KEY=...         │                                      │
         │    AWS_SESSION_TOKEN=...             │                                      │
         │                                      │                                      │
         │ 7. Use temporary credentials to      │                                      │
         │    deploy infrastructure             │                                      │
         ├──────────────────────────────────────────────────────────────────────────>│
         │                                      │                                      │
```

**Key Points:**
- GitHub generates a **signed JWT token** that proves the workflow's identity
- The token includes claims: repository name, branch, commit SHA, etc.
- AWS validates the token with GitHub's public keys
- AWS issues **temporary credentials** (like a 1-hour pass)
- When the hour expires, credentials stop working automatically

## 🏗️ What This Module Creates

This Terraform configuration creates:

1. **IAM OIDC Identity Provider** - Establishes trust between AWS and GitHub
2. **IAM Roles** (configurable):
   - **Read-Only Role** - Safe for PR checks, testing, cost analysis
   - **Deploy Role** - Can create/modify infrastructure (Terraform, CloudFormation)
   - **Admin Role** (optional) - Full access, only from `main` branch (use with caution)
3. **Trust Policies** - Restricts which repos/branches can assume each role
4. **IAM Policies** - Defines what each role can do in AWS

## 🆚 Comparison: Azure vs AWS OIDC

| Aspect | Azure App Registration | AWS OIDC |
|--------|----------------------|----------|
| Setup Complexity | More complex (app + service principal + secrets) | Simpler (just OIDC provider + roles) |
| Secrets Required | Client secret (can expire) | None! Pure OIDC |
| Trust Mechanism | Service principal login | IAM role assumption |
| Token Lifetime | Configurable (hours to years) | 1 hour (AWS STS default) |
| Granular Access | Via Azure RBAC | Via IAM policies + trust conditions |
| GitHub Action | `azure/login@v1` | `aws-actions/configure-aws-credentials@v4` |

**Both achieve the same goal:** Secure, temporary access without long-lived secrets.

## 📋 Prerequisites

Before deploying this module:

1. **AWS CLI configured** with admin-level permissions
   ```bash
   aws sts get-caller-identity  # Verify your AWS identity
   ```

2. **Terraform state bootstrap** completed
   - You should have the S3 bucket for state storage
   - Run from `deployments/aws/terraform-state-bootstrap/` if not done

3. **GitHub repository** with Actions enabled
   - This is already set up for `KuduWorks/fictional-octo-system`

4. **Your AWS Account ID**
   ```bash
   aws sts get-caller-identity --query Account --output text
   ```

## 🚀 Deployment Steps

### Step 1: Configure Variables

```bash
cd deployments/aws/iam/github-oidc/

# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit with your settings
nano terraform.tfvars  # or use your preferred editor
```

**Update `terraform.tfvars`:**
```hcl
github_org          = "KuduWorks"  # Your GitHub org or username
github_repositories = [
  "fictional-octo-system"  # Repos that can use these roles
]

create_readonly_role = true   # Safe for all workflows
create_deploy_role   = true   # For Terraform deployments
create_admin_role    = false  # Only enable if absolutely needed
```

### Step 2: Backend Configuration

The AWS account ID is already configured in `backend.tf`. No changes are needed unless you want to use a different account.

If you do need to update the account ID, you can find your AWS account ID with:

```bash
aws sts get-caller-identity --query Account --output text
```

### Step 3: Deploy

```bash
# Initialize Terraform
terraform init

# Review what will be created
terraform plan

# Create the OIDC provider and roles
terraform apply
```

**What gets created:**
- 1 OIDC provider (free)
- 2 IAM roles by default (free)
- IAM policies (free)
- **Cost: $0.00/month** 🎉

### Step 4: Get Role ARNs

After deployment, save the role ARNs (you'll need them in GitHub Actions):

```bash
terraform output deploy_role_arn
# Example output: arn:aws:iam::YOUR-ACCOUNT-ID:role/github-actions-deploy

terraform output readonly_role_arn
# Example output: arn:aws:iam::YOUR-ACCOUNT-ID:role/github-actions-readonly
```

> **📝 Note:** Replace `YOUR-ACCOUNT-ID` with your actual AWS account ID in the examples below. Get it with: `aws sts get-caller-identity --query Account --output text`

## 📝 Using in GitHub Actions

### Example 1: Read-Only Workflow (PR Checks)

```yaml
name: AWS Cost Check
on: [pull_request]

permissions:
  id-token: write   # Required for OIDC
  contents: read

jobs:
  cost-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::YOUR-ACCOUNT-ID:role/github-actions-readonly
          aws-region: eu-north-1
      
      - name: Check Current AWS Costs
        run: |
          aws ce get-cost-and-usage \
            --time-period Start=2024-11-01,End=2024-11-30 \
            --granularity MONTHLY \
            --metrics BlendedCost
```

### Example 2: Deployment Workflow (Main Branch)

```yaml
name: Deploy Infrastructure
on:
  push:
    branches: [main]

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::YOUR-ACCOUNT-ID:role/github-actions-deploy
          aws-region: eu-north-1
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
      
      - name: Deploy with Terraform
        run: |
          cd deployments/aws/policies/encryption-baseline
          terraform init
          terraform apply -auto-approve
```

### Example 3: Multi-Environment Deployment

```yaml
name: Deploy to Environment
on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy'
        required: true
        type: choice
        options: [dev, staging, prod]

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment }}
    steps:
      - uses: actions/checkout@v4
      
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::YOUR-ACCOUNT-ID:role/github-actions-deploy
          aws-region: eu-north-1
      
      - name: Deploy
        run: |
          echo "Deploying to ${{ github.event.inputs.environment }}"
          # Your deployment commands here
```

## 🔒 Security Best Practices

### 1. **Use Separate Roles for Different Purposes**

```hcl
# Read-only: PR checks, cost analysis, audits
create_readonly_role = true

# Deploy: Terraform, infrastructure changes
create_deploy_role = true

# Admin: Emergency only, main branch only
create_admin_role = false  # Keep disabled unless absolutely needed
```

### 2. **Restrict by Branch**

The admin role is automatically restricted to `main` branch:

```hcl
# In main.tf - admin role trust policy
"token.actions.githubusercontent.com:sub" = [
  "repo:KuduWorks/fictional-octo-system:ref:refs/heads/main"
]
```

### 3. **Restrict by Repository**

Only listed repos can assume roles:

```hcl
github_repositories = [
  "fictional-octo-system",
  "other-trusted-repo"  # Only add repos you control
]
```

### 4. **Monitor Role Usage**

Use CloudTrail to see when roles are assumed:

```bash
# See recent AssumeRoleWithWebIdentity events
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=AssumeRoleWithWebIdentity \
  --max-results 10
```

## 🔧 Troubleshooting

### Error: "Not authorized to perform sts:AssumeRoleWithWebIdentity"

**Problem:** GitHub Actions can't assume the IAM role

**Solutions:**

1. **Check the role ARN in your workflow**
   ```yaml
   role-to-assume: arn:aws:iam::YOUR-ACCOUNT-ID:role/github-actions-deploy
   # Replace YOUR-ACCOUNT-ID with your actual AWS account ID
   ```

2. **Verify permissions in workflow**
   ```yaml
   permissions:
     id-token: write   # This is required!
     contents: read
   ```

3. **Check repository is allowed**
   ```bash
   terraform output  # View configured repos
   ```

### Error: "OpenIDConnect provider not found"

**Problem:** OIDC provider doesn't exist or wrong ARN

**Solution:** Verify the provider exists:
```bash
aws iam list-open-id-connect-providers
terraform output oidc_provider_arn
```

### Error: "Access denied" when deploying resources

**Problem:** Role doesn't have sufficient permissions

**Solutions:**

1. **Use the correct role** - Deploy role for deployments, not read-only
2. **Check IAM policy** - Review permissions in `main.tf`
3. **Add custom permissions** if needed

### Credentials expire during long workflows

**Problem:** 1-hour token expires mid-deployment

**Solutions:**

1. **Break into smaller jobs** - Each job gets fresh credentials
2. **Use workflow concurrency** - Run parallel jobs
3. **Re-authenticate mid-workflow**

## 📊 What Each Role Can Do

### Read-Only Role
✅ List resources, view configs, read S3 objects  
✅ Get costs, view billing, check compliance  
✅ Run `terraform plan` (no changes)  
❌ Cannot create/modify/delete resources

**Use for:** PR checks, cost analysis, compliance audits

### Deploy Role
✅ Everything read-only role can do  
✅ Create/modify/delete: S3, EC2, VPC, IAM roles, Config, Budgets, SNS, KMS  
✅ Read/write Terraform state in S3  
✅ Lock state in DynamoDB  
❌ Limited IAM permissions (can't grant itself more access)

**Use for:** Terraform deployments, infrastructure changes

### Admin Role (if enabled)
✅ **Full AWS account access**  
⚠️ Only works from `main` branch  
⚠️ Use with extreme caution

**Use for:** Emergency access only

## 🔄 Migrating from AWS Access Keys

If you're currently using access keys in GitHub secrets:

### Step 1: Deploy this module
```bash
terraform apply
```

### Step 2: Update workflows to use OIDC
```yaml
# Old way - DELETE THIS
- name: Configure AWS
  env:
    AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
    AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}

# New way - ADD THIS
- name: Configure AWS
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
    aws-region: eu-north-1
```

### Step 3: Test the new workflow

### Step 4: Delete access keys from GitHub secrets

## 💰 Cost

**This module is completely free!**

- IAM OIDC providers: Free
- IAM roles: Free
- IAM policies: Free
- Role assumption API calls: Free

## 📚 Additional Resources

- [AWS OIDC Documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
- [GitHub Actions OIDC Guide](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [aws-actions/configure-aws-credentials](https://github.com/aws-actions/configure-aws-credentials)

## 🔗 Related Modules

- **Azure App Registration**: `deployments/azure/app-registration/` - Similar concept for Azure
- **Terraform State Bootstrap**: `deployments/aws/terraform-state-bootstrap/` - Required before this
- **Encryption Baseline**: `deployments/aws/policies/encryption-baseline/` - Deploy after setting up OIDC

---

**Pro Tip:** After deploying this, update your `.github/workflows/` to use OIDC authentication. You'll never have to rotate AWS access keys again! 🎉
