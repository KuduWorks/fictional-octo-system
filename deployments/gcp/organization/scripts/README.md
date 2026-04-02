# GCP Service Account Key Audit Scripts

> *"Because forgetting about that 3-year-old service account key is how breaches happen"* 🔍🔐

This module provides automated security auditing scripts for GCP service account keys, addressing the GCP security notification about dormant credentials and credential lifecycle management.

## Overview

The Service Account Key Audit script scans all service accounts across your GCP organization to identify security risks:
- **Dormant keys**: Keys with no activity in the last 30 days
- **User-managed keys**: Manual keys that should migrate to Workload Identity
- **Expiring keys**: Keys approaching rotation deadlines
- **Key age tracking**: Visibility into credential lifecycle

## Quick Start

### Prerequisites

```bash
# Authenticate to GCP
gcloud auth application-default login

# Ensure you have permissions across projects
gcloud auth login

# Verify access to projects
gcloud projects list
```

### Basic Audit

```bash
cd deployments/gcp/organization/scripts/

# Run audit with default settings
./service-account-key-audit.sh
```

Output:
```
[2026-02-10 14:30:00] Starting GCP Service Account Key Audit (v1.0.0)
[2026-02-10 14:30:01] Dormant threshold: 30 days
✓ Found 5 project(s)

════════════════════════════════════════════════════════════════════════
SERVICE ACCOUNT                                    KEY TYPE        AGE (DAYS)   LAST USED       STATUS
════════════════════════════════════════════════════════════════════════
github-actions@dev-project.iam.gserviceaccount.com SYSTEM_MANAGED  45           N/A             ACTIVE
old-automation@dev-project.iam.gserviceaccount.com USER_MANAGED    118          N/A             DORMANT
terraform-sa@prod-project.iam.gserviceaccount.com  SYSTEM_MANAGED  12           N/A             ACTIVE
════════════════════════════════════════════════════════════════════════

SUMMARY:
  Total projects scanned: 5
  Total service accounts: 15
  User-managed keys found: 1
  Dormant keys (>30 days): 1

⚠ Action required: 1 dormant key(s) found
✓ JSON report saved: ./audit-reports/audit-report-2026-02-10.json
✓ Report uploaded to Secret Manager: gcp-service-account-audit-reports (version: 1)

Retrieve report with:
  gcloud secrets versions access latest --secret="gcp-service-account-audit-reports" > audit.json
```

## Why Dual Output Formats?

This script outputs audit results in TWO formats simultaneously:

### 1. Colored Table (stdout)
**Purpose**: Immediate visual feedback for CLI users

**Benefits**:
- Quick scan of security status at a glance
- Color-coded severity (green/yellow/red)
- Human-readable format for debugging
- Real-time progress visibility

**Use Case**: Running script manually for immediate review

```bash
# View colored table in terminal
./service-account-key-audit.sh

# Save table output for sharing
./service-account-key-audit.sh > audit-table.txt
```

### 2. JSON File (machine-readable)
**Purpose**: Automation, storage, and programmatic analysis

**Benefits**:
- Machine-parseable for CI/CD pipelines
- Structured data for GitHub Actions integration
- Compatible with Secret Manager storage
- Enables historical trend analysis

**Use Case**: Automated quarterly audits, GitHub Issue creation

```bash
# Parse JSON for specific findings
cat ./audit-reports/audit-report-2026-02-10.json | jq '.findings[] | select(.status == "DORMANT")'

# Count dormant keys
cat ./audit-reports/audit-report-2026-02-10.json | jq '.summary.dormant_keys_30d'
```

**Why Both?**
- **Table**: Human review and debugging
- **JSON**: Automation and long-term storage
- **Consistency**: Both formats use same underlying data
- **Flexibility**: Choose format based on use case

## Script Options

### Verbose Mode
Enable detailed logging for debugging:
```bash
./service-account-key-audit.sh --verbose

# Example verbose output:
# [VERBOSE] Scanning project: dev-project-123
# [VERBOSE]   Found 3 service account(s)
# [VERBOSE]     Checking keys for: github-actions@dev-project-123.iam.gserviceaccount.com
# [VERBOSE]     Checking keys for: terraform-sa@dev-project-123.iam.gserviceaccount.com
```

**When to use**: Debugging failures, understanding scan progress, troubleshooting permissions

### Custom Dormant Threshold
```bash
# Mark keys as dormant after 60 days instead of 30
./service-account-key-audit.sh --dormant-days 60

# Strict mode: 7-day threshold
./service-account-key-audit.sh --dormant-days 7
```

### Custom Output File
```bash
# Save to specific filename
./service-account-key-audit.sh --output quarterly-audit-q1-2026.json

# Save with timestamp
./service-account-key-audit.sh --output "audit-$(date +%Y%m%d-%H%M%S).json"
```

### Local File Only (No Secret Manager Upload)
```bash
# Skip Secret Manager upload
./service-account-key-audit.sh --no-upload
```

**When to use**: Testing script, offline analysis, storage constraints

### Debugging with Verbose Mode
```bash
# Redirect verbose output to debug log
./service-account-key-audit.sh --verbose > debug.log 2>&1

# Verbose + custom output
./service-account-key-audit.sh --verbose --output test-audit.json
```

## Color Scheme Documentation

For consistency across all GCP scripts, this color scheme is used:

| Color | Meaning | Example |
|-------|---------|---------|
| **🟢 GREEN** | OK / No action needed | SYSTEM_MANAGED keys, active service accounts |
| **🟡 YELLOW** | Warning / Review recommended | USER_MANAGED keys (should migrate to Workload Identity) |
| **🔴 RED** | Critical / Action required | DORMANT keys (>30 days inactive, should be disabled) |
| **🔵 BLUE** | Informational | Log messages, headers, section dividers |

**TTY Detection**: Colors automatically disabled in non-interactive environments (e.g., GitHub Actions logs).

## Secret Manager Storage

### Why Secret Manager?

**Benefits**:
- ✅ **Free for quarterly audits** (within 6-version free tier)
- ✅ **Encrypted at rest** (AES-256 encryption)
- ✅ **Automatic versioning** (each audit = new version)
- ✅ **365-day TTL** (automatic expiration/cleanup)
- ✅ **GCP-native** (no cross-cloud dependencies)
- ✅ **Access control** via IAM roles

**Cost**: $0.00/month for quarterly audits (4 versions < 6-version free tier)

### Secret Structure

```
Secret Name: gcp-service-account-audit-reports
Replication: Automatic (multi-region)
TTL: 365 days (auto-expires after 1 year)

Version 1: 2026-02-10 audit (expires 2027-02-10)
Version 2: 2026-05-10 audit (expires 2027-05-10)
Version 3: 2026-08-10 audit (expires 2027-08-10)
Version 4: 2026-11-10 audit (expires 2027-11-10)
```

### Retrieve Audit Reports

```bash
# Get latest audit
gcloud secrets versions access latest \
  --secret="gcp-service-account-audit-reports" > latest-audit.json

# List all audit versions
gcloud secrets versions list gcp-service-account-audit-reports

# Get specific version
gcloud secrets versions access 2 \
  --secret="gcp-service-account-audit-reports" > audit-v2.json

# View audit summary without downloading
gcloud secrets versions access latest \
  --secret="gcp-service-account-audit-reports" | jq '.summary'
```

## Exit Code Behavior

**Script always exits with code 0** (success), even if dormant keys are found.

**Why Exit 0?**
- Script is **informational**, not enforcement
- GitHub Issues signal action needed (not workflow failure)
- Allows CI/CD pipelines to continue
- Prevents false-positive failures in automation

**Example**:
```bash
# Script finds dormant keys but exits 0
./service-account-key-audit.sh
echo $?
# Output: 0

# GitHub workflow continues, creates Issue for findings
```

## Error Handling

Script continues scanning even if individual projects fail:

```bash
# Project 1: Success ✓
# Project 2: Permission denied ⚠ (logged, continues to Project 3)
# Project 3: Success ✓
# Project 4: Service account list failed ⚠ (logged, continues to Project 5)
# Project 5: Success ✓
```

Failed projects are logged in JSON output:
```json
{
  "failed_projects": ["restricted-project", "inaccessible-project"]
}
```

## Cost Comparison

### Secret Manager (Recommended for Quarterly Audits)

| Item | Price | Quarterly Cost |
|------|-------|----------------|
| Secret versions (4/year) | $0.06 per version/month | **$0.00** (free tier) |
| Access operations (~10/month) | $0.03 per 10,000 ops | **$0.00** (free tier) |
| **Total Annual Cost** | | **$0.00** ✅ |

**Free Tier**: 6 active secret versions/month included

### GCS Bucket (Alternative for Large Organizations)

| Item | Price | Quarterly Cost |
|------|-------|----------------|
| Storage (4 reports × 100KB) | $0.020 per GB/month | **~$0.0001/year** |
| Operations (4 writes, 120 reads) | $0.05 per 10,000 writes | **~$0.0005/year** |
| **Total Annual Cost** | | **~$0.0006** ✅ |

**When to use GCS**: Reports > 64KB (large organizations with 500+ service accounts)

### BigQuery (Future Enhancement - For Trend Analysis)

🔮 **Future**: BigQuery integration coming in a future release for large organizations requiring historical trend analysis, cost forecasting, and compliance dashboards.

**Use Case**:
- Historical audit comparisons
- Trend analysis (key creation/deletion rates)
- Compliance reporting (quarterly SOC2 evidence)
- Cost attribution per team/project

**Example Queries** (Future):
```sql
-- Trend: Dormant keys over time
SELECT audit_date, summary.dormant_keys_30d
FROM `project.dataset.audit_reports`
ORDER BY audit_date DESC;

-- Top 5 projects by user-managed keys
SELECT project, COUNT(*) as key_count
FROM `project.dataset.audit_reports`, UNNEST(findings)
WHERE key_type = 'USER_MANAGED'
GROUP BY project
ORDER BY key_count DESC
LIMIT 5;
```

## Size Limitations

### Secret Manager Limit: 64 KB per secret version

**Typical Report Sizes**:
- Small org (10-50 service accounts): ~5-10 KB ✅
- Medium org (50-200 service accounts): ~15-30 KB ✅
- Large org (200-500 service accounts): ~40-60 KB ⚠️
- Very large org (500+ service accounts): 65+ KB ❌

**If you exceed 64 KB**:
1. Script warns when approaching limit (60 KB)
2. Consider switching to GCS bucket storage
3. Or split audits by folder/project (run multiple times)

**GCS Migration** (if needed):
```bash
# Upload to GCS instead
gsutil cp ./audit-reports/audit-report-2026-02-10.json \
  gs://fictional-octo-system-audit-reports-<PROJECT-ID>/$(date +%Y)/

# Cost: ~$0.0006/year for quarterly audits
```

## Integration with GitHub Actions

This script is designed for automated quarterly audits via GitHub Actions:

**Workflow** (see [.github/workflows/gcp-security-audit.yml](../../../.github/workflows/gcp-security-audit.yml)):
1. Runs quarterly (Q1, Q2, Q3, Q4)
2. Executes audit script
3. Parses JSON output
4. Creates GitHub Issue if dormant keys found
5. Uploads report to Secret Manager
6. Attaches JSON as workflow artifact

**Manual Trigger**: Workflow supports `workflow_dispatch` for ad-hoc audits

## Troubleshooting

### Permission denied errors
```bash
# Ensure you have IAM permissions
gcloud projects add-iam-policy-binding <project-id> \
  --member="user:your-email@domain.com" \
  --role="roles/iam.securityReviewer"
```

### Script fails to create secret
```bash
# Enable Secret Manager API
gcloud services enable secretmanager.googleapis.com

# Grant secret admin permissions
gcloud projects add-iam-policy-binding <project-id> \
  --member="user:your-email@domain.com" \
  --role="roles/secretmanager.admin"
```

### No service accounts found
```bash
# Verify you have access to projects
gcloud projects list

# Check specific project
gcloud iam service-accounts list --project=<project-id>
```

### Colors not showing
```bash
# Colors require TTY (terminal)
# If piping or redirecting, colors are automatically disabled

# Force colors (if needed)
export TERM=xterm-256color
./service-account-key-audit.sh
```

### Report size warning
```
⚠ Report size (62000 bytes) approaching Secret Manager limit (64KB)
```

**Solution**:
- Switch to GCS bucket storage (see Cost Comparison above)
- Or split audit by project: `./service-account-key-audit.sh` per project

## Security Best Practices

✅ **DO:**
- Run audits quarterly (automated via GitHub Actions)
- Review dormant keys immediately
- Disable unused service accounts
- Migrate to Workload Identity Federation
- Store audit reports in Secret Manager (encrypted)
- Use verbose mode for debugging only

❌ **DON'T:**
- Commit JSON reports to git (contains service account names)
- Share audit reports publicly (sensitive infrastructure info)
- Ignore dormant keys (security risk)
- Run audits too frequently (monthly audits = $4.32/year cost)

## Future Refinements

🔮 **Planned Enhancements:**
- BigQuery integration for historical trend analysis
- Slack/email notifications via GitHub Actions marketplace
- Automated remediation script (disable dormant keys)
- Workflow input parameters for targeted audits
- Cost forecasting based on key creation trends
- Integration with PagerDuty for critical findings

## Examples

### Weekly Development Team Audit
```bash
# Stricter threshold for active development
./service-account-key-audit.sh --dormant-days 7 --verbose
```

### Quarterly Compliance Audit
```bash
# Standard 30-day threshold with Secret Manager storage
./service-account-key-audit.sh --output compliance-q1-2026.json
```

### Production-Only Audit
```bash
# Filter for production projects only (manual)
gcloud config set project prod-project-123
./service-account-key-audit.sh --no-upload
```

### Debug Failed Audit
```bash
# Verbose mode + local file only
./service-account-key-audit.sh --verbose --no-upload > debug.log 2>&1
cat debug.log | grep "Failed"
```

## Next Steps

1. ✅ Run initial manual audit (verify setup)
2. 📧 Configure [Essential Contacts](../../bootstrap/essential-contacts/) for security alerts
3. 📋 Deploy [Organization Policies](../policies/) to prevent new key creation
4. 🤖 Enable [Automated Quarterly Audits](.github/workflows/gcp-security-audit.yml) via GitHub Actions
5. 🔐 Migrate to [Workload Identity Federation](../../iam/workload-identity/) for keyless auth

## Additional Resources

- [GCP Service Account Best Practices](https://cloud.google.com/iam/docs/best-practices-service-accounts)
- [Secret Manager Documentation](https://cloud.google.com/secret-manager/docs)
- [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
- [GitHub Actions Security Best Practices](https://docs.github.com/en/actions/security-guides)

---

**💡 Pro Tip**: Combine this audit script with organization policies (disable key creation) and Workload Identity Federation (keyless auth) for a complete security posture!

**Cost: $0.00/month** (quarterly audits with Secret Manager) 💰✨
