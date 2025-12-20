# AWS Required Tags Module

Provides governance-enforced tag baseline for all AWS resources. Use this module to ensure your resources meet tagging compliance requirements.

## 🏷️ Required Tags

All AWS resources must have these tags:

- **environment** - Environment name (dev, staging, production)
- **team** - Team ID from approved-tags.yaml
- **costcenter** - Cost center code for billing allocation

## 📋 Usage

### Basic Usage

```hcl
# In your Terraform configuration
module "required_tags" {
  source = "../../modules/required-tags"

  environment = "production"
  team        = "platform-engineering"
  costcenter  = "eng-0001"
}

# Apply to your resources using merge()
resource "aws_s3_bucket" "example" {
  bucket = "my-application-bucket"

  tags = merge(
    module.required_tags.baseline_tags,
    {
      # Add your custom tags here
      application = "web-app"
      data_classification = "internal"
    }
  )
}
```

### AWS Provider Default Tags (Recommended)

For automatic tagging of all resources:

```hcl
# In your root module
module "required_tags" {
  source = "./modules/required-tags"

  environment = var.environment
  team        = var.team
  costcenter  = var.costcenter
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = module.required_tags.baseline_tags
  }
}

# Now all resources automatically get governance tags!
resource "aws_s3_bucket" "example" {
  bucket = "my-bucket"
  
  # Only add resource-specific tags
  tags = {
    application = "web-app"
  }
}
```

### Multiple Environments

```hcl
# Development
module "dev_tags" {
  source = "../../modules/required-tags"

  environment = "dev"
  team        = "platform-engineering"
  costcenter  = "ENG-0001"
}

# Production
module "prod_tags" {
  source = "../../modules/required-tags"

  environment = "production"
  team        = "platform-engineering"
  costcenter  = "eng-0001"
}
```

## 🎯 Tag Validation

This module includes basic validation, but full compliance is checked by:
- Daily AWS Config evaluation (2am UTC)
- Team validation against `approved-tags.yaml`
- Allowed value validation (environment, costcenter codes)

## 📚 Allowed Values

See `deployments/aws/policies/tagging-enforcement/approved-tags.yaml` for:
- Valid environment values
- Registered team IDs
- Valid cost center codes

## ⚠️ Important Notes

### Preventing Tag Drift

When using tag enforcement automation, **always use merge()** to prevent Terraform drift:

```hcl
# ✅ CORRECT - Prevents drift
tags = merge(
  module.required_tags.baseline_tags,
  { custom = "value" }
)

# ❌ WRONG - Will cause drift if automation adds tags
tags = {
  custom = "value"
  # Missing required tags - automation will add them
  # Next terraform plan will try to remove them
  # Infinite loop!
}
```

### Grace Period

New resources have a **14-day grace period** before compliance alerts are sent. Use this time to:
- Verify tags are correct
- Add any missing tags
- Update YAML if new team/costcenter needed

### Unknown Teams

If you use a team ID not in `approved-tags.yaml`:
- Resource is flagged as non-compliant
- Alert sent to compliance@kuduworks.net only
- Add your team to YAML via PR (requires compliance approval)

## 🔄 Updating Allowed Values

To add new teams or cost centers:

1. Edit `deployments/aws/policies/tagging-enforcement/approved-tags.yaml`
2. Submit PR (requires approval from CODEOWNERS)
3. After merge, `terraform apply` in tagging-enforcement to sync to S3
4. Values available for use immediately

## 📊 Compliance Monitoring

Non-compliant resources trigger daily emails (2am UTC):
- **Compliance team** - All non-compliant resources
- **Resource team** - Only their team's non-compliant resources

Email grouped by:
1. **Missing tags** (highest severity)
2. **Invalid tag values** (medium severity)
3. **Resource type** (for organization)

## 🛠️ Troubleshooting

### "Team not found in YAML"
Add your team to approved-tags.yaml and submit PR for approval.

### "Environment must be one of: dev, staging, production"
Use exact values from validation. Check approved-tags.yaml for allowed list.

### "Tag drift detected"
Ensure you're using merge() pattern. Never manually set tags that conflict with governance tags.

## Examples

See `examples/` directory for complete working examples:
- Basic S3 bucket
- EC2 instance with custom tags
- Multi-environment setup
- Provider default_tags pattern
