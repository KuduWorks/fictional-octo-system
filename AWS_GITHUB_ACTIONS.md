# AWS GitHub Actions Quick Reference

This file provides quick copy-paste examples for using AWS OIDC in GitHub Actions.

## 🎯 Role ARNs

```yaml
# Read-Only Role (for checks, reports, plans)
role-to-assume: arn:aws:iam::494367313227:role/github-actions-readonly

# Deploy Role (for infrastructure changes)
role-to-assume: arn:aws:iam::494367313227:role/github-actions-deploy
```

## 📝 Basic Workflow Template

```yaml
name: My AWS Workflow
on: [push]

permissions:
  id-token: write  # Required for OIDC
  contents: read

jobs:
  my-job:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::494367313227:role/github-actions-readonly
          aws-region: eu-north-1
      
      - name: Run AWS Commands
        run: |
          aws sts get-caller-identity
          aws s3 ls
```

## 🔐 Read-Only Role Examples

### Check AWS Costs
```yaml
- name: Get Current Costs
  run: |
    aws ce get-cost-and-usage \
      --time-period Start=2024-11-01,End=2024-11-30 \
      --granularity MONTHLY \
      --metrics BlendedCost
```

### List Resources
```yaml
- name: List S3 Buckets
  run: aws s3 ls

- name: List EC2 Instances
  run: |
    aws ec2 describe-instances \
      --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' \
      --output table
```

### Terraform Plan
```yaml
- name: Terraform Plan
  run: |
    cd deployments/aws/my-module
    terraform init
    terraform plan
```

## 🚀 Deploy Role Examples

### Terraform Apply
```yaml
- name: Configure AWS Credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::494367313227:role/github-actions-deploy
    aws-region: eu-north-1

- name: Deploy Infrastructure
  run: |
    cd deployments/aws/policies/encryption-baseline
    terraform init
    terraform apply -auto-approve
```

### Create S3 Bucket
```yaml
- name: Create S3 Bucket
  run: |
    aws s3api create-bucket \
      --bucket my-new-bucket-$(date +%s) \
      --region eu-north-1 \
      --create-bucket-configuration LocationConstraint=eu-north-1
```

## 🎭 Multi-Region Example

```yaml
strategy:
  matrix:
    region: [eu-north-1, us-east-1, ap-southeast-1]

steps:
  - name: Configure AWS Credentials
    uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: arn:aws:iam::494367313227:role/github-actions-deploy
      aws-region: ${{ matrix.region }}
  
  - name: Deploy to Region
    run: echo "Deploying to ${{ matrix.region }}"
```

## 🔄 Re-authenticate Mid-Workflow

For long-running workflows (credentials expire after 1 hour):

```yaml
steps:
  - name: Initial Authentication
    uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: arn:aws:iam::494367313227:role/github-actions-deploy
      aws-region: eu-north-1
  
  - name: Long Running Task Part 1
    run: terraform apply -auto-approve
  
  # Re-authenticate after 45 minutes
  - name: Re-authenticate
    uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: arn:aws:iam::494367313227:role/github-actions-deploy
      aws-region: eu-north-1
  
  - name: Long Running Task Part 2
    run: terraform apply -auto-approve
```

## 🎯 Branch-Specific Roles

```yaml
- name: Configure AWS Credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ github.ref == 'refs/heads/main' && 'arn:aws:iam::494367313227:role/github-actions-deploy' || 'arn:aws:iam::494367313227:role/github-actions-readonly' }}
    aws-region: eu-north-1
```

## 📦 With Docker

```yaml
- name: Login to ECR
  run: |
    aws ecr get-login-password --region eu-north-1 | \
      docker login --username AWS --password-stdin 494367313227.dkr.ecr.eu-north-1.amazonaws.com

- name: Build and Push
  run: |
    docker build -t my-app .
    docker tag my-app:latest 494367313227.dkr.ecr.eu-north-1.amazonaws.com/my-app:latest
    docker push 494367313227.dkr.ecr.eu-north-1.amazonaws.com/my-app:latest
```

## 🐛 Debugging

### Verify Credentials
```yaml
- name: Debug AWS Identity
  run: |
    echo "Current identity:"
    aws sts get-caller-identity
    
    echo "Session duration:"
    aws sts get-session-token --duration-seconds 900
```

### Check Permissions
```yaml
- name: Test Permissions
  run: |
    echo "Can I list S3 buckets?"
    aws s3 ls && echo "✅ Yes" || echo "❌ No"
    
    echo "Can I create buckets?"
    aws s3api create-bucket --bucket test-$(date +%s) --region eu-north-1 && echo "✅ Yes" || echo "❌ No"
```

## 📚 More Information

- Full documentation: `deployments/aws/iam/github-oidc/README.md`
- All workflows: `.github/workflows/README.md`
- AWS Account ID: `494367313227`
- Default Region: `eu-north-1` (Stockholm)
