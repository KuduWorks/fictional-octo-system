# AWS Quick Start Guide

This guide will help you deploy your first AWS infrastructure module to mirror your Azure setup.

## Prerequisites

1. **AWS Account**: Create one at https://aws.amazon.com
2. **AWS CLI**: Install and configure
   ```bash
   # Install AWS CLI
   # Windows: Download from https://aws.amazon.com/cli/
   # macOS: brew install awscli
   # Linux: apt-get install awscli
   
   # Configure credentials
   aws configure
   # Enter: Access Key ID, Secret Access Key, Region (us-east-1), Output format (json)
   ```

3. **Terraform**: Already installed (you're using it for Azure)

## Step 1: Test Your AWS Credentials

```bash
# Verify AWS CLI is configured
aws sts get-caller-identity

# Should return your account ID and ARN
```

## Step 2: Deploy Encryption Baseline (Mirrors Azure ISO 27001 Crypto)

This is the AWS equivalent of `deployments/azure/policies/iso27001-crypto/`

```bash
cd deployments/aws/policies/encryption-baseline/

# Copy example variables
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars to set your preferences
# Change aws_region if needed (default: us-east-1)

# Initialize Terraform
terraform init

# Check that your code is structurally correct
terrafrom validate

# Preview what will be created
terraform plan

# Apply the configuration
terraform apply
```

### What Gets Created

- **AWS Config Recorder**: Continuously evaluates resource compliance
- **Config Rules**: 6 encryption-focused compliance rules
  - S3 bucket encryption
  - EBS volume encryption
  - RDS encryption
  - S3 HTTPS enforcement
  - DynamoDB KMS encryption
  - CloudTrail encryption
- **S3 Bucket**: Stores AWS Config compliance data
- **IAM Role**: Allows Config to access resources

### Cost Estimate

- AWS Config: ~$2.00/month per rule = ~$12/month for 6 rules
- S3 Storage: ~$0.23/month for compliance data
- **Total: ~$12-15/month**

## Step 3: View Compliance Dashboard

After applying, visit the AWS Config console:

```bash
# The URL will be in the Terraform output
terraform output compliance_dashboard_url
```

Or go to: https://console.aws.amazon.com/config/home?region=us-east-1#/dashboard

## Step 4: Test Compliance Rules

Create a non-compliant resource to see Config in action:

```bash
# Create an unencrypted S3 bucket (will be flagged as non-compliant)
aws s3api create-bucket --bucket test-unencrypted-bucket-$(date +%s) --region us-east-1

# Wait ~10 minutes, then check Config dashboard
# You'll see the bucket flagged as non-compliant
```

## Azure vs AWS Comparison

| What | Azure Location | AWS Location |
|------|---------------|--------------|
| Encryption Policies | `deployments/azure/policies/iso27001-crypto/` | `deployments/aws/policies/encryption-baseline/` |
| Policy Dashboard | Azure Policy portal | AWS Config console |
| Compliance Data | Azure Policy compliance | AWS Config S3 bucket |
| Enforcement | Azure Policy (deny/audit) | AWS Config (detect) + SCPs (prevent) |

## Next Steps

Once encryption baseline is working:

1. **Add Region Control**: Mirror your Azure region-control policies
2. **Set Up GitHub OIDC**: Replace AWS access keys in GitHub Actions
3. **Create KMS Keys**: Mirror your Key Vault setup
4. **Deploy VPC**: Set up networking like your Azure vnet

## Troubleshooting

### "AWS Config already enabled"
If you get an error that Config is already enabled, you can either:
- Import existing Config recorder: `terraform import aws_config_configuration_recorder.main default`
- Use a different recorder name in `terraform.tfvars`

### "Access Denied"
Make sure your AWS IAM user/role has these permissions:
- `config:*`
- `s3:*`
- `iam:CreateRole`, `iam:PutRolePolicy`

### "Region not enabled"
Some regions need to be manually enabled in AWS Console → Account → AWS Regions

## Cleanup

To destroy all resources (stop AWS charges):

```bash
cd deployments/aws/policies/encryption-baseline/
terraform destroy
```

## Getting Help

- Check module README: `deployments/aws/policies/encryption-baseline/README.md`
- AWS Config docs: https://docs.aws.amazon.com/config/
- Compare with Azure setup: `deployments/azure/policies/iso27001-crypto/`
