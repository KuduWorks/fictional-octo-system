# AWS Tag Enforcement 🏷️

> *Team-based tag governance with merge() pattern and daily compliance digests*

Automated AWS resource tagging enforcement using AWS Config, EventBridge, and Lambda. This solution monitors your AWS resources for required tags (`environment`, `team`, `costcenter`), validates tag values against allowed lists, and sends daily digest emails to compliance team and resource owners.

## 🎯 What It Does

- **Monitors** AWS resources daily for required tags (environment, team, costcenter)
- **Validates** tag values against YAML-defined allowed lists  
- **Filters** resources with 14-day grace period for new deployments
- **Alerts** compliance team (all issues) + individual teams (their issues only)
- **Enforces** manual remediation via Terraform using merge() pattern
- **Prevents** tag drift by requiring developers use shared tagging module

## 🏗️ Architecture

```
Daily @ 2am UTC:
  EventBridge Scheduled Rule
      ↓
  Lambda Function
      ↓ (queries)
  AWS Config (non-compliant resources)
      ↓ (loads)
  approved-tags.yaml (from S3)
      ↓ (validates & filters)
  - 14-day grace period
  - Tag value validation
  - Severity grouping
      ↓ (sends)
  SNS → Emails
  ├── compliance@kuduworks.net (all issues)
  └── team-specific@kuduworks.net (their issues only)
```

## 🚀 Quick Start

### Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- AWS account with permissions for:
  - AWS Config
  - Lambda
  - EventBridge
  - S3
  - SNS
  - IAM

### Step 1: Review Team Configuration

Edit `approved-tags.yaml` to add your teams and allowed tag values:

```yaml
teams:
  platform-engineering:
    email: platform-team@kuduworks.net
    description: Platform and infrastructure team
  
  your-team:
    email: your-team@kuduworks.net
    description: Your team description

allowed_values:
  environment:
    - dev
    - staging
    - production
  
  costcenter:
    - eng-0001
    - YOUR-COSTCENTER
```

**Important**: Changes to `approved-tags.yaml` require PR approval from compliance team (see `.github/CODEOWNERS`).

### Step 2: Configure Backend

```bash
cp backend.tf.example backend.tf
# Edit backend.tf with your S3 bucket and DynamoDB table
```

### Step 3: Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your settings
```

**Key variables to update:**
- `compliance_email` - Where all compliance reports go
- `tags` - Must include valid environment, team, costcenter values
- `dry_run_mode` - Start with `true` (logs emails without sending)

### Step 4: Deploy

```bash
terraform init
terraform plan
terraform apply
```

This creates:
- AWS Config rule for tag validation
- S3 bucket with approved-tags.yaml
- Lambda function for daily checks
- EventBridge rule (2am UTC daily trigger)
- SNS topic for notifications
- CloudWatch alarms

### Step 5: Verify SNS Subscription

Check your email for SNS subscription confirmation and click the link.

### Step 6: Use Shared Tagging Module in Your Code

In your Terraform projects:

```hcl
# Import the required tags module
module "required_tags" {
  source = "../../modules/required-tags"

  environment = "production"
  team        = "platform-engineering"  # Must exist in approved-tags.yaml
  costcenter  = "eng-0001"               # Must exist in approved-tags.yaml
  region = "us-east-1"

  default_tags {
    tags = module.required_tags.baseline_tags
  }
}

# Now all resources automatically get governance tags
resource "aws_s3_bucket" "example" {
  bucket = "my-bucket"
  
  # Only add resource-specific tags
  tags = {
    application = "web-app"
  }
}

# Option B: Manual merge per resource
resource "aws_ec2_instance" "app" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"

  tags = merge(
    module.required_tags.baseline_tags,
    {
      name        = "app-server"
      application = "api"
    }
  )
}
```

### Step 7: Test and Enable

1. Deploy with `dry_run_mode = true` initially
2. Check CloudWatch Logs for Lambda output
3. Verify email format in logs
4. Set `dry_run_mode = false` when ready
5. Wait for 2am UTC for first real digest!

## 📋 Configuration Options

### Required Tags (Mandatory)

Three tags must be present on all taggable resources:

```hcl
required_tags = [
  "environment",  # Allowed: dev, staging, production
  "team",         # Must exist in approved-tags.yaml
  "costcenter"    # Must be in allowed list in approved-tags.yaml
]
```

**Important**: Tag keys are **lowercase** (different from original uppercase version).

### Team Configuration (approved-tags.yaml)

The YAML file defines team mappings and validation rules:

```yaml
teams:
  platform-engineering:
    email: platform-team@kuduworks.net
    description: Platform and infrastructure team

allowed_values:
  environment:
    - dev
    - staging
    - production
  
  costcenter:
    - eng-0001
    - eng-0002
    - ops-0001

compliance:
  compliance_email: compliance@kuduworks.net
  grace_period_days: 14
  digest_time: "02:00"
```

**Updating YAML**:
1. Edit `approved-tags.yaml`
2. Submit PR (requires compliance team approval via CODEOWNERS)
3. After merge, run `terraform apply` to sync to S3
4. Changes take effect on next daily run (2am UTC)

### Resource Types

AWS Config automatically filters to taggable resources. Configure which types to check:

```hcl
resource_types_to_check = [
  "AWS::EC2::Instance",
  "AWS::S3::Bucket",
  "AWS::RDS::DBInstance",
  "AWS::Lambda::Function",
  # Add more as needed
]
```

See [AWS Config Supported Resources](https://docs.aws.amazon.com/config/latest/developerguide/resource-config-reference.html) for full list.

### Operating Modes

| Mode | `dry_run_mode` | Behavior |
|------|---------------|----------|
| **Testing** | `true` | Logs email content to CloudWatch, no emails sent |
| **Production** | `false` | Sends real emails to compliance and teams |

**No auto-tagging mode** - manual remediation via Terraform is required.

### Grace Period

New resources are excluded from compliance checks for 14 days (configurable):

```hcl
grace_period_days = 14  # Default
```

This gives teams time to:
- Deploy infrastructure
- Test functionality
- Add proper tags via Terraform
- Avoid alert fatigue during active development

## 📊 Monitoring & Notifications

### Daily Digest Schedule

- **When**: Every day at 2am UTC
- **Who**: Compliance team (all issues) + individual teams (their issues only)
- **What**: Only sent when non-compliant resources exist (no spam on compliant days!)

### Email Format

**Compliance Team Email** (compliance@kuduworks.net):
- Full report of all non-compliant resources
- Grouped by severity (missing tags > invalid values)
- Then grouped by resource type
- Includes team ownership info

**Team-Specific Emails** (from approved-tags.yaml):
- Filtered to show only that team's resources
- Includes remediation instructions
- Links to shared tagging module documentation

### Email Severity Levels

1. **🚨 Missing Tags** (Highest) - Required tags completely absent
2. **⚠️  Invalid Values** (Medium) - Tags present but values not in allowed list
3. **Unknown Teams** (Compliance Only) - Team tag not in YAML

### CloudWatch Alarms

Two alarms monitor the system (if enabled):

1. **Non-Compliant Resources** - Triggers when > threshold resources lack tags
2. **Lambda Errors** - Triggers when daily check fails

### CloudWatch Logs

Lambda execution logs:
```bash
# View real-time logs
aws logs tail /aws/lambda/kuduworks-tag-enforcer-tag-remediation --follow

# Search for specific team
aws logs filter-pattern /aws/lambda/kuduworks-tag-enforcer-tag-remediation --filter-pattern "platform-engineering"
```

### AWS Config Dashboard

Monitor compliance status:
1. AWS Console → Config → Rules
2. Find `required-tags-check`
3. View compliant/non-compliant resources
4. Drill down by resource type

## 🛠️ Developer Workflow

### Adding a New Team

1. **Edit approved-tags.yaml**:
   ```yaml
   teams:
     my-new-team:
       email: my-team@kuduworks.net
       description: My awesome team
   ```

2. **Submit PR** - Requires approval from compliance team (CODEOWNERS)

3. **After merge, sync to S3**:
   ```bash
   cd deployments/aws/policies/tagging-enforcement
   terraform apply -target=aws_s3_object.team_emails
   ```

4. **Use in your Terraform**:
   ```hcl
   module "required_tags" {
     source = "../../modules/required-tags"
     
     environment = "production"
     team        = "my-new-team"  # Now valid!
     costcenter  = "eng-0001"
   }
   ```

### Adding a New Cost Center

1. **Edit approved-tags.yaml**:
   ```yaml
   allowed_values:
     costcenter:
       - eng-0001
       - MY-NEW-CC  # Add here
   ```

2. **Follow same PR approval process**

3. **Sync to S3 after merge**

### Preventing Tag Drift

**✅ CORRECT** - Using merge():
```hcl
module "required_tags" {
  source = "../../modules/required-tags"
  
  environment = "production"
  team        = "platform-engineering"
  costcenter  = "eng-0001"
}

resource "aws_s3_bucket" "app" {
  bucket = "my-app-bucket"
  
  tags = merge(
    module.required_tags.baseline_tags,
    {
      application = "web-app"
      data_class  = "internal"
    }
  )
}
```

**❌ WRONG** - Will cause drift:
```hcl
resource "aws_s3_bucket" "app" {
  bucket = "my-app-bucket"
  
  tags = {
    application = "web-app"
    # Missing governance tags!
    # If auto-tagging were enabled, would cause drift loop
  }
}
```

**🌟 BEST** - Provider default_tags:
```hcl
provider "aws" {
  region = "us-east-1"
  
  default_tags {
    tags = module.required_tags.baseline_tags
  }
}

# Now ALL resources get governance tags automatically!
resource "aws_s3_bucket" "app" {
  bucket = "my-app-bucket"
  
  # Only add resource-specific tags
  tags = {
    application = "web-app"
  }
}
```

## 🔧 Troubleshooting

### "No compliance digest received"

**Check**:
1. Lambda execution in CloudWatch Logs
2. Verify 2am UTC has passed
3. Check if any resources are non-compliant
4. Verify dry_run_mode setting

**Solution**:
```bash
# Manually invoke Lambda to test
aws lambda invoke \
  --function-name kuduworks-tag-enforcer-tag-remediation \
  --payload '{}' \
  response.json
```

### "Team not found" errors in logs

**Cause**: Resource has team tag value not in approved-tags.yaml

**Solution**:
1. Add team to YAML via PR
2. Or update resource tag to valid team ID

### "Invalid environment value"

**Cause**: environment tag is not dev/staging/production

**Solution**: Update resource tags:
```hcl
environment = "production"  # Not "prod" or "prd"
```

### Emails not being sent (dry_run = false)

**Check**:
1. SNS topic subscription confirmed
2. Lambda IAM permissions for SNS publish
3. Check spam folder
4. Verify email addresses in approved-tags.yaml

### Grace period not working

**Symptoms**: New resources immediately flagged

**Check**:
1. Verify `grace_period_days` variable set
2. Check Lambda environment variables
3. Ensure resource has creation timestamp in Config

## 💰 Cost Estimate

Approximate monthly costs (us-east-1, 1000 resources):

| Service | Usage | Cost |
|---------|-------|------|
| AWS Config | 30 evaluations/day × 30 days | ~$18 |
| Config Rules | 1 active rule | $2 |
| Lambda | 30 invocations/month @ 60s each | < $0.01 |
| S3 (Config bucket) | 5GB storage | ~$0.12 |
| S3 (Team config) | 1KB storage | < $0.01 |
| SNS | 60 notifications/month | < $0.01 |
| CloudWatch Logs | 100MB/month | ~$0.50 |
| **Total** | | **~$20.64/month** |

*Scales with number of resources and evaluation frequency*

## 🔐 Security Considerations

- **Least Privilege IAM**: Lambda has read-only Config access + S3 read + SNS publish only
- **Encryption at Rest**: All S3 buckets use AES-256 encryption
- **Encryption in Transit**: HTTPS for all AWS API calls
- **Public Access Blocked**: S3 buckets have public access blocks enabled
- **Versioning**: S3 buckets versioned for auditability
- **Audit Trail**: All actions logged in CloudWatch Logs
- **YAML Access Control**: approved-tags.yaml changes require PR approval (CODEOWNERS)
- **No Secret Tags**: Does not handle or store sensitive data

## 📚 References

- [AWS Config Rules Documentation](https://docs.aws.amazon.com/config/latest/developerguide/evaluate-config.html)
- [AWS Tagging Best Practices](https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html)
- [EventBridge Scheduled Rules](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-create-rule-schedule.html)
- [Required Tags Module](../modules/required-tags/README.md)

## 🤝 Contributing

Found a bug? Want to add support for more resource types? PRs welcome!

See [CONTRIBUTING.md](../../../CONTRIBUTING.md) for guidelines.

## 📄 License

See [LICENSE](../../../LICENSE) in the root of this repository.

---

## 🎯 Key Takeaways

1. **No Auto-Tagging** - Teams must fix tags in their Terraform code (prevents drift)
2. **Use merge()** - Always merge governance tags with custom tags
3. **14-Day Grace Period** - New resources get time before alerts
4. **Daily Digests Only** - No real-time spam, predictable at 2am UTC
5. **Team Isolation** - Teams only see their issues, compliance sees all
6. **YAML-Driven** - Central configuration with approval workflow

## 💡 Pro Tips

- Start with `dry_run_mode = true` to test email format
- Use provider `default_tags` for effortless compliance
- Add new teams/costcenters to YAML before deploying resources
- Monitor CloudWatch Logs daily for first week
- Document your team's costcenter in team wiki
- Set calendar reminder for 2:30am UTC to check digests 📅

## 🆘 Support

**Issues? Try these in order:**

1. Check this README thoroughly
2. Review CloudWatch Logs for Lambda
3. Verify AWS Config rule status
4. Check approved-tags.yaml is synced to S3
5. Confirm SNS subscriptions
6. Open issue in repo with logs attached

**Questions about governance policy?** Contact: compliance@kuduworks.net

**Technical implementation help?** Platform team: platform-team@kuduworks.net

---

*"Taggers gonna tag, tag, tag, tag, tag..." 🎵 - Taylor Swift, probably*
