# GCP Organization Verification Guide

This guide provides verification commands to confirm your GCP Organization is properly configured with Cloud Identity, external M365 accounts, and break-glass access.

## Prerequisites Checklist

Before verifying, ensure you've completed:
- ✅ Cloud Identity Free signup
- ✅ Added M365 account as external user with Organization Admin role
- ✅ Created native break-glass account with randomized name
- ✅ Linked billing account to organization

## Verification Steps

### Step 1: Verify Organization Exists

**Check organization is created**:

```bash
# List all organizations you have access to
gcloud organizations list

# Expected output:
# DISPLAY_NAME              ID            DIRECTORY_CUSTOMER_ID
# <YOUR-DOMAIN>             <ORG-ID>      <DIRECTORY-CUSTOMER-ID>
```

**Get organization details**:

```bash
# Store organization ID for subsequent commands
ORG_ID=$(gcloud organizations list --format="value(ID)")
echo "Organization ID: $ORG_ID"

# Get full organization information
gcloud organizations describe $ORG_ID

# Expected output:
# creationTime: '2025-12-29T...'
# displayName: <YOUR-DOMAIN>
# name: organizations/<ORG-ID>
# owner:
#   directoryCustomerId: <DIRECTORY-CUSTOMER-ID>
# state: ACTIVE
```

**Verify organization state**:

```bash
# Organization must be ACTIVE
gcloud organizations describe $ORG_ID --format="value(state)"

# Expected: ACTIVE
```

### Step 2: Verify M365 External Account Access

**Test authentication with M365 credentials**:

```bash
# Sign out current account
gcloud auth revoke --all

# Authenticate with M365 account
gcloud auth login <YOUR-ADMIN-EMAIL>

# Browser will open → Microsoft login page
# Use your Microsoft 365 password and MFA
# GCP will redirect to: https://login.microsoftonline.com/...

# After successful auth, verify active account
gcloud auth list

# Expected output:
#              Credentialed Accounts
# ACTIVE  ACCOUNT
# *       <YOUR-ADMIN-EMAIL>
```

**Verify organization admin permissions**:

```bash
# List organizations (should see your org)
gcloud organizations list

# Get IAM policy to confirm your permissions
gcloud organizations get-iam-policy $ORG_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:<YOUR-ADMIN-EMAIL>" \
  --format="table(bindings.role)"

# Expected roles:
# roles/resourcemanager.organizationAdmin
# roles/billing.admin (optional)
```

**Test organization-level operations**:

```bash
# Try listing all projects in the organization
gcloud projects list --organization=$ORG_ID

# Try viewing organization IAM policy
gcloud organizations get-iam-policy $ORG_ID

# Both should succeed without permission errors
```

### Step 3: Verify Break-Glass Account

**Option A: If using Cloud Identity native account**:

```bash
# Sign out M365 account
gcloud auth revoke --all

# Authenticate with break-glass account
gcloud auth login breakglass-<RANDOM>@<YOUR-DOMAIN>

# Use the password stored in Azure Key Vault
# Complete 2FA challenge

# Verify active account
gcloud auth list

# Expected:
# *       breakglass-<RANDOM>@<YOUR-DOMAIN>

# Verify organization access
gcloud organizations list
gcloud organizations describe $ORG_ID

# Verify admin permissions
gcloud organizations get-iam-policy $ORG_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:breakglass-<RANDOM>@<YOUR-DOMAIN>" \
  --format="table(bindings.role)"

# Expected:
# roles/resourcemanager.organizationAdmin
# roles/iam.organizationRoleAdmin
```

**Option B: If using service account break-glass**:

```bash
# Retrieve service account key from Azure Key Vault
az keyvault secret show \
  --vault-name <YOUR-KEYVAULT> \
  --name "gcp-breakglass-sa-key" \
  --query value -o tsv > breakglass-key.json

# Activate service account
gcloud auth activate-service-account \
  breakglass-admin@<PROJECT-ID>.iam.gserviceaccount.com \
  --key-file=breakglass-key.json

# Verify active account
gcloud auth list

# Expected:
# *       breakglass-admin@<PROJECT-ID>.iam.gserviceaccount.com

# Verify organization access
gcloud organizations list

# Clean up key file
rm breakglass-key.json
```

### Step 4: Verify Billing Account Linkage

**Check billing account exists**:

```bash
# List all billing accounts
gcloud billing accounts list

# Expected output:
# ACCOUNT_ID            NAME                OPEN  MASTER_ACCOUNT_ID
# <BILLING-ACCOUNT-ID>  Billing Account 1   True

# Get billing account details
gcloud billing accounts describe <BILLING-ACCOUNT-ID>
```

**Verify billing permissions**:

```bash
# Check who has access to billing account
gcloud billing accounts get-iam-policy <BILLING-ACCOUNT-ID>

# Should include:
# - <YOUR-ADMIN-EMAIL> with roles/billing.admin
# - Organization admins with billing access
```

**Test billing account assignment**:

```bash
# When creating new projects, verify billing can be linked
gcloud projects create test-billing-check-001 \
  --organization=$ORG_ID \
  --labels=environment=test,purpose=verification

# Link billing to test project
gcloud billing projects link test-billing-check-001 \
  --billing-account=<BILLING-ACCOUNT-ID>

# Verify billing is enabled
gcloud billing projects describe test-billing-check-001

# Clean up test project
gcloud projects delete test-billing-check-001 --quiet
```

### Step 5: Verify Service Account Strategy

**Check existing service accounts**:

```bash
# List service accounts in current project
gcloud iam service-accounts list

# Expected (from existing deployments):
# main-github-actions@<PROJECT-ID>.iam.gserviceaccount.com
# terraform-automation@<PROJECT-ID>.iam.gserviceaccount.com
```

**Verify Workload Identity Pool**:

```bash
# List workload identity pools
gcloud iam workload-identity-pools list \
  --location=global \
  --project=<PROJECT-ID>

# Expected:
# github-actions-pool

# Get pool details
gcloud iam workload-identity-pools describe github-actions-pool \
  --location=global \
  --project=<PROJECT-ID>
```

**Verify no long-lived service account keys** (security best practice):

```bash
# Check for service account keys (should be minimal)
gcloud iam service-accounts keys list \
  --iam-account=main-github-actions@<PROJECT-ID>.iam.gserviceaccount.com

# Should only show system-managed keys, no user-managed keys
# Expected:
# KEY_ID                                    CREATED_AT            EXPIRES_AT            KEY_TYPE
# abc123...                                 2025-12-29T...        2025-01-05T...        SYSTEM_MANAGED

# User-managed keys indicate manual key creation (avoid this)
```

### Step 6: Verify Cloud Identity Configuration

**Check Cloud Identity users**:

```bash
# Note: Cloud Identity user management requires Cloud Identity API or Admin Console
# Verify via Admin Console: https://admin.google.com/ac/users

# Alternative: Check organization IAM policy for user list
gcloud organizations get-iam-policy $ORG_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:user*" \
  --format="value(bindings.members)" | sort -u

# Expected users:
# user:<YOUR-ADMIN-EMAIL>
# user:breakglass-<RANDOM>@<YOUR-DOMAIN>
```

**Verify external identity configuration**:

```bash
# Check if M365 domain is NOT verified in GCP (it shouldn't be)
gcloud domains verify <YOUR-DOMAIN> 2>&1 | grep "not verified"

# Expected: Error message indicating domain is not verified
# This is CORRECT - we're using external identity, not domain verification
```

### Step 7: Verify Regional Configuration

**Check default region settings**:

```bash
# View current gcloud configuration
gcloud config list

# Expected region: europe-north1 (Finland)
# compute/region: europe-north1

# Set default region if not configured
gcloud config set compute/region europe-north1
gcloud config set compute/zone europe-north1-a
```

**Verify no resource location restrictions yet**:

```bash
# List organization policies (should be empty initially)
gcloud resource-manager org-policies list --organization=$ORG_ID

# Expected: Empty or minimal policies
# Organization policies will be implemented in next phase
```

## Verification Summary

After running all commands, you should have confirmed:

| Component | Status | Command |
|-----------|--------|---------|
| ✅ Organization exists | ACTIVE | `gcloud organizations list` |
| ✅ M365 account access | Working | `gcloud auth login <YOUR-ADMIN-EMAIL>` |
| ✅ Break-glass account | Working | `gcloud auth login breakglass-<RANDOM>@<YOUR-DOMAIN>` |
| ✅ Organization Admin IAM | Granted | `gcloud organizations get-iam-policy` |
| ✅ Billing account linked | Active | `gcloud billing accounts list` |
| ✅ Service accounts exist | Configured | `gcloud iam service-accounts list` |
| ✅ Workload Identity Pool | Active | `gcloud iam workload-identity-pools list` |
| ✅ Default region | europe-north1 | `gcloud config list` |

## Common Issues and Solutions

### Issue 1: Organization Not Found

**Symptom**:
```bash
gcloud organizations list
# Listed 0 items.
```

**Solutions**:
1. Ensure you completed Cloud Identity Free signup
2. Create at least one GCP project to trigger organization creation:
   ```bash
   gcloud projects create temp-org-trigger-001
   gcloud organizations list  # Should now show organization
   ```
3. Check you're authenticated with the correct account:
   ```bash
   gcloud auth list
   ```

### Issue 2: M365 Account Has No Permissions

**Symptom**:
```bash
gcloud organizations get-iam-policy $ORG_ID
# Error: Permission denied
```

**Solutions**:
1. Re-authenticate with account that created organization
2. Grant permissions to M365 account:
   ```bash
   gcloud organizations add-iam-policy-binding $ORG_ID \
     --member="user:<YOUR-ADMIN-EMAIL>" \
     --role="roles/resourcemanager.organizationAdmin"
   ```
3. Wait 60 seconds for IAM propagation, then retry

### Issue 3: Billing Account Not Accessible

**Symptom**:
```bash
gcloud billing accounts list
# Listed 0 items.
```

**Solutions**:
1. Verify billing account exists in Console: https://console.cloud.google.com/billing
2. Grant billing admin role:
   ```bash
   gcloud organizations add-iam-policy-binding $ORG_ID \
     --member="user:<YOUR-ADMIN-EMAIL>" \
     --role="roles/billing.admin"
   ```
3. Check billing account ID is correct: `<BILLING-ACCOUNT-ID>`

### Issue 4: Break-Glass Account 2FA Issues

**Symptom**: Can't complete 2FA challenge for break-glass account

**Solutions**:
1. Use backup codes stored in Azure Key Vault:
   ```bash
   az keyvault secret show \
     --vault-name <YOUR-KEYVAULT> \
     --name "gcp-breakglass-2fa-codes"
   ```
2. Reset 2FA using M365 admin account via Cloud Identity Admin Console
3. Generate new backup codes and update Key Vault

### Issue 5: M365 Authentication Redirect Loop

**Symptom**: Browser keeps redirecting between GCP and Microsoft login

**Solutions**:
1. Clear browser cache and cookies
2. Use incognito/private browsing window
3. Ensure M365 account is added as external user in Cloud Identity:
   ```
   https://admin.google.com/ac/users
   ```
4. Check for Conditional Access policies in Azure AD that might block GCP

## Security Audit Commands

Run these regularly to audit security configuration:

```bash
# List all organization admins
gcloud organizations get-iam-policy $ORG_ID \
  --flatten="bindings[].members" \
  --filter="bindings.role:roles/resourcemanager.organizationAdmin" \
  --format="value(bindings.members)"

# Expected: Only <YOUR-ADMIN-EMAIL> and breakglass-<RANDOM>@<YOUR-DOMAIN>

# Check for service account keys (should be minimal)
for SA in $(gcloud iam service-accounts list --format="value(email)"); do
  echo "Checking keys for: $SA"
  gcloud iam service-accounts keys list --iam-account=$SA \
    --filter="keyType=USER_MANAGED" \
    --format="table(name,validAfterTime,validBeforeTime)"
done

# Expected: No USER_MANAGED keys (only SYSTEM_MANAGED)

# Audit Cloud Audit Logs configuration
gcloud logging sinks list --organization=$ORG_ID

# Expected: Will be configured in next phase

# Check organization policies
gcloud resource-manager org-policies list --organization=$ORG_ID

# Expected: Will be configured in next phase
```

## Next Phase: Organization Policies and Folders

Once all verification steps pass, proceed to:

1. **Folder Hierarchy Setup**: `deployments/gcp/organization/folders/`
   - Create `dev` and `prod` folders
   - Establish project structure

2. **Organization Policies**: `deployments/gcp/organization/policies/`
   - Resource location restrictions (global + europe-north1)
   - Public access prevention
   - Service usage controls

3. **Project Creation**: `deployments/gcp/projects/`
   - `kudu-dev-01` under dev folder
   - `kudu-prod-01` under prod folder

4. **Centralized Logging**: `deployments/gcp/organization/logging/`
   - Organization-level audit logs
   - Log sinks to GCS
   - Retention policies

## Documentation of Verification

Record verification results:

```bash
# Create verification log
cat > verification-results.txt << 'EOF'
GCP Organization Verification Results
Date: $(date)
Verified by: $(gcloud auth list --filter=status:ACTIVE --format="value(account)")

Organization ID: $(gcloud organizations list --format="value(ID)")
Organization State: $(gcloud organizations describe $ORG_ID --format="value(state)")
Billing Account: 01B0BF-5CA797-5BB7B8

M365 Account Access: ✅ Verified
Break-Glass Account Access: ✅ Verified
Organization Admin Permissions: ✅ Verified
Billing Account Linkage: ✅ Verified
Service Accounts: ✅ Verified
Workload Identity: ✅ Verified

Next Steps: Proceed to folder and organization policy setup
EOF

# Commit verification to repository
git add verification-results.txt
git commit -m "docs: GCP organization setup verification completed"
```

## Support and References

- [Cloud Identity Troubleshooting](https://support.google.com/cloudidentity/answer/7319251)
- [Organization Resource Manager](https://cloud.google.com/resource-manager/docs/creating-managing-organization)
- [External Identities](https://support.google.com/cloudidentity/answer/9415374)
- [Workload Identity Best Practices](https://cloud.google.com/iam/docs/best-practices-for-using-workload-identity-federation)
- Workspace reference: `deployments/gcp/iam/workload-identity/README.md`
- AWS comparison: `deployments/aws/AWS_DEPLOYMENT_GUIDE.md`
