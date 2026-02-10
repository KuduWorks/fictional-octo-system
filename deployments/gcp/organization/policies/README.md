# GCP Organization Policies

> *"Because trusting everyone with service account keys is like leaving your house unlocked"* 🔐🏛️

This module implements GCP Organization Policies to enforce security controls across your entire organization, addressing the GCP security notification about service account key management and credential lifecycle security.

## Overview

Organization Policies allow you to centrally manage security controls that apply to all projects, folders, and resources in your GCP organization. This module implements four critical policies recommended by GCP for secure credential management:

1. **Service Account Key Expiry** - Enforce 90-day rotation for user-managed keys
2. **Disable Key Creation** - Prevent new user-managed service account keys
3. **Disable Key Upload** - Block external key imports
4. **Domain Restriction** - Limit IAM members to your organization's domains

## Why These Policies Matter

Following the recent GCP security notification, these policies address the top security risks for unauthorized access:
- Long-lived credentials without rotation
- User-managed keys instead of Workload Identity Federation
- External keys imported from untrusted sources
- IAM access granted to users outside your organization

## Quick Start

### Step 1: Prerequisites

```bash
# Authenticate to GCP
gcloud auth application-default login

# Verify organization admin permissions
gcloud organizations get-iam-policy <your-org-id> \
  --flatten="bindings[].members" \
  --filter="bindings.members:user:$(gcloud config get-value account)" \
  --format="value(bindings.role)"

# Should include: roles/resourcemanager.organizationAdmin
```

### Step 2: Get Required Information

```bash
# Get Organization ID
gcloud organizations list
# Example output: DISPLAY_NAME: yourdomain.com, ID: 123456789012

# Get Cloud Identity Customer ID (for domain restriction policy)
gcloud organizations describe <your-org-id> \
  --format="value(owner.directoryCustomerId)"
# Example output: C0abc123def

# Get Organization Domain
gcloud organizations describe <your-org-id> \
  --format="value(displayName)"
# Example output: yourdomain.com
```

### Step 3: Configure Module

```bash
cd deployments/gcp/organization/policies/

# Copy backend configuration
cp backend.tf.example backend.tf
sed -i 's/<YOUR-PROJECT-ID>/<your-project-id>/g' backend.tf

# Copy variables configuration
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Update with your actual values
```

Update `terraform.tfvars`:
```hcl
organization_id = "123456789012"
project_id      = "my-bootstrap-project"

# Start with dry-run mode for testing
dry_run = true

# Enable all policies
enable_key_expiry_policy         = true
enable_key_creation_policy       = true
enable_key_upload_policy         = true
enable_domain_restriction_policy = true

# Configure policies
key_expiry_hours = 2160  # 90 days

allowed_policy_member_domains = [
  "C0abc123def",       # Your Cloud Identity customer ID
  "yourdomain.com",    # Your organization domain
]

# No exemptions initially
exclude_folders  = []
exclude_projects = []
```

### Step 4: Deploy in Dry-Run Mode

```bash
# Initialize Terraform
terraform init

# Review plan
terraform plan

# Deploy policies in dry-run (testing) mode
terraform apply
```

Output will show dry-run warning:
```
⚠️  DRY-RUN MODE ACTIVE ⚠️
Organization policies are deployed in DRY-RUN mode.
Policy violations are LOGGED but NOT ENFORCED.
```

### Step 5: Test Policies (Dry-Run)

During dry-run mode, violations are logged but not blocked. This allows you to identify impact before enforcement.

#### Monitor Policy Violations

```bash
# View all policy violations in the last 7 days
gcloud logging read \
  "protoPayload.methodName=\"SetOrgPolicy\" AND \
   protoPayload.request.policy.dryRun=true" \
  --limit=50 \
  --format=json \
  --freshness=7d

# View violations for specific policy
gcloud logging read \
  "protoPayload.methodName=\"SetOrgPolicy\" AND \
   resource.labels.policy_name=\"iam.serviceAccountKeyExpiryHours\" AND \
   protoPayload.request.policy.dryRun=true" \
  --limit=20 \
  --format=json

# Count violations by project
gcloud logging read \
  "protoPayload.methodName=\"SetOrgPolicy\" AND \
   protoPayload.request.policy.dryRun=true" \
  --format="value(resource.labels.project_id)" \
  --freshness=7d | sort | uniq -c | sort -rn
```

#### Test Key Creation (Should Log, Not Block)

```bash
# Try to create a service account key (will succeed in dry-run)
gcloud iam service-accounts keys create test-key.json \
  --iam-account=test-sa@<your-project>.iam.gserviceaccount.com

# Check if violation was logged
gcloud logging read \
  "protoPayload.methodName=\"google.iam.admin.v1.CreateServiceAccountKey\" AND \
   severity=NOTICE" \
  --limit=5 \
  --format=json

# Clean up test key
rm test-key.json
```

### Step 6: Review and Adjust Exemptions

Based on violation logs, identify resources that need policy exemptions:

```hcl
# In terraform.tfvars
exclude_projects = [
  "legacy-app-project",  # PERMANENT: Cannot migrate to Workload Identity - Approved 2026-02-10
  "vendor-integration",  # EXPIRES: 2026-12-31 - Vendor requires service account keys - Review quarterly
]
```

Re-apply to test with exemptions:
```bash
terraform apply
```

### Step 7: Enable Enforcement

Once testing is complete and exemptions are configured:

```hcl
# In terraform.tfvars
dry_run = false  # Enable enforcement
```

```bash
# Apply enforcement
terraform apply

# Verify policies are enforced
terraform output policies_summary
```

Output should show:
```
Mode: ENFORCED (production)
```

### Step 8: Verify Enforcement

```bash
# Try to create a service account key (should fail)
gcloud iam service-accounts keys create test-key.json \
  --iam-account=test-sa@<your-project>.iam.gserviceaccount.com

# Expected error:
# ERROR: (gcloud.iam.service-accounts.keys.create) PERMISSION_DENIED: 
# Policy iam.disableServiceAccountKeyCreation is enforced
```

## What Gets Created

| Policy | Purpose | Default | Impact |
|--------|---------|---------|--------|
| **iam.serviceAccountKeyExpiryHours** | Enforce 90-day key rotation | Enabled | Existing keys >90 days expire |
| **iam.disableServiceAccountKeyCreation** | Block new user-managed keys | Enabled | Cannot create new keys |
| **iam.disableServiceAccountKeyUpload** | Block external key uploads | Enabled | Cannot upload keys |
| **iam.allowedPolicyMemberDomains** | Restrict IAM to specific domains | Enabled* | External users blocked |

*Enabled only if `allowed_policy_member_domains` is configured.

## Testing Policies in Dry-Run Mode

### Why Dry-Run First?

Dry-run mode allows you to:
1. **Identify impacted resources** before blocking operations
2. **Test exemptions** without affecting production workloads
3. **Communicate changes** to teams before enforcement
4. **Adjust policies** based on real-world usage patterns

### Dry-Run Workflow

```
┌─────────────────────────────────────┐
│ 1. Deploy with dry_run = true      │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ 2. Monitor Cloud Logging            │
│    - View violation patterns        │
│    - Identify affected projects     │
│    - Analyze impact                 │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ 3. Configure Exemptions             │
│    - Add exclude_projects           │
│    - Add exclude_folders            │
│    - Document justification         │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ 4. Test with Exemptions             │
│    - Verify exempted resources OK   │
│    - Ensure intended resources fail │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ 5. Set dry_run = false              │
│    - Enable enforcement             │
│    - Policies now block violations  │
└─────────────────────────────────────┘
```

### Cloud Logging Queries

#### All Policy Violations (Last 24 Hours)
```bash
gcloud logging read \
  "protoPayload.methodName=\"SetOrgPolicy\" AND \
   protoPayload.request.policy.dryRun=true" \
  --limit=100 \
  --format=json \
  --freshness=24h
```

#### Violations by Policy Type
```bash
# Key creation attempts
gcloud logging read \
  "protoPayload.methodName=\"google.iam.admin.v1.CreateServiceAccountKey\"" \
  --limit=20 \
  --format="table(timestamp, resource.labels.project_id, protoPayload.authenticationInfo.principalEmail)"

# Key upload attempts
gcloud logging read \
  "protoPayload.methodName=\"google.iam.admin.v1.UploadServiceAccountKey\"" \
  --limit=20

# IAM policy changes (domain restriction)
gcloud logging read \
  "protoPayload.methodName=\"SetIamPolicy\" AND \
   severity=NOTICE" \
  --limit=20
```

#### Export Violations to JSON
```bash
gcloud logging read \
  "protoPayload.methodName=\"SetOrgPolicy\" AND \
   protoPayload.request.policy.dryRun=true" \
  --limit=500 \
  --format=json \
  --freshness=7d > policy-violations-$(date +%Y-%m-%d).json
```

## Common Exemption Scenarios

### Permanent Exemptions

#### Legacy Applications
```hcl
exclude_projects = [
  "mainframe-integration",  # PERMANENT: Legacy mainframe connector - Requires service account keys - Approved 2026-02-10 by CTO
]
```
**Justification**: Application cannot be modified to use Workload Identity due to technology constraints.

#### Third-Party Integrations
```hcl
exclude_projects = [
  "vendor-saas-integration",  # PERMANENT: SaaS vendor requires service account JSON key - Approved 2026-02-10 - Annual review required
]
```
**Justification**: External vendor platform only supports service account key authentication.

#### On-Premise Systems
```hcl
exclude_folders = [
  "123456789012",  # PERMANENT: On-premise datacenter folder - Cannot use Workload Identity - Approved 2026-02-10 - Review annually
]
```
**Justification**: On-premise systems outside GCP cannot use Workload Identity Federation.

### Expiring Exemptions

#### Migration Projects
```hcl
exclude_projects = [
  "aws-migration-2026",  # EXPIRES: 2026-12-31 - AWS to GCP migration project - Review monthly - Remove when migration complete
]
```
**Justification**: Temporary exemption during 9-month migration. Review monthly, remove on completion.

#### Proof of Concept
```hcl
exclude_projects = [
  "ml-model-poc-q1",  # EXPIRES: 2026-03-31 - Q1 ML proof of concept - Review end of quarter - Decommission or enforce
]
```
**Justification**: Short-term POC project. Enforce policies if moving to production.

#### Vendor Transition
```hcl
exclude_projects = [
  "old-vendor-integration",  # EXPIRES: 2026-06-30 - Transitioning to new vendor with Workload Identity support - Review monthly
]
```
**Justification**: Transitioning to new vendor platform. Remove exemption when migration complete.

### Exemption Tracking Best Practices

**Use inline comments with structured format:**
```hcl
"resource-id",  # TYPE: YYYY-MM-DD - Justification - Review frequency - Approver
```

**Examples:**
```hcl
exclude_projects = [
  # Permanent exemptions
  "legacy-system",  # PERMANENT: Cannot migrate - Security compensating controls in place - Reviewed 2026-02-10 by CISO

  # Expiring exemptions
  "migration-proj", # EXPIRES: 2026-08-01 - 6-month migration window - Review monthly - Approved by VP Engineering
  "vendor-pilot",   # EXPIRES: 2026-04-30 - Pilot program - Review after pilot ends - Approved by Product Manager
]
```

## Policy Details

### Service Account Key Expiry (iam.serviceAccountKeyExpiryHours)

**Purpose**: Enforce maximum lifespan for user-managed service account keys.

**Default**: 2160 hours (90 days)

**Impact**:
- Keys older than 90 days will expire
- Applications using expired keys will fail authentication
- Forces key rotation for security

**Best Practice**: Migrate to Workload Identity Federation instead of rotating keys.

**Configuration:**
```hcl
key_expiry_hours = 2160  # 90 days (recommended)
# Or customize:
# key_expiry_hours = 720   # 30 days (stricter)
# key_expiry_hours = 4320  # 180 days (less strict)
```

### Disable Key Creation (iam.disableServiceAccountKeyCreation)

**Purpose**: Prevent creation of new user-managed service account keys.

**Impact**:
- `gcloud iam service-accounts keys create` will fail
- Console key creation blocked
- API key creation requests denied

**Exceptions**: System-managed keys (used by GCE, GAE) are unaffected.

**Migration Path**: Use [Workload Identity Federation](../../iam/workload-identity/) for automation.

### Disable Key Upload (iam.disableServiceAccountKeyUpload)

**Purpose**: Block uploading externally-generated service account keys.

**Impact**:
- Cannot upload keys generated outside GCP
- Prevents importing potentially compromised keys
- Forces key generation within GCP's secure environment

**Use Case**: Blocks keys generated on developer laptops or CI/CD systems.

### Allowed Policy Member Domains (iam.allowedPolicyMemberDomains)

**Purpose**: Restrict IAM policy members to specific domains.

**Configuration:**
```hcl
allowed_policy_member_domains = [
  "C0abc123def",       # Cloud Identity customer ID
  "yourdomain.com",    # Organization domain
  # "partner.com",     # Trusted partner domain (if needed)
]
```

**Impact**:
- Cannot grant IAM roles to users outside allowed domains
- Blocks `user:external@gmail.com` or `user:contractor@other.com`
- Service accounts from other organizations blocked

**Exceptions**: 
- Google-managed service accounts (`@gserviceaccount.com`) may need exemption
- Cross-organization collaboration requires explicit configuration

## Cost

**Organization Policies: FREE** ✅
- No charge for policy creation
- No charge for policy enforcement
- No charge for dry-run testing
- No limits on number of policies

## Troubleshooting

### "Permission denied" error deploying policies
```bash
# Ensure you have organization admin role
gcloud organizations add-iam-policy-binding <your-org-id> \
  --member="user:your-email@domain.com" \
  --role="roles/resourcemanager.organizationAdmin"
```

### Policy violations not appearing in Cloud Logging
```bash
# Ensure Cloud Logging is enabled
gcloud services enable logging.googleapis.com --project=<your-project>

# Increase log retention if needed
gcloud logging buckets update _Default \
  --location=global \
  --retention-days=30
```

### Key creation blocked but policy is in dry-run
```bash
# Verify dry_run setting
terraform output dry_run_mode

# Check policy configuration
gcloud org-policies describe iam.disableServiceAccountKeyCreation \
  --organization=<your-org-id>
```

### Exemptions not working
```bash
# Verify folder/project IDs are correct
gcloud resource-manager folders list --organization=<your-org-id>
gcloud projects list --format="value(projectId)"

# Check Terraform output for exempted resources
terraform output exempted_resources
```

### Policy conflicts with existing setups
```bash
# Deploy in dry-run first
dry_run = true

# Monitor violations
gcloud logging read "protoPayload.methodName=\"SetOrgPolicy\"" --limit=50

# Add exemptions as needed
exclude_projects = ["conflicting-project"]
```

## Integration with Other Modules

This module works alongside:
- **Essential Contacts** ([deployments/gcp/bootstrap/essential-contacts](../../bootstrap/essential-contacts/)) - Receive policy violation alerts
- **Service Account Audits** ([deployments/gcp/organization/scripts](../scripts/)) - Automated compliance checks
- **Workload Identity** ([deployments/gcp/iam/workload-identity](../../iam/workload-identity/)) - Keyless authentication alternative

## Security Best Practices

✅ **DO:**
- Start with `dry_run = true` to test impact
- Document all exemptions with justification
- Review exemptions quarterly
- Use Workload Identity Federation instead of service account keys
- Monitor Cloud Logging for violations
- Set expiration dates for temporary exemptions

❌ **DON'T:**
- Deploy with `dry_run = false` without testing
- Create blanket exemptions at organization level
- Exempt entire folders without review
- Ignore dry-run violations
- Grant permanent exemptions without security review
- Disable policies to avoid migration work

## Future Refinements

🔮 **Planned Enhancements:**
- Automated exemption expiry tracking and alerts
- Integration with GitHub Issues for exemption reviews
- Terraform validation for exemption comment format
- Dashboard for policy compliance metrics
- Automated remediation for policy violations

## Variables Reference

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `organization_id` | string | - | GCP Organization ID (required) |
| `project_id` | string | - | Project for Terraform state (required) |
| `dry_run` | bool | `true` | Enable dry-run testing mode |
| `enable_key_expiry_policy` | bool | `true` | Enable key expiry policy |
| `enable_key_creation_policy` | bool | `true` | Enable key creation blocking |
| `enable_key_upload_policy` | bool | `true` | Enable key upload blocking |
| `enable_domain_restriction_policy` | bool | `true` | Enable domain restriction |
| `key_expiry_hours` | number | `2160` | Key lifespan in hours (90 days) |
| `allowed_policy_member_domains` | list(string) | `[]` | Allowed domains for IAM members |
| `exclude_folders` | list(string) | `[]` | Exempt folder IDs |
| `exclude_projects` | list(string) | `[]` | Exempt project IDs |
| `gcp_region` | string | `"europe-north1"` | Default GCP region |
| `environment` | string | `"production"` | Environment label |

## Next Steps

1. ✅ Deploy Organization Policies (you're here!)
2. 📧 Configure [Essential Contacts](../../bootstrap/essential-contacts/) for alerts
3. 🔍 Set up [Service Account Key Audit](../scripts/) for quarterly compliance
4. 🔐 Migrate to [Workload Identity Federation](../../iam/workload-identity/) for keyless auth
5. 💰 Monitor costs with [Budget Alerts](../../cost-management/budgets/)

## Additional Resources

- [GCP Organization Policies Documentation](https://cloud.google.com/resource-manager/docs/organization-policy/overview)
- [IAM Security Best Practices](https://cloud.google.com/iam/docs/best-practices)
- [Service Account Key Management](https://cloud.google.com/iam/docs/best-practices-service-accounts#key-management)
- [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)

---

**💡 Pro Tip**: Always test policies in dry-run mode first. Use Cloud Logging to identify violations before enforcement. Document exemptions with expiration dates for easier review!

**Cost: $0.00/month** 💰✨
