# Placeholder Service Principal Module

## Purpose

Creates a **zero-permission service principal** to satisfy the 2-owner minimum requirement when human owners are temporarily unavailable. This follows the **zero-trust principle**: the placeholder has NO API permissions and cannot access any resources.

## Zero-Trust Design

- ✅ **Zero API permissions** - No `required_resource_access` blocks
- ✅ **No interactive sign-in** - `sign_in_audience = "AzureADMyOrg"` only
- ✅ **App role assignment required** - Prevents accidental usage
- ✅ **No enterprise/gallery features** - Cannot be shared
- ✅ **Audit trail** - Justification stored in application notes
- ✅ **Quarterly review** - Flagged for Q2/Q4 first Monday review
- ✅ **6-month escalation** - Leadership review if placeholder persists

## When to Use

Use this module **ONLY** when:
1. Application registration is needed urgently for business operations
2. Second human owner is not yet identified/available
3. You have a substantive 50+ character justification
4. You commit to replacing the placeholder with a human owner ASAP

## When NOT to Use

❌ **DO NOT** use this module for:
- Convenience (finding 2nd owner is "too hard")
- Service accounts that should be managed identities instead
- Long-term ownership (>6 months triggers escalation)
- Bypassing security reviews

## Usage Example

```hcl
# Create placeholder service principal
module "placeholder_owner" {
  source = "./modules/placeholder-service-principal"
  
  placeholder_name = "PLACEHOLDER-MyApp-Owner-Temporary"
  
  justification = <<-EOT
    Second owner temporarily unavailable during org restructure. 
    Marketing team lead (john.doe@company.com) will be added as owner 
    by end of Q2 2024 when team assignments finalize. Application needed 
    immediately to support product launch scheduled for March 15, 2024.
    Approved by Director of Engineering (jane.smith@company.com).
  EOT
  
  created_by_workflow = "github-actions-manual-approval"
  
  tags = [
    "department:marketing",
    "project:product-launch-2024"
  ]
}

# Use placeholder in app registration
module "my_app" {
  source = "../"
  
  app_name = "MyApplication"
  
  app_owners = [
    "user-object-id-1@entra-directory",  # Human owner
    module.placeholder_owner.service_principal_id  # Temporary placeholder
  ]
  
  placeholder_owner_justification = module.placeholder_owner.justification
  
  # ... rest of app registration config
}
```

## Validation Rules

The module enforces strict validation:

### Justification Requirements
- ✅ **Minimum 50 characters** - Forces substantive explanation
- ✅ **Maximum 2000 characters** - Fits in Azure AD notes field
- ✅ **No placeholder text** - Rejects "test", "temp", "todo", "tbd", "n/a"
- ✅ **No injection attacks** - Blocks `<`, `>`, `"`, `'`, `&` characters
- ✅ **Must be meaningful** - Will be reviewed quarterly by security team

### Name Requirements
- ✅ **Must contain "placeholder"** - Clear identification (case-insensitive)
- ✅ **10-120 characters** - Fits Azure AD display name limits

## Quarterly Review Process

Every **Q2 and Q4 first Monday** (or next business day if Monday is holiday/weekend):

1. **Automated scan** identifies all placeholder service principals
2. **Age calculation** determines how long placeholder has existed
3. **Under 6 months**: Email reminder to app registration owner
   - Action required: Replace placeholder with human owner
   - Include original justification for context
4. **Over 6 months**: Escalate to leadership team
   - Triggers executive review workflow
   - May result in application decommission if owners unavailable

## Audit Trail

All placeholders store comprehensive audit information:

```json
{
  "purpose": "Placeholder owner for 2-owner minimum requirement",
  "justification": "Your 50+ character justification",
  "justification_length": 85,
  "created_date": "2024-03-15T10:30:00Z",
  "quarterly_review": "Required on Q2 and Q4 first Monday",
  "escalation_policy": "Escalate to leadership if placeholder exists >6 months",
  "zero_permissions": true,
  "created_by_workflow": "github-actions-manual-approval"
}
```

## Identifying Placeholders

Placeholders are tagged for easy identification:

```bash
# Find all placeholder service principals
az ad sp list --query "[?tags[?contains(@, 'purpose:placeholder-owner')]]" --output table

# Get placeholder details
az ad sp show --id <service-principal-id> --query "{displayName:displayName, createdDateTime:createdDateTime, tags:tags}"
```

## Removal Process

When human owner becomes available:

1. **Add human owner** to app registration
2. **Remove placeholder** from `app_owners` list
3. **Delete placeholder SP** (module will handle cleanup)
4. **Update PR** with justification: "Replaced placeholder with [human owner name/email]"

## Security Considerations

### Why Zero Permissions?

If a placeholder service principal has ANY permissions, it creates security risks:
- **Credential compromise**: If SP credentials leaked, attacker gains permissions
- **Forgotten cleanup**: High-permission placeholders that persist >6 months
- **Least privilege violation**: Placeholder should do nothing except exist as owner

### Why Not Use a Shared Placeholder?

Each app registration gets its own placeholder because:
- **Audit trail**: Per-app justification required for quarterly reviews
- **Accountability**: Creator tracked per placeholder for escalation
- **Cleanup isolation**: Deleting one placeholder doesn't affect other apps
- **Blast radius**: If one justification expires, others unaffected

## Terraform State Considerations

Placeholders are stored in Terraform state:
- **State file contains**: Application ID, service principal ID, justification
- **Justification is NOT sensitive**: It's audit trail, not credentials
- **Created date tracked**: Used for 6-month escalation calculation

## Examples of Good Justifications

✅ **Good** (substantive, specific, timeline):
```
Second owner John Doe (john.doe@company.com) is on parental leave until April 2024. 
Application needed for Q1 product launch. Jane Smith (jane.smith@company.com) approved 
as temporary sole human owner. John will be re-added as owner upon return. 
Approved by VP Engineering (exec@company.com).
```

❌ **Bad** (too short, vague):
```
Need second owner later
```

❌ **Bad** (placeholder text):
```
TODO: Add real justification after approval
```

❌ **Bad** (no timeline):
```
Can't find second owner right now
```

## Module Outputs

| Output | Description | Usage |
|--------|-------------|-------|
| `service_principal_id` | Object ID of placeholder SP | Add to `app_owners` list |
| `justification` | Stored justification | Reference in app registration |
| `created_date` | Timestamp | Quarterly review age calculation |
| `notes` | Full audit trail JSON | Reporting and compliance |

## Compliance and Governance

This module supports:
- ✅ **Zero-trust architecture** - No permissions by default
- ✅ **Audit requirements** - Full justification trail
- ✅ **Quarterly reviews** - Automated reminders and escalation
- ✅ **Least privilege** - Placeholder can do nothing except exist
- ✅ **Accountability** - Creator and workflow tracked
- ✅ **Time-bounded** - 6-month hard limit before escalation

## Support and Issues

For questions about placeholder service principals:
1. Review this README
2. Check quarterly review workflow documentation
3. Contact security team for justification guidance
4. Escalate to leadership if placeholder needed >6 months

## See Also

- [Approval Workflow Documentation](../../APPROVAL_WORKFLOW.md)
- [Quarterly Review Workflow](.github/workflows/app-registration-placeholder-review.yml)
- [Owner Verification Script](../../scripts/verify-owners.sh)
