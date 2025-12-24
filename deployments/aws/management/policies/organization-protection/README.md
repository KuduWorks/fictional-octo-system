# AWS Organization Protection Policy

This module creates a Service Control Policy (SCP) that allows member accounts to view organization structure but prevents them from modifying it. Only the management account can create accounts, modify policies, or change organizational units.

> **Note:** All AWS account IDs used in this documentation (e.g., `<YOUR-MANAGEMENT-ACCOUNT-ID>`) are placeholders. Replace them with your actual AWS account IDs when deploying.

## What This Creates

### Service Control Policy (SCP)
**OrganizationProtection** - Two-part policy for organization governance:

1. **Allow Read-Only Access** - Permits all `organizations:Describe*` and `organizations:List*` actions
   - Member accounts can view organization structure
   - Enables visibility for compliance and auditing
   - Does not grant modification permissions

2. **Deny Organization Modifications** - Blocks all write operations to organization
   - Prevents creating/deleting accounts
   - Blocks policy attachments/detachments
   - Denies OU modifications
   - Management account is exempted via condition

### Enforcement
- Attached at **organization root** level for all member accounts
- Management account retains full organization control
- Immediate blocking of unauthorized organization changes

## Why This Matters

Without this policy, any member account with sufficient IAM permissions could:
- Create new AWS accounts in your organization
- Modify or delete Service Control Policies
- Move accounts between organizational units
- Potentially compromise organization governance

This SCP ensures centralized control over organization structure while maintaining visibility for all accounts.

## Prerequisites

1. **AWS Organizations** - Your account must be part of an AWS Organization
2. **Management Account Access** - Deploy from the management account only
3. **Appropriate Permissions** - `organizations:CreatePolicy` and `organizations:AttachPolicy`

## Verification

Check if you're in an organization:

```bash
aws organizations describe-organization
```

If you see organization details, you're ready to deploy.

## Usage

### 1. Copy Example Files

```bash
cd deployments/aws/policies/organization-protection

# Copy terraform.tfvars example
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
# Update management_account_id with your 12-digit AWS account ID
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Review Changes

```bash
terraform plan
```

### 4. Deploy the Policy

```bash
terraform apply
```

### 5. Verify Deployment

```bash
# List all SCPs in your organization
aws organizations list-policies --filter SERVICE_CONTROL_POLICY

# Check if policy is attached to root
aws organizations list-policies-for-target \
  --target-id <YOUR-ORG-ROOT-ID> \
  --filter SERVICE_CONTROL_POLICY
```

## Testing the Policy

### From Management Account (Should Succeed)

```bash
# Management account can still manage organization
aws organizations list-accounts
aws organizations describe-organization

# Can create organizational units (if needed)
aws organizations list-organizational-units-for-parent \
  --parent-id <YOUR-ORG-ROOT-ID>
```

### From Member Account (Read Works, Write Fails)

```bash
# Assume role in member account first
aws sts assume-role \
  --role-arn arn:aws:iam::<YOUR-MEMBER-ACCOUNT-ID>:role/CrossAccountTestRole \
  --role-session-name test-session \
  --external-id <YOUR-EXTERNAL-ID>

# Export credentials, then test...

# ✅ Read operations should SUCCEED
aws organizations describe-organization
aws organizations list-accounts

# ❌ Write operations should FAIL with AccessDenied
aws organizations create-organizational-unit \
  --parent-id <YOUR-ORG-ROOT-ID> \
  --name TestOU
# Expected: AccessDenied - Service control policy restricts this action

aws organizations create-account \
  --email test@example.com \
  --account-name TestAccount
# Expected: AccessDenied - Service control policy restricts this action
```

## Policy Scope

### Allowed Actions (All Accounts)
- `organizations:Describe*` - View organization details
- `organizations:List*` - List accounts, OUs, policies

### Denied Actions (Member Accounts Only)
- Account management (Create, Remove, Move)
- Policy management (Create, Update, Delete, Attach, Detach)
- OU management (Create, Update, Delete)
- Organization settings (Enable features, AWS service access)
- Delegated administrator changes

### Exempted (Management Account)
- All organization operations allowed
- No restrictions via condition exclusion

## Important Notes

### 1. Management Account Bypass
**The management account always bypasses SCPs.** This is by AWS design to prevent lockout. The policy uses a condition to explicitly allow management account operations.

### 2. SCP Propagation Time
After deploying, allow **5-15 minutes** for the policy to propagate globally before testing.

### 3. Testing from Correct Account
- ✅ Test from member account via assumed role
- ❌ Testing from management account gives false results (SCPs don't apply)

### 4. Read-Only Visibility
Member accounts can still see organization structure, which may reveal account names and IDs. If complete isolation is needed, deny all `organizations:*` actions instead.

## Compliance Mapping

This policy helps meet several compliance requirements:

| Framework | Control | Mapping |
|-----------|---------|---------|
| **ISO 27001** | A.9.2.3 - Management of privileged access rights | Restricts privileged organization operations |
| **NIST 800-53** | AC-2 - Account Management | Centralizes account creation/deletion |
| **CIS AWS Foundations** | 1.1 - Maintain current contact details | Prevents unauthorized account modifications |
| **SOC 2** | CC6.1 - Logical and physical access controls | Enforces least privilege for organization access |

## Backend Configuration

After deploying with local state, migrate to remote state:

```bash
# Copy backend example
cp backend.tf.example backend.tf

# Edit backend.tf with your state bucket name
# (Get bucket name from terraform-state-bootstrap outputs)

# Migrate state to S3
terraform init -migrate-state
```

## Troubleshooting

### Error: "AWSOrganizationsNotInUseException"
You're not in an AWS Organization. Create one first or use an alternative approach.

### Error: "PolicyTypeNotEnabledException"
Service Control Policies are not enabled. Enable them:
```bash
aws organizations enable-policy-type \
  --root-id <YOUR-ORG-ROOT-ID> \
  --policy-type SERVICE_CONTROL_POLICY
```

### Error: "AccessDeniedException"
You don't have permissions to create SCPs. Ensure you're deploying from the management account with appropriate IAM permissions.

### Member Account Can Still Modify Organization
- Wait 5-15 minutes for SCP propagation
- Verify you're testing from member account (not management account)
- Check policy is attached: `aws organizations list-policies-for-target --target-id <MEMBER-ACCOUNT-ID> --filter SERVICE_CONTROL_POLICY`

### Management Account Operations Blocked
If management account operations fail, verify the condition in the SCP properly excludes your management account ID.

## Cleanup

To remove the organization protection policy:

```bash
terraform destroy
```

**⚠️ Warning:** This removes organization governance controls. Member accounts will regain ability to modify organization structure if they have IAM permissions.

## Related Modules

- [region-control](../region-control/) - Restricts resource creation to approved regions
- [encryption-baseline](../encryption-baseline/) - Enforces encryption and blocks public access
- [cross-account-role](../../iam/cross-account-role/) - For testing SCPs from member accounts

## Cost

Service Control Policies are **free**. There is no charge for creating or attaching SCPs.

## Security Best Practices

1. ✅ **Deploy from management account only**
2. ✅ **Test enforcement from member account**
3. ✅ **Monitor CloudTrail for denied organization operations**
4. ✅ **Review policy attachments regularly**
5. ✅ **Document exempted accounts if you add more conditions**
6. ✅ **Combine with other SCPs for defense in depth**

## Support

For issues or questions:
- Review [AWS Organizations SCPs documentation](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html)
- Check [AWS Organizations troubleshooting guide](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_troubleshoot.html)
- Open an issue in the repository
