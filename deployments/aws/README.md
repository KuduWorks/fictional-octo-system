# AWS Infrastructure Deployment 🚀

This directory contains Terraform configurations for AWS infrastructure that mirrors the Azure setup in `deployments/azure/`.

*Because one cloud is never enough, and your infrastructure should be as geographically distributed as your vacation photos!* ✈️

## Structure

*A well-organized chaos of Terraform modules:*

- **budget-monitoring/** - Cost control and billing alerts 💰
  - Two-tier budget tracking ($100 org, $90 member) with SNS email notifications
  
- **policies/** - The "thou shalt not" section 📜
  - `encryption-baseline/` - ✅ ACTIVE SCPs: S3 public access blocking + encryption enforcement (mirrors Azure ISO 27001 crypto)
  - `region-control/` - ✅ ACTIVE SCPs: Stockholm-only deployment enforcement (mirrors Azure region restrictions)
  - `resource-tagging/` - 📋 Planned: Tag it or regret it later
  
- **iam/** - Identity and Access Management (or "who can break what")
  - `github-oidc/` - No more secrets in GitHub! (Math-based auth FTW)
  - `service-roles/` - Roles for services to talk to other services
  
- **kms/** - Key Management Service (the key to the kingdom) 🔑
  - `key-management/` - Where encryption keys live their best life
  
- **secrets/** - Secrets Manager (not to be confused with KMS... or is it?)
  - `secret-rotation/` - Because passwords that never change are so 2010
  
- **compute/** - The actual work-doing machines
  - `ssm-automation/` - Robots managing your servers (what could go wrong?)
  
- **networking/** - How computers talk to each other
  - `vpc-baseline/` - Your own private internet (almost)

- **finops-lambda/** - Serverless cost optimization and reporting functions (because spreadsheets are for mortals)

## Prerequisites

1. **AWS CLI** installed and configured *(Amazon's way of letting you break things from the command line)*
2. **Terraform** >= 1.0 *(The "I can automate that" tool)*
3. **AWS credentials** configured via `aws configure` *(More secrets to remember - at least these ones live in `~/.aws/`)*
4. **Coffee** ☕ *(Not technically required, but highly recommended)*

## Getting Started

Each subdirectory contains its own Terraform configuration. Navigate to the specific module and run the magic incantation:

```bash
terraform init    # "Let me download half the internet..."
terraform plan    # "Here's what I'm about to do. Look scary enough?"
terraform apply   # "YOLO! Creating resources..." 🎲
```

**Pro tip**: Always run `terraform plan` first. It's like checking the price before adding to cart. 💸

**First time?** Start here: [`terraform-state-bootstrap/`](terraform-state-bootstrap/) - Because even your infrastructure needs a home.

## Azure vs AWS Service Mapping

*The "this is like that, but different" translation guide:*

| Azure Service | AWS Equivalent | Translation Notes |
|--------------|----------------|-------------------|
| Cost Management + Budgets | AWS Budgets | Azure: Built-in. AWS: Also built-in. Both send scary emails! 💸 |
| Azure Policy | AWS Config Rules + SCPs | Azure: One policy. AWS: SCPs prevent + Config detects. ✅ BOTH ACTIVE |
| App Registration | IAM Roles + OIDC Provider | AWS: "Why use secrets when you can use math?" 🔐 |
| Key Vault | KMS + Secrets Manager | AWS split this into two services (naturally) |
| VM Automation | Systems Manager Automation | Both automate VMs. AWS version has more syllables. |
| Management Groups | AWS Organizations | Same concept, different name. Classic cloud move. |
| Resource Groups | Tags + Resource Groups | Azure groups things logically. AWS says "¿por qué no los dos?" |

## Active Enforcement

**🛡️ Service Control Policies (SCPs) Now Active:**
- ✅ **S3 Public Access Blocking** - No public buckets allowed (hard block at API level)
- ✅ **Region Restriction** - Stockholm (eu-north-1) only for resource creation
- ✅ **Account-Level Protection** - Public access blocks enforced at account level
- 📊 **AWS Config Monitoring** - Continuous compliance detection (9 rules active)

**⏳ Deployment Note**: SCPs take 5-15 minutes to propagate globally after initial deployment.

### ⚠️ Important: Management Account Limitation

**SCPs do NOT apply to the management account.** This is an AWS design limitation to prevent accidental lockout.

- **Management Account** (<YOUR-MGMT-ACCOUNT-ID>): Bypasses all SCPs
- **Member Accounts** (e.g., <YOUR-MEMBER-ACCOUNT-ID>): SCPs fully enforced

**For Testing**: Use [cross-account-role](iam/cross-account-role/) to properly test SCPs from a member account.

## Security Compliance Alerting

**📧 EventBridge + SNS Integration for Config Compliance Monitoring**

### What is EventBridge?

Amazon EventBridge is AWS's event routing service - think of it as a central switchboard for events happening across your AWS infrastructure. When AWS services emit events (like "Config detected non-compliant resource"), EventBridge can listen for specific patterns and route them to targets like SNS, Lambda, or SQS.

**The Problem**: AWS Config rules can detect compliance violations (unencrypted RDS, public S3 buckets, etc.), but they don't send notifications natively. You'd have to manually check the Config dashboard to see issues.

**The Solution**: EventBridge bridges this gap by:
1. Listening for Config compliance state changes
2. Filtering for `NON_COMPLIANT` events
3. Routing alerts to SNS → Email notifications

**Event Flow**:
```
AWS Config Rule detects violation
    ↓
Emits event: "Config Rules Compliance Change"
    ↓
EventBridge matches: complianceType = "NON_COMPLIANT"
    ↓
Routes to SNS topic → <email address for security alerts>
    ↓
Email alert sent automatically
```

### SNS Email Subscription Confirmation

When you first deploy the security alerts infrastructure, you'll receive a confirmation email:

1. **Check your inbox** at the configured security email address
2. **Click "Confirm subscription"** in the AWS SNS email
3. **Alerts will start flowing** once confirmed

**Note**: Until confirmed, EventBridge will attempt delivery but emails won't be sent. The subscription remains in "PendingConfirmation" state.

### RDS SSL/TLS Enforcement

The `rds-require-ssl-connection` Config rule monitors RDS instances to ensure database connections use encryption in transit. This prevents credentials and data from being transmitted in plaintext over the network.

**Compliant Configuration Examples**:

#### MySQL/Aurora MySQL
```hcl
# Create parameter group requiring SSL
resource "aws_db_parameter_group" "mysql_force_ssl" {
  family      = "mysql8.0"
  name        = "force-ssl-connections"
  description = "Require SSL for all connections"

  parameter {
    name  = "require_secure_transport"
    value = "1"  # Enforces SSL
  }
}

# Apply to RDS instance
resource "aws_db_instance" "mysql" {
  engine               = "mysql"
  instance_class       = "db.t3.micro"
  parameter_group_name = aws_db_parameter_group.mysql_force_ssl.name
  # ... other settings
}
```

#### PostgreSQL/Aurora PostgreSQL
```hcl
# Create parameter group requiring SSL
resource "aws_db_parameter_group" "postgres_force_ssl" {
  family      = "postgres15"
  name        = "force-ssl-connections"
  description = "Require SSL for all connections"

  parameter {
    name  = "rds.force_ssl"
    value = "1"  # Enforces SSL
  }
}

# Apply to RDS instance
resource "aws_db_instance" "postgres" {
  engine               = "postgres"
  instance_class       = "db.t3.micro"
  parameter_group_name = aws_db_parameter_group.postgres_force_ssl.name
  # ... other settings
}
```

**Grace Period**: The RDS SSL rule evaluates every 24 hours (not on every change), providing a 24-hour grace period for remediation before marking resources non-compliant.

**Alert Example**:
```
🚨 AWS Config Compliance Violation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Rule:          rds-require-ssl-connection
Status:        NON_COMPLIANT
Resource:      my-database-instance
Type:          AWS::RDS::DBInstance
Region:        eu-north-1
Account:       123456789012
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Action Required: Review and remediate the non-compliant resource.
```

## Multi-Cloud Strategy

*"Why put all your eggs in one basket when you can distribute them across multiple baskets in different regions with redundant storage and automatic failover?"*

This AWS infrastructure complements the Azure setup and demonstrates:
- **Cross-cloud policy enforcement** *(Because rules should be universal, like speed limits)*
- **Identity federation** *(One login to rule them all... hopefully)*
- **Secret management strategies** *(Spoiler: Don't commit them to git)*
- **Compliance in heterogeneous environments** *(Fancy words for "it works on both clouds")*

### Why Multi-Cloud?
- ✅ Vendor lock-in avoidance *(Freedom!)*
- ✅ Geographic distribution *(Hello from Stockholm! 🇸🇪)*
- ✅ Best-of-breed services *(Use each cloud's superpowers)*
- ✅ Resume padding *(You can now say "I do multi-cloud")*
- ❌ Double the clouds = Double the bills *(But who's counting?)*
