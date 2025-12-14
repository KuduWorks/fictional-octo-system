# App Registration Approval Workflow

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Quick Start Guide](#quick-start-guide)
- [Developer Guide](#developer-guide)
- [Reviewer Guide](#reviewer-guide)
- [Lifecycle Management](#lifecycle-management)
- [Security & Compliance](#security--compliance)
- [Troubleshooting](#troubleshooting)
- [Reference](#reference)

---

## Overview

The App Registration Approval Workflow is a comprehensive PR-based approval system for Azure Entra ID application registrations. It enforces zero-trust principles through automated validation, human oversight, and continuous compliance monitoring.

### Key Features

✅ **Permission Risk Classification** - Automatic HIGH/MEDIUM/LOW risk assessment
✅ **Owner Validation** - Enforce ≥2 owners (≥1 human, ≤1 placeholder)
✅ **Drift Detection** - Daily audits with 7-day grace period for disabled owners
✅ **Quarterly Reviews** - Placeholder service principal cleanup (Q2/Q4)
✅ **Auto-Remediation** - Automatic PR creation for fixable compliance issues
✅ **Manual Override** - Emergency bypass with 50-char audit trail
✅ **Email Notifications** - Azure Communication Services integration

### Security Principles

1. **Zero-Trust** - No permissions by default, explicit justification required
2. **Human-First** - Minimum 1 human owner, placeholders are temporary
3. **Least Privilege** - HIGH-risk permissions require 100-char justification
4. **Accountability** - All actions logged, quarterly reviews enforced
5. **Compliance** - Automated validation, manual overrides audited

---

## Architecture

### Workflow Components

```
┌─────────────────────────────────────────────────────────────┐
│                    Pull Request Created                      │
│              (.github/PULL_REQUEST_TEMPLATE)                 │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              Approval Workflow Triggered                     │
│         (.github/workflows/app-registration-approval.yml)    │
│                                                              │
│  1. Run verify-owners.sh (scripts/)                          │
│  2. Run validate-permissions.sh (scripts/)                   │
│  3. Terraform validate & plan                                │
│  4. Post PR comment with results                             │
│  5. Set commit status (✅/❌)                                 │
└────────────────────────┬────────────────────────────────────┘
                         │
                ┌────────┴────────┐
                │                 │
          ✅ Pass            ❌ Fail
                │                 │
                ▼                 ▼
      ┌─────────────────┐  ┌──────────────────┐
      │ 2 Reviewers     │  │ Fix Issues       │
      │ Approve PR      │  │ Push Updates     │
      └────────┬────────┘  └──────┬───────────┘
               │                  │
               ▼                  │
      ┌─────────────────┐         │
      │ Merge to main   │◄────────┘
      └────────┬────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────────┐
│              Deployment Workflow Triggered                   │
│         (.github/workflows/app-registration-deploy.yml)      │
│                                                              │
│  1. Pre-deployment validation                                │
│  2. Terraform apply                                          │
│  3. Grant admin consent (if requested)                       │
│  4. Post-deployment verification                             │
│  5. Create deployment notification                           │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                 Continuous Monitoring                        │
│                                                              │
│  Daily:     Owner Audit (.../audit.yml)                      │
│  Quarterly: Placeholder Review (.../placeholder-review.yml)  │
│  On Change: Placeholder Tracking (.../placeholder-tracking.yml) │
└─────────────────────────────────────────────────────────────┘
```

### File Structure

```
deployments/azure/app-registration/
├── main.tf                              # Main Terraform module
├── variables.tf                         # Variables with validations
├── outputs.tf                           # Module outputs
├── APPROVAL_WORKFLOW.md                 # This documentation
│
├── config/
│   └── allowed-owners.json              # Governance-approved owner list
│
├── modules/
│   └── placeholder-service-principal/   # Zero-permission SP module
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
│
├── scripts/
│   ├── verify-owners.sh                 # Owner validation script
│   └── validate-permissions.sh          # Permission validation script
│
└── permission-policies/
    └── graph-permissions-risk-matrix.json  # Risk classification rules

.github/
├── PULL_REQUEST_TEMPLATE/
│   └── app_registration.md              # Structured PR template
│
└── workflows/
    ├── app-registration-approval.yml    # PR validation
    ├── app-registration-deploy.yml      # Deployment
    ├── app-registration-audit.yml       # Daily owner audit
    ├── app-registration-placeholder-review.yml  # Quarterly review
    └── app-registration-placeholder-tracking.yml  # Change tracking
```

---

## Quick Start Guide

### For Developers: Creating a New App Registration

1. **Create feature branch:**
   ```bash
   git checkout -b feature/add-my-app-registration
   ```

2. **Copy example configuration:**
   ```bash
   cp deployments/azure/app-registration/examples/basic-app.tfvars \
      deployments/azure/app-registration/terraform.tfvars
   ```

3. **Edit configuration:**
   ```hcl
   app_display_name = "MyApplication"
   
   # IMPORTANT: Owners MUST be from approved governance list
   # See: config/allowed-owners.json
   app_owners = [
     "12345678-1234-1234-1234-123456789012",  # security-admin@example.com
     "87654321-4321-4321-4321-210987654321"   # identity-admin@example.com
   ]
   
   graph_permissions = [
     {
       id    = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
       type  = "Scope"  # Delegated
       value = "User.Read"
     }
   ]
   ```

4. **Commit and push:**
   ```bash
   git add deployments/azure/app-registration/
   git commit -m "Add MyApplication app registration"
   git push origin feature/add-my-app-registration
   ```

5. **Create Pull Request:**
   - Use template: `app_registration.md`
   - Fill in all required sections
   - Wait for validation to complete

6. **Address validation failures** (if any):
   - Review PR comment with validation results
   - Fix issues in your branch
   - Push updates (validation re-runs automatically)

7. **Request reviews:**
   - Tag 2 reviewers
   - Respond to feedback
   - Make requested changes

8. **Merge PR:**
   - After 2 approvals, merge to `main`
   - Deployment workflow triggers automatically
   - Monitor deployment in Actions tab

### For Reviewers: Approving a PR

1. **Review PR checklist:**
   - ✅ At least 2 owners (minimum 1 human)
   - ✅ All human owners are from approved governance list (`config/allowed-owners.json`)
   - ✅ All owners have ENABLED accounts
   - ✅ Placeholder justification substantive (if used)
   - ✅ HIGH-risk permissions have 100+ char justifications
   - ✅ Principle of least privilege followed
   - ✅ Testing evidence provided
   - ✅ Rollback plan documented

2. **Check validation status:**
   - Review automated PR comment
   - Verify all checks passed (✅)
   - Review Terraform plan output

3. **Approve or request changes:**
   - Approve if compliant
   - Request changes with specific feedback
   - Re-review after changes

---

## Developer Guide

### Permission Risk Classification

Permissions are automatically classified as HIGH/MEDIUM/LOW risk:

#### HIGH Risk (`.All` suffix)
- **Examples:** `Directory.ReadWrite.All`, `User.ReadWrite.All`, `Mail.ReadWrite.All`
- **Requirement:** 100+ character justification
- **Justification must include:**
  - Business need and use case
  - Alternatives considered
  - Approval authority and ticket number

**Example:**
```hcl
permission_justifications = {
  "Directory.ReadWrite.All" = "Application manages automated user provisioning for 50+ departments across organization. Requires full directory write access to create user accounts, assign licenses, update attributes, and manage group memberships. Scoped permissions insufficient for cross-departmental automation. Alternative identity governance solutions evaluated but incompatible with existing HRIS integration. Approved by Security Team ticket #SEC-12345 on 2024-03-15. Annual security review scheduled."
}
```

#### MEDIUM Risk (Application permissions without `.All`)
- **Examples:** `User.Read.All`, `Group.Read.All`
- **Requirement:** Justification recommended
- **Review:** Document blast radius

#### LOW Risk (Delegated permissions)
- **Examples:** `User.Read`, `Mail.Send`, `Calendars.Read`
- **Requirement:** None (but document usage)

### Owner Requirements

#### Governance Policy
**All human owners MUST be from the approved governance/security list:**
- See: `config/allowed-owners.json` for current approved owners
- Only users on this list can be designated as app registration owners
- Typically 3-8 high-privilege governance/security users
- Ensures accountability and proper access controls
- Changes to approved list require CISO/Security Leadership approval

#### Minimum Requirements
- **Total owners:** ≥ 2
- **Human owners:** ≥ 1 (MUST be from approved governance list)
- **Placeholder SPs:** ≤ 1

#### Viewing Approved Owners

**List current approved owners:**
```bash
cat deployments/azure/app-registration/config/allowed-owners.json | jq '.allowed_owners.users[] | {email, role, team}'
```

**Example output:**
```json
{
  "email": "security-admin@example.com",
  "role": "Security Administrator",
  "team": "Information Security"
}
{
  "email": "identity-admin@example.com",
  "role": "Identity Administrator",
  "team": "IT Operations"
}
```

#### Requesting Addition to Approved Owner List

**Process:**
1. Submit PR to `config/allowed-owners.json`
2. Include CISO approval documentation
3. Provide business justification for governance role
4. Confirm user has appropriate Entra ID admin roles
5. Security leadership review required

**Not on approved list?**
- Work with existing approved owners to submit your request
- Typical approval time: 2-4 weeks
- Emergency access: See break-glass procedures

#### Finding Owner Object IDs

**Azure CLI:**
```bash
# Find user by email (MUST be from approved list)
az ad user show --id user@company.com --query id -o tsv

# Find user by display name
az ad user list --filter "displayName eq 'John Doe'" --query "[0].id" -o tsv

# Verify user is enabled
az ad user show --id <object-id> --query accountEnabled -o tsv
```

**PowerShell:**
```powershell
# Find user by email
(Get-AzureADUser -ObjectId user@company.com).ObjectId

# Find user by display name
(Get-AzureADUser -Filter "displayName eq 'John Doe'").ObjectId
```

#### Using Placeholder Service Principals

**When to use:**
- Application needed urgently
- Second human owner temporarily unavailable
- Org restructure/transition period

**When NOT to use:**
- Convenience ("too hard" to find 2nd owner)
- Service accounts (use managed identities)
- Long-term (>6 months triggers escalation)

**Example with placeholder:**
```hcl
# Create placeholder module
module "temp_placeholder" {
  source = "./modules/placeholder-service-principal"
  
  placeholder_name = "PLACEHOLDER-MyApp-Owner-Temporary"
  
  justification = <<-EOT
    Second owner John Doe (john.doe@company.com) on parental leave until April 2024.
    Application needed for Q1 product launch scheduled March 15. Jane Smith 
    (jane.smith@company.com) serving as temporary sole human owner. John will be 
    re-added as owner upon return. Approved by VP Engineering (exec@company.com) 
    ticket #ENG-5678.
  EOT
  
  created_by_workflow = "github-actions"
  tags = ["project:product-launch"]
}

# Use in app registration
module "my_app" {
  source = "./deployments/azure/app-registration"
  
  app_display_name = "MyApplication"
  
  app_owners = [
    "12345678-1234-1234-1234-123456789012",  # Jane Smith (human)
    module.temp_placeholder.service_principal_id  # Temporary placeholder
  ]
  
  placeholder_owner_justification = module.temp_placeholder.justification
  
  # ... rest of configuration
}
```

### Handling Validation Failures

#### Owner Validation Failed

**Error:** "User not on approved governance owner list"

**Solution:**
```bash
# View current approved owners
cat deployments/azure/app-registration/config/allowed-owners.json | jq '.allowed_owners.users[].email'

# Replace with approved owner from list
app_owners = [
  "<object-id-of-approved-owner-1>",
  "<object-id-of-approved-owner-2>"
]
```

**Not on the list?**
- Request addition to approved owner list (CISO approval required)
- Work with existing approved owner to submit your request
- See `config/allowed-owners.json` for process documentation

**Error:** "At least 1 HUMAN owner required"

**Solution:**
```hcl
# Ensure at least one owner is from approved governance list
app_owners = [
  "user-object-id-1",     # Must be from config/allowed-owners.json ✅
  "user-object-id-2"      # Must be from config/allowed-owners.json ✅
]
```

**Error:** "Owner account is DISABLED"

**Solution:**
1. Verify owner status: `az ad user show --id <object-id> --query accountEnabled`
2. Replace with active owner if permanently disabled
3. Wait up to 7 days if temporarily disabled (grace period)

#### Permission Validation Failed

**Error:** "HIGH-RISK permission Directory.ReadWrite.All missing justification"

**Solution:**
```hcl
permission_justifications = {
  "Directory.ReadWrite.All" = "Detailed explanation of business need, alternatives considered, approval information... (minimum 100 characters)"
}
```

**Error:** "Permission justification too short (45 characters)"

**Solution:** Expand justification to include:
- Business context
- Why this permission is needed
- Alternatives evaluated
- Approval authority and date
- Security review status

#### Terraform Validation Failed

**Error:** "Resource precondition failed: Maximum 1 placeholder service principal allowed"

**Solution:** Replace extra placeholders with human owners:
```hcl
app_owners = [
  "human-owner-1",
  "human-owner-2",     # Replace placeholder with human
  # "placeholder-sp"  # Remove extra placeholder
]
```

### Manual Override (Emergency Use Only)

For exceptional circumstances:

```hcl
manual_override_justification = "Validation script producing false positive for owner verification. User john.doe@company.com (object ID 12345...) shows as disabled in script but is active in Azure Portal. Verified with IT department ticket #IT-9999. Emergency deployment needed for production incident #PROD-1234. Security team notified and will review post-deployment."
```

**Manual overrides are:**
- Logged in audit trail
- Reviewed quarterly
- May trigger security review if frequent

---

## Reviewer Guide

### Review Checklist

#### 1. Owner Validation

**Verify:**
- [ ] At least 2 owners specified
- [ ] At least 1 human user (not service principal)
- [ ] All owner object IDs are valid UUIDs
- [ ] Owners exist in Azure AD (check automated validation)
- [ ] All owners have ENABLED accounts
- [ ] If placeholder used, justification is ≥50 characters and substantive

**Questions to ask:**
- Why are these individuals appropriate owners?
- Is there a succession plan if primary owner leaves?
- If placeholder used, what's the timeline for replacement?

#### 2. Permission Risk Assessment

**HIGH-Risk Permissions (`.All` suffix):**
- [ ] Justification ≥100 characters
- [ ] Business need clearly explained
- [ ] Alternatives considered and documented
- [ ] Approval authority specified (security team, leadership)
- [ ] Approval ticket/date referenced

**All Permissions:**
- [ ] Principle of least privilege followed
- [ ] Permissions match stated application purpose
- [ ] No excessive or unnecessary permissions
- [ ] Delegated permissions preferred over Application where possible

**Example good justification:**
```
"Application.ReadWrite.All required for CI/CD pipeline managing app registrations 
across dev/staging/prod environments. Pipeline creates/updates/deletes app 
registrations automatically during deployment. Scoped permissions like 
Application.ReadWrite.OwnedBy insufficient as pipeline manages apps owned by 
different teams. Alternative manual approval workflow evaluated but incompatible 
with deployment SLAs. Security architecture review completed (ticket #SEC-7890). 
Approved by Security Team and CISO on 2024-01-15. Annual review scheduled."
```

**Example poor justification:**
```
"Need this permission for the app"  ❌ Too vague, no context
```

#### 3. Configuration Review

**Check:**
- [ ] Application name follows naming convention
- [ ] Redirect URIs are valid and necessary
- [ ] Certificate auth or managed identity used (not secrets for production)
- [ ] Secret rotation policy appropriate (90-180 days)
- [ ] Key Vault storage enabled for secrets
- [ ] Tags complete for cost tracking
- [ ] Testing evidence provided

####
 4. Change Management

**Verify:**
- [ ] Change type clearly specified (new, permission change, owner change, etc.)
- [ ] Business justification for timeline provided
- [ ] Testing completed in non-production environment
- [ ] Rollback plan documented and feasible
- [ ] Impact assessment completed (who/what affected)

#### 5. Security & Compliance

**Check:**
- [ ] No sensitive data in PR (secrets, connection strings, etc.)
- [ ] Admin consent justification provided (if auto-consent requested)
- [ ] Compliance tags present (department, cost center, project)
- [ ] Manual override justification substantive (if used)

### Approval Decision Matrix

| Scenario | Required Reviewers | Notes |
|----------|-------------------|-------|
| New app registration | 2 | Standard approval |
| Permission change (add HIGH-risk) | 2 | Security team review recommended |
| Permission change (remove permissions) | 1-2 | Can be expedited if removing only |
| Owner change (add/remove) | 2 | Verify succession planning |
| Auto-remediation PR | 1 | Drift detection fixes |
| Manual override used | 2 | Extra scrutiny required |
| Placeholder addition | 2 | Review justification carefully |
| Placeholder removal | 1 | Compliance improvement, expedite |

### Common Review Scenarios

**Scenario 1: First-time app registration**
- Verify developer understands ownership responsibilities
- Check permission choices align with application purpose
- Ensure testing evidence provided
- Recommend managed identity if Azure-hosted

**Scenario 2: Adding HIGH-risk permissions**
- Challenge: Is there a less privileged alternative?
- Verify justification includes security review
- Confirm approval from appropriate authority
- Check annual review scheduled

**Scenario 3: Placeholder service principal**
- Verify justification explains why 2 humans unavailable
- Check timeline for replacement is reasonable (<6 months)
- Ensure approval from leadership documented
- Note for quarterly review follow-up

**Scenario 4: Manual override**
- Understand why validation failed
- Verify override is truly necessary
- Check with security team if uncertain
- Document decision rationale in approval comment

---

## Lifecycle Management

### Daily: Owner Drift Detection

**Schedule:** Every day at 9 AM UTC

**Purpose:** Detect when app registration owners are disabled in Azure AD

**Process:**
1. Audit runs automatically via GitHub Actions
2. Queries Azure AD for all owners in Terraform config
3. Checks if any owners have disabled accounts
4. Calculates days since account disabled

**Notifications:**

**Day 0 (Immediate):**
- Basic alert issue created
- Labeled: `drift-detected`, `grace-period`
- Action: Replace disabled owner within 7 days

**Day 7+ (Escalation):**
- Full escalation issue created
- Labeled: `grace-period-expired`, `urgent`, `security`
- Escalated to: Security team, app owners, management
- Action: Immediate remediation required

**Auto-Remediation:**
- Creates draft PR to remove disabled owners
- Requires manual addition of replacement owners
- Reduced approval requirement (1 reviewer)

### Quarterly: Placeholder Review

**Schedule:** First Monday of Q2 (April) and Q4 (October)

**Purpose:** Review all placeholder service principals and enforce 6-month limit

**Process:**
1. Scan Azure AD for all placeholder service principals
2. Calculate age of each placeholder
3. Generate review report
4. Create tracking issues

**Actions by Age:**

| Age | Status | Action |
|-----|--------|--------|
| 0-5 months | ✅ OK | Reminder to replace when owner identified |
| 5-6 months | ⚠️ Warning | Replace soon - approaching limit |
| 6+ months | ��� Escalation | Immediate action + leadership escalation |

**Leadership Escalation (>6 months):**
- Separate escalation issue created
- Decision required within 30 days:
  - Identify permanent owners and replace
  - Decommission application if no longer needed
  - Escalate to architecture review

### Continuous: Placeholder Tracking

**Triggers:** PR created/updated, push to main

**Purpose:** Track placeholder additions/removals in real-time

**On Placeholder Addition:**
- PR comment with warning and requirements
- Label: `placeholder-addition`
- Requires 2 reviewers (standard approval)
- Creates tracking issue on merge

**On Placeholder Removal:**
- PR comment celebrating compliance improvement
- Label: `placeholder-removal`, `compliance-improvement`
- Requires 1 reviewer (expedited approval)
- Closes tracking issue on merge
- Creates celebration issue

### Deployment Lifecycle

```
1. PR Created
   ├─ Validation runs (approval workflow)
   ├─ Results posted as PR comment
   └─ Commit status set (✅/❌)

2. PR Approved (2 reviewers)
   └─ Ready to merge

3. Merged to main
   ├─ Pre-deployment validation
   ├─ Terraform apply
   ├─ Admin consent (if requested)
   ├─ Post-deployment verification
   └─ Deployment notification issued

4. Continuous Monitoring
   ├─ Daily owner drift detection
   ├─ Quarterly placeholder review
   └─ Real-time placeholder tracking
```

---

## Security & Compliance

### Zero-Trust Principles

1. **Default Deny:** No permissions by default, explicit grants only
2. **Least Privilege:** Minimum permissions required for functionality
3. **Verify Explicitly:** Automated validation + human review
4. **Assume Breach:** Continuous monitoring, rapid detection
5. **Minimize Blast Radius:** Scoped permissions preferred over `.All`

### Compliance Controls

| Control | Implementation | Validation |
|---------|---------------|------------|
| 2-Owner Minimum | Terraform validation | Pre-deployment check |
| Human Accountability | ≥1 human owner required | Owner verification script |
| Temporary Placeholders | ≤1 SP, 6-month limit | Quarterly review |
| Permission Justification | HIGH-risk requires 100 chars | Permission validation script |
| Admin Consent | Explicit approval required | Deployment workflow |
| Drift Detection | Daily owner audit | Audit workflow |
| Audit Trail | All changes tracked in Git | Repository history |
| Manual Override | 50-char justification logged | Quarterly review |

### Audit Trail

**What's logged:**
- All Terraform configuration changes (Git history)
- Approval decisions (PR comments/reviews)
- Deployment events (workflow runs)
- Drift detection results (issues created)
- Quarterly reviews (review reports)
- Manual overrides (justifications in config)
- Placeholder additions/removals (tracking issues)

**Retention:**
- Git history: Indefinite
- GitHub issues: Indefinite
- Workflow logs: 90 days (GitHub default)
- Deployment metadata: Stored in `.deployment-history/`

**Compliance Reports:**
```bash
# Generate owner compliance report
./scripts/verify-owners.sh > owner-compliance-$(date +%Y%m%d).json

# Generate permission risk report
./scripts/validate-permissions.sh > permission-risk-$(date +%Y%m%d).json

# List all placeholders
az ad sp list --query "[?tags[?contains(@, 'purpose:placeholder-owner')]]" --output table
```

### Security Best Practices

**DO:**
✅ Use certificate authentication for production apps
✅ Enable managed identities for Azure-hosted apps
✅ Store secrets in Azure Key Vault
✅ Rotate secrets every 90-180 days
✅ Use scoped permissions when possible
✅ Document HIGH-risk permission justifications
✅ Test in non-production first
✅ Replace placeholders within 6 months

**DON'T:**
❌ Use client secrets for long-lived credentials
❌ Grant `.All` permissions without justification
❌ Use placeholders for convenience
❌ Manual override without substantive reason
❌ Skip testing before production deployment
❌ Share service principal credentials
❌ Store secrets in Git/code

---

## Troubleshooting

### Common Issues

#### Issue: "Owner verification failed - account disabled"

**Cause:** Owner account disabled in Azure AD

**Solutions:**
1. **Temporary disable:** Wait for grace period (7 days), owner may be re-enabled
2. **Permanent disable:** Replace owner immediately
   ```hcl
   app_owners = [
     "active-owner-1",
     "active-owner-2"  # Replace disabled owner
   ]
   ```

#### Issue: "Permission validation failed - justification missing"

**Cause:** HIGH-risk permission (ending in `.All`) without justification

**Solution:** Add to `permission_justifications`:
```hcl
permission_justifications = {
  "Directory.ReadWrite.All" = "Detailed justification min 100 characters..."
}
```

#### Issue: "Terraform precondition failed - multiple placeholders"

**Cause:** More than 1 placeholder service principal in `app_owners`

**Solution:** Keep maximum 1 placeholder:
```hcl
app_owners = [
  "human-owner-1",
  "human-owner-2",  # Replace 2nd placeholder with human
  # module.placeholder.service_principal_id  # Remove extra placeholder
]
```

#### Issue: "Manual override not working"

**Cause:** Override justification too short (<50 characters)

**Solution:**
```hcl
manual_override_justification = "Detailed explanation of why override needed, risk assessment, mitigation plan... (minimum 50 characters)"
```

#### Issue: "Deployment failed - admin consent required"

**Cause:** Application permissions require admin consent

**Solution:**
1. **Automated:** Set `grant_admin_consent = true` in workflow dispatch
2. **Manual:** Azure Portal → App Registration → API Permissions → Grant admin consent

#### Issue: "Quarterly review not running"

**Cause:** Cron schedule approximates first Monday

**Solution:** Manually trigger workflow:
```bash
# GitHub CLI
gh workflow run app-registration-placeholder-review.yml -f force_review=true

# Or use GitHub web UI: Actions → Quarterly Placeholder Review → Run workflow
```

### Getting Help

**For validation issues:**
1. Review PR comment with detailed error messages
2. Check workflow logs in Actions tab
3. Run validation scripts locally:
   ```bash
   cd deployments/azure/app-registration
   ./scripts/verify-owners.sh
   ./scripts/validate-permissions.sh
   ```

**For permission questions:**
- [Microsoft Graph Permissions Reference](https://learn.microsoft.com/en-us/graph/permissions-reference)
- Security team contact: security@company.com
- Review `permission-policies/graph-permissions-risk-matrix.json`

**For deployment issues:**
- Check deployment workflow logs
- Review `.deployment-history/` folder
- Contact infrastructure team

**For compliance questions:**
- Review quarterly placeholder reports
- Check drift detection issues
- Contact governance team

---

## Reference

### Configuration Examples

**Minimal configuration:**
```hcl
module "simple_app" {
  source = "./deployments/azure/app-registration"
  
  app_display_name = "SimpleApp"
  
  app_owners = [
    "user-object-id-1",
    "user-object-id-2"
  ]
  
  graph_permissions = [
    {
      id    = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
      type  = "Scope"
      value = "User.Read"
    }
  ]
}
```

**Production configuration with HIGH-risk permissions:**
```hcl
module "production_app" {
  source = "./deployments/azure/app-registration"
  
  app_display_name = "ProductionApp"
  sign_in_audience = "AzureADMyOrg"
  
  app_owners = [
    "12345678-1234-1234-1234-123456789012",  # Primary owner
    "87654321-4321-4321-4321-210987654321"   # Secondary owner
  ]
  
  graph_permissions = [
    {
      id    = "1bfefb4e-e0b5-418b-a88f-73c46d2cc8e9"
      type  = "Role"  # Application permission
      value = "Directory.ReadWrite.All"
    }
  ]
  
  permission_justifications = {
    "Directory.ReadWrite.All" = "Application manages automated user provisioning for 50+ departments. Requires full directory write access to create user accounts, assign licenses, and manage group memberships. Scoped permissions insufficient for cross-departmental automation. Security review completed (ticket #SEC-12345). Approved by CISO on 2024-03-15. Annual review scheduled."
  }
  
  use_certificate_auth = true
  certificate_value    = file("${path.module}/certs/app-cert.pem")
  certificate_end_date = "2025-12-31T23:59:59Z"
  
  store_in_key_vault = true
  key_vault_id       = "/subscriptions/.../Microsoft.KeyVault/vaults/my-keyvault"
  
  grant_admin_consent = true
  
  tags = {
    Environment = "Production"
    CostCenter  = "Engineering"
    Project     = "User Provisioning"
  }
}
```

### File Templates

**terraform.tfvars template:**
```hcl
# App Registration Configuration
app_display_name = "MyApplication"
sign_in_audience = "AzureADMyOrg"

# Owners (minimum 2, at least 1 human)
app_owners = [
  "user-object-id-1",
  "user-object-id-2"
]

# Placeholder justification (if using placeholder SP)
placeholder_owner_justification = ""

# Microsoft Graph Permissions
graph_permissions = [
  {
    id    = "permission-guid"
    type  = "Scope"  # or "Role"
    value = "Permission.Name"
  }
]

# HIGH-risk permission justifications (for .All permissions)
permission_justifications = {
  # "Permission.Name.All" = "Justification minimum 100 characters..."
}

# Manual override (emergency use only)
manual_override_justification = ""

# Authentication
use_certificate_auth = false  # true for production
store_in_key_vault   = false  # true for production

# Admin Consent
grant_admin_consent = false  # Set true if needed

# Tags
tags = {
  Environment = "Development"
  Project     = "MyProject"
}
```

### Useful Commands

**Azure CLI:**
```bash
# Find user by email
az ad user show --id user@company.com --query "{ObjectId:id,DisplayName:displayName,Enabled:accountEnabled}"

# List all app registrations
az ad app list --query "[].{Name:displayName,AppId:appId,ObjectId:id}" --output table

# Check permission exists in Microsoft Graph
az ad sp show --id 00000003-0000-0000-c000-000000000000 \
  --query "appRoles[?value=='User.ReadWrite.All'].{Id:id,Name:value}" --output table

# Grant admin consent manually
az ad app permission admin-consent grant --id <app-id>
```

**Terraform:**
```bash
# Initialize
terraform init

# Validate configuration
terraform validate

# Plan changes
terraform plan

# Apply changes
terraform apply

# Show outputs
terraform output
```

**Git:**
```bash
# Create feature branch
git checkout -b feature/my-app-registration

# Stage changes
git add deployments/azure/app-registration/

# Commit
git commit -m "Add MyApplication registration"

# Push
git push origin feature/my-app-registration
```

### Links

**Documentation:**
- [Microsoft Graph Permissions Reference](https://learn.microsoft.com/en-us/graph/permissions-reference)
- [Azure AD App Registration Best Practices](https://learn.microsoft.com/en-us/azure/active-directory/develop/security-best-practices-for-app-registration)
- [Terraform AzureAD Provider](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs)

**Repository Files:**
- [Permission Risk Matrix](permission-policies/graph-permissions-risk-matrix.json)
- [Placeholder SP Module](modules/placeholder-service-principal/README.md)
- [Owner Verification Script](scripts/verify-owners.sh)
- [Permission Validation Script](scripts/validate-permissions.sh)

**Workflows:**
- [Approval Workflow](../../.github/workflows/app-registration-approval.yml)
- [Deployment Workflow](../../.github/workflows/app-registration-deploy.yml)
- [Owner Audit Workflow](../../.github/workflows/app-registration-audit.yml)
- [Quarterly Review Workflow](../../.github/workflows/app-registration-placeholder-review.yml)
- [Placeholder Tracking Workflow](../../.github/workflows/app-registration-placeholder-tracking.yml)

---

## Appendix

### Permission IDs Reference

Common Microsoft Graph permission IDs:

| Permission Name | ID | Type | Risk |
|-----------------|-----|------|------|
| User.Read | e1fe6dd8-ba31-4d61-89e7-88639da4683d | Scope | LOW |
| User.ReadWrite.All | 741f803b-c850-494e-b5df-cde7c675a1ca | Role | HIGH |
| Directory.Read.All | 7ab1d382-f21e-4acd-a863-ba3e13f7da61 | Role | MEDIUM |
| Directory.ReadWrite.All | 1bfefb4e-e0b5-418b-a88f-73c46d2cc8e9 | Role | HIGH |
| Application.ReadWrite.All | 1bfefb4e-e0b5-418b-a88f-73c46d2cc8e9 | Role | HIGH |
| Mail.Read | 810c84a8-4a9e-49e6-bf7d-12d183f40d01 | Scope | LOW |
| Mail.ReadWrite.All | e2a3a72e-5f79-4c64-b1b1-878b674786c9 | Role | HIGH |
| Group.ReadWrite.All | 62a82d76-70ea-41e2-9197-370581804d09 | Role | HIGH |

Full list: Run `az ad sp show --id 00000003-0000-0000-c000-000000000000 --query appRoles`

### Change Log

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2024-12-13 | Initial release |

---

**Document Maintained By:** Security & Governance Team  
**Last Updated:** December 13, 2024  
**Next Review:** March 2025 (Quarterly)

For questions or feedback, contact: appsec@company.com
