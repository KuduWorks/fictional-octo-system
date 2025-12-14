# App Registration Owner Governance

## Overview

This directory contains the governance-approved list of users authorized to own Azure Entra ID app registrations and enterprise applications. Only users listed in `allowed-owners.json` can be designated as owners in the approval workflow.

## Purpose

**Why restrict ownership?**
- **Accountability:** Small, defined list of responsible governance/security personnel
- **Security:** Owners have significant privileges over identity and access
- **Compliance:** Ensures proper oversight and access controls
- **Auditability:** Clear chain of responsibility for app registration lifecycle

## Approved Owner Requirements

Users on the approved owner list must:

1. **Hold appropriate Entra ID administrative roles:**
   - Security Administrator
   - Application Administrator
   - Cloud Application Administrator
   - Global Administrator
   - Identity Governance Administrator
   - Privileged Role Administrator

2. **Be part of governance/security teams:**
   - Information Security
   - IT Operations (Identity Management)
   - Governance, Risk & Compliance
   - Security Architecture

3. **Maintain active employment and enabled accounts**

4. **Complete security awareness training** (if required by organization)

## Process

### Adding a New Approved Owner

**Prerequisites:**
- User must hold appropriate Entra ID admin role
- Business justification required
- CISO or Security Leadership approval

**Steps:**

1. **Create Pull Request**
   ```bash
   git checkout -b governance/add-approved-owner-<name>
   ```

2. **Edit `allowed-owners.json`:**
   ```json
   {
     "email": "new-owner@example.com",
     "role": "Security Administrator",
     "team": "Information Security",
     "added_date": "2025-12-14",
     "justification": "Dedicated security lead for identity governance initiatives. Responsible for app registration lifecycle management and compliance oversight."
   }
   ```

3. **Submit PR with:**
   - CISO approval email/ticket
   - Verification of Entra ID admin role assignment
   - Business justification for governance responsibilities
   - Reference to job role/responsibilities

4. **Security leadership review** (typically 2-4 weeks)

5. **Merge after approval**

### Removing an Approved Owner

**When to remove:**
- Employment termination
- Role change
- Prolonged absence (>6 months)
- Account disabled

**Steps:**

1. **Identify successor owner** for existing app registrations

2. **Create Pull Request** to remove user from list

3. **Document:**
   - Reason for removal
   - Successor owner(s) identified
   - Any app registrations requiring owner updates

4. **30-day notice period** (unless emergency termination)

5. **Update all app registrations** to replace removed owner

## File Structure

```
config/
├── README.md                # This file
└── allowed-owners.json      # Governance-approved owner list
```

## Validation

The `verify-owners.sh` script automatically validates that all human owners specified in app registration Terraform files are present in the approved owner list.

**Validation checks:**
- Owner email matches entry in `allowed-owners.json`
- Owner account is enabled in Entra ID
- Minimum owner requirements met (≥2 total, ≥1 human)

**Example validation output:**
```
👥 Verifying app registration owners...
📂 Scanning: deployments/azure/app-registration/
🔐 Governance: 5 approved owner(s)

🔍 Verifying: security-admin@example.com
  ✓ Type: User
  ✓ Display Name: Security Admin
  ✓ Object ID: 12345678-1234-1234-1234-123456789012
  ✓ Governance: Approved owner
  ✓ Status: Enabled

✅ All owner validations passed
```

## Emergency Access

For emergency situations requiring immediate app registration changes when approved owners are unavailable:

1. **Follow break-glass procedures** (see Security Runbook)
2. **Use emergency access accounts** (if available)
3. **Document in incident ticket**
4. **Submit retroactive governance approval** within 24 hours
5. **Replace emergency owners** with approved owners within 7 days

## Audit and Review

**Quarterly reviews:**
- Q1, Q3: Verify all approved owners still active and in appropriate roles
- Q2, Q4: Full access review with removal of inactive/inappropriate owners

**Review criteria:**
- Account still enabled
- User still in governance/security role
- No prolonged absences
- Continued need for governance responsibilities

## Examples

### Typical Approved Owner List Size

**Small organizations (< 500 users):** 3-5 approved owners
**Medium organizations (500-5000 users):** 5-8 approved owners
**Large organizations (> 5000 users):** 8-15 approved owners

Keep the list as small as practical to maintain accountability.

### Sample Approved Owner

```json
{
  "email": "security-admin@example.com",
  "role": "Security Administrator",
  "team": "Information Security",
  "added_date": "2025-01-15",
  "justification": "Primary security owner for identity governance. Responsible for app registration approval workflow, quarterly reviews, and security compliance audits. Entra ID Security Administrator role assigned. 8+ years experience in identity management."
}
```

## Support

**Questions about approved owner list:**
- Contact: Security Architecture Team
- Email: security-architecture@example.com
- Slack: #security-governance

**Request to be added as approved owner:**
- Process: See "Adding a New Approved Owner" above
- Approval authority: CISO or Security Leadership
- Typical timeline: 2-4 weeks

## References

- [Entra ID administrative roles](https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/permissions-reference)
- [App registration best practices](https://learn.microsoft.com/en-us/entra/identity-platform/security-best-practices-for-app-registration)
- Internal Security Policy: Identity Governance (LINK-TO-INTERNAL-POLICY)
