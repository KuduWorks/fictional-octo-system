# GitHub Workflows - Governance List Integration Updates

## Overview

Updated all GitHub Actions workflows to properly handle and communicate the new governance-approved owner list requirement. The workflows now detect, report, and remediate governance violations in addition to existing owner validation checks.

## Workflows Updated

### 1. app-registration-approval.yml (PR Validation)

**File:** `.github/workflows/app-registration-approval.yml`

**Changes:**
- ✅ Already calls updated `verify-owners.sh` (includes governance validation)
- ✅ Enhanced PR comment to show governance approval status
- ✅ Added governance-specific error messaging when validation fails

**New Features:**

**PR Comment Enhancements:**
```
### 👥 Owner Verification

✅ PASSED

- Total Owners: 2
- Human Owners: 2 (from approved governance list) ← NEW
- Placeholder SPs: 0

Verified Owners:
- ✅ 12345678-... (user) - Enabled | 🔒 Approved governance user ← NEW
- ✅ 87654321-... (user) - Enabled | 🔒 Approved governance user ← NEW
```

**Governance Violation Error Box:**
When owners fail governance check, PR comment includes:
```
❌ FAILED

Errors:
- ⚠️ User not on approved governance owner list: random-user@example.com

> 🔒 Governance Requirement: All human owners must be from the approved list.
> See: `deployments/azure/app-registration/config/allowed-owners.json`
> 
> To view approved owners: `cat config/allowed-owners.json | jq '.allowed_owners.users[].email'`
> 
> Not on the list? Submit PR with CISO approval. See `config/README.md`
```

**Impact:** Developers immediately see governance requirements and how to resolve violations.

---

### 2. app-registration-deploy.yml (Deployment)

**File:** `.github/workflows/app-registration-deploy.yml`

**Changes:**
- ✅ Already runs `verify-owners.sh` in pre-deployment validation
- ✅ Enhanced to detect and log governance violations specifically
- ✅ Blocks deployment when governance violations detected

**New Pre-Deployment Validation:**
```yaml
- name: Run pre-deployment owner verification
  run: |
    echo "🔒 Verifying owners against approved governance list..."
    
    # Check for governance violations specifically
    GOVERNANCE_ERRORS=$(echo "$VERIFICATION_OUTPUT" | jq -r '.validation_errors[] | select(contains("not on approved governance owner list"))')
    if [ -n "$GOVERNANCE_ERRORS" ]; then
      echo "::error::🔒 GOVERNANCE VIOLATION: Owners not on approved list"
      echo "::error::See: deployments/azure/app-registration/config/allowed-owners.json"
    fi
```

**Error Output:**
```
Error: 🔒 GOVERNANCE VIOLATION: Owners not on approved list
Error: See: deployments/azure/app-registration/config/allowed-owners.json
Error: User not on approved governance owner list: user@example.com
```

**Impact:** Deployments blocked if governance violations detected, with clear error messages pointing to approved list.

---

### 3. app-registration-audit.yml (Daily Owner Audit)

**File:** `.github/workflows/app-registration-audit.yml`

**Major Changes:**

#### A. New Output Variable
```yaml
outputs:
  drift_detected: ${{ steps.detect-drift.outputs.drift_detected }}
  disabled_owners_found: ${{ steps.detect-drift.outputs.disabled_owners_found }}
  grace_period_expired: ${{ steps.detect-drift.outputs.grace_period_expired }}
  governance_violations: ${{ steps.detect-drift.outputs.governance_violations }}  # NEW
```

#### B. Governance Violation Detection
```bash
# Check for governance violations (owners not on approved list)
GOVERNANCE_ERRORS=$(echo "$VERIFICATION_OUTPUT" | jq -r '.validation_errors[] | select(contains("not on approved governance owner list"))')

if [ -n "$GOVERNANCE_ERRORS" ]; then
  echo "governance_violations=true" >> $GITHUB_OUTPUT
  echo "::error::Governance violations detected - owners not on approved list"
else
  echo "governance_violations=false" >> $GITHUB_OUTPUT
fi
```

#### C. Enhanced Drift Report
Drift report now includes governance violations section:

```markdown
### 🚫 Governance Violations Detected

The following owners are NOT on the approved governance/security list:

- User not on approved governance owner list: user@example.com
- User not on approved governance owner list: another-user@example.com

⚠️ IMMEDIATE ACTION REQUIRED: Only users from the approved governance list can own app registrations.

**Approved owner list:** `deployments/azure/app-registration/config/allowed-owners.json`

**Options:**
1. Replace with approved owner from governance list
2. Submit PR to add user to approved list (requires CISO approval)

See `config/README.md` for the approval process.
```

#### D. New Governance Violation Notification
Separate GitHub issue created for governance violations:

```yaml
- name: Send governance violation notification
  if: steps.detect-drift.outputs.governance_violations == 'true'
  uses: actions/github-script@v7
```

**Issue Created:**
```
Title: 🚫 App Registration Governance Violation - Action Required

Labels: app-registration, governance-violation, security, urgent

Body:
## 🚫 App Registration Governance Violation

**Audit Date:** 2025-12-14
**Status:** ⚠️ GOVERNANCE POLICY VIOLATION

One or more app registration owners are NOT on the approved governance/security list.

### Governance Requirement
Only users from the approved governance list can own app registrations.
**Approved list:** `deployments/azure/app-registration/config/allowed-owners.json`

### Action Required
Choose ONE of the following options:

1. Replace with approved owner (recommended):
   - Select owner from approved governance list
   - Create PR to update app registration configuration
   - Deploy changes

2. Add user to approved list (requires executive approval):
   - Submit PR to `config/allowed-owners.json`
   - Include CISO approval documentation
   - Typical approval time: 2-4 weeks
   - See `config/README.md` for process

### Security Impact
App registrations with unapproved owners are non-compliant with security policy.
Access may be restricted if not resolved promptly.
```

**Impact:** Immediate visibility into governance violations with actionable remediation steps.

---

## Workflow Validation Flow

### Before (Original):
```
PR Created → Owner Verification (≥2 owners, ≥1 human, ≤1 placeholder)
          → Permission Validation (HIGH/MEDIUM/LOW risk)
          → Terraform Validate & Plan
          → 2 Reviewers Approve
          → Deploy
```

### After (With Governance):
```
PR Created → Owner Verification (≥2 owners, ≥1 human, ≤1 placeholder, ALL from approved list ✓)
          → Permission Validation (HIGH/MEDIUM/LOW risk)
          → Terraform Validate & Plan
          → 2 Reviewers Approve
          → Deploy with governance pre-check ✓
          
Daily Audit → Detect drift (disabled owners + governance violations ✓)
           → Send notifications (separate for governance violations ✓)
           → Create remediation PR
```

## Error Handling Matrix

| Scenario | Detection | Notification | Remediation |
|----------|-----------|--------------|-------------|
| **Owner not on approved list** | ✅ PR validation<br>✅ Pre-deployment<br>✅ Daily audit | ❌ PR comment<br>🚫 GitHub issue<br>📧 Optional email | Manual PR to replace owner |
| **Owner account disabled** | ✅ PR validation<br>✅ Daily audit | ⚠️ Day 0 alert<br>🚨 Day 7 escalation | Auto-remediation PR (draft) |
| **<2 total owners** | ✅ PR validation<br>✅ Terraform precondition | ❌ PR comment<br>🔴 Deployment blocked | Manual PR to add owners |
| **0 human owners** | ✅ PR validation<br>✅ Terraform precondition | ❌ PR comment<br>🔴 Deployment blocked | Manual PR to add human owner |
| **>1 placeholder** | ✅ PR validation<br>✅ Quarterly review | ❌ PR comment<br>📅 Q2/Q4 leadership email | Manual PR to remove placeholders |

## Testing Scenarios

### Test 1: Owner Not on Approved List (PR Validation)

**Setup:**
```hcl
app_owners = [
  "random-user@example.com"  # Not on approved list
]
```

**Expected:**
- ❌ PR validation fails
- PR comment shows governance error with help text
- Deployment blocked

**Verify:**
```bash
# Check PR workflow logs
gh run view <run-id>

# Look for:
# - "::error::User not on approved governance owner list"
# - PR comment with governance guidance
```

### Test 2: Governance Violation (Daily Audit)

**Setup:**
- Deploy app registration with unapproved owner (bypass validation for test)
- Wait for daily audit (9 AM UTC) or trigger manually

**Trigger Manually:**
```bash
gh workflow run app-registration-audit.yml
```

**Expected:**
- 🚫 GitHub issue created: "App Registration Governance Violation"
- Drift report includes governance violations section
- Issue labeled: `governance-violation`, `security`, `urgent`

**Verify:**
```bash
# Check audit workflow logs
gh run view <run-id>

# Check for created issue
gh issue list --label governance-violation

# Verify issue contains:
# - Approved owner list path
# - Remediation options (replace vs add to list)
# - CISO approval requirement mentioned
```

### Test 3: Deploy with Governance Validation

**Setup:**
```hcl
app_owners = [
  "security-admin@example.com",  # On approved list
  "identity-admin@example.com"   # On approved list
]
```

**Expected:**
- ✅ Pre-deployment validation passes
- 🔒 Log shows "Verifying owners against approved governance list..."
- Deployment proceeds successfully

**Verify:**
```bash
# Check deploy workflow logs
gh run view <run-id>

# Look for:
# - "::notice::Pre-deployment owner verification passed"
# - No governance errors
```

## Configuration Files

Workflows now read from:
- `deployments/azure/app-registration/config/allowed-owners.json` (via verify-owners.sh)

Workflows reference in error messages:
- `deployments/azure/app-registration/config/README.md` (governance process documentation)

## Monitoring and Alerts

### Alert Types

1. **PR Validation Failure** → PR comment (immediate)
2. **Governance Violation** → GitHub issue (immediate)
3. **Day 0 Disabled Owner** → GitHub issue (grace period)
4. **Day 7 Expired Grace Period** → GitHub issue with escalation

### Issue Labels

- `governance-violation` - Owner not on approved list
- `drift-detected` - Any drift detected
- `grace-period` - Disabled owner within 7 days
- `grace-period-expired` - Disabled owner >7 days
- `security` - Security-related issue
- `urgent` - Requires immediate attention

### Future Enhancements

Potential additions:
- 📧 Email notifications via Azure Communication Services for governance violations
- 📊 Metrics dashboard showing governance compliance rate
- 🤖 Automated PR to suggest approved owner replacements
- 🔔 Slack/Teams notifications for security team
- 📅 Monthly governance compliance report

## Rollback Procedure

If governance enforcement causes issues:

1. **Temporarily disable governance check in verify-owners.sh:**
   ```bash
   # Comment out governance validation section
   # Lines ~75-85 in verify-owners.sh
   ```

2. **Bypass validation (emergency only):**
   ```bash
   gh workflow run app-registration-deploy.yml \
     -f skip_validation=true
   ```

3. **Revert workflows to previous version:**
   ```bash
   git revert <commit-hash>
   ```

## Summary

✅ **app-registration-approval.yml** - Enhanced PR comments with governance status
✅ **app-registration-deploy.yml** - Pre-deployment governance checks with clear errors
✅ **app-registration-audit.yml** - Governance violation detection, reporting, and dedicated notifications

All workflows now:
- Detect governance violations via updated `verify-owners.sh`
- Provide clear error messages referencing `config/allowed-owners.json`
- Guide users to `config/README.md` for approval process
- Create separate notifications for governance vs disabled owner issues
- Block deployments when governance violations detected

The governance requirement is now fully integrated into the CI/CD pipeline with appropriate guardrails and clear remediation paths.

---

*Last Updated: 2025-12-14*
*Workflows validated and ready for production use*
