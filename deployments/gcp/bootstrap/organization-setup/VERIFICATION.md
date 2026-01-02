# GCP Organization Verification Guide

This guide provides verification commands to confirm your GCP Organization is properly configured with Cloud Identity, M365 SAML SSO, and break-glass access.

## ⚠️ Security Notice

**Load your configuration before running any commands:**
```bash
cd deployments/gcp/bootstrap/organization-setup
source config.sh
```

This ensures all commands use your actual values from the gitignored configuration file.

## Prerequisites Checklist

Before verifying, ensure you've completed:
- ✅ Cloud Identity Free signup
- ✅ SAML federation configured between Entra ID and Cloud Identity
- ✅ M365 account granted IAM Organization Admin role
- ✅ Created native break-glass account
- ✅ Linked billing account to organization
- ✅ Created and loaded config.sh with your values

## Verification Steps

### Step 1: Verify Organization Exists

**Load configuration and check organization**:

```bash
# Load your configuration
source config.sh

# List all organizations you have access to
gcloud organizations list

# Expected output:
# DISPLAY_NAME              ID            DIRECTORY_CUSTOMER_ID
# $GCP_ORG_DOMAIN           $GCP_ORG_ID   <DIRECTORY-CUSTOMER-ID>
```

**Get organization details**:

```bash
# Verify organization ID from config
echo "Organization ID: $GCP_ORG_ID"
echo "Organization Domain: $GCP_ORG_DOMAIN"

# Get full organization information
gcloud organizations describe $GCP_ORG_ID

# Expected output:
# creationTime: '2025-12-29T...'
# displayName: $GCP_ORG_DOMAIN
# name: organizations/$GCP_ORG_ID
# owner:
#   directoryCustomerId: <DIRECTORY-CUSTOMER-ID>
# state: ACTIVE
```

**Verify organization state**:

```bash
# Organization must be ACTIVE
gcloud organizations describe $GCP_ORG_ID --format="value(state)"

# Expected: ACTIVE
```

### Step 2: Verify M365 SAML SSO Authentication

**Test SAML federation in browser first**:

```bash
# Load configuration
source config.sh

# Open browser to test SSO
echo "Testing SAML SSO for: $GCP_ADMIN_EMAIL"
echo "1. Open incognito browser: https://accounts.google.com"
echo "2. Enter: $GCP_ADMIN_EMAIL"
echo "3. Should redirect to: login.microsoftonline.com"
echo "4. Complete M365 authentication"
echo "5. Should redirect back to Google"
```

**Verify SAML configuration in Cloud Identity**:

```bash
# In Cloud Identity Admin Console (https://admin.google.com/)
# Navigate to: Security → Authentication → SSO with third-party IdP
# Should show: Entra ID SAML configuration
# Status: Active
```

**Verify Entra ID Enterprise Application**:

```bash
# In Azure Portal: https://portal.azure.com
# Enterprise Applications → Google Cloud Platform - $GCP_ORG_DOMAIN
# Verify:
# - Application is active
# - $GCP_ADMIN_EMAIL is assigned under Users and groups
# - SAML SSO is configured
```

**Test gcloud authentication with M365 credentials**:

```bash
# Sign out current account
gcloud auth revoke --all

# Authenticate with M365 account
gcloud auth login $GCP_ADMIN_EMAIL

# Browser will open → Microsoft login page (SAML redirect)
# Use your Microsoft 365 password and MFA
# GCP will redirect to: https://login.microsoftonline.com/...
# After SAML assertion, you'll be authenticated

# After successful auth, verify active account
gcloud auth list

# Expected output:
#              Credentialed Accounts
# ACTIVE  ACCOUNT
# *       $GCP_ADMIN_EMAIL
```

**Verify organization admin permissions**:

```bash
# Load configuration
source config.sh

# List organizations (should see your org)
gcloud organizations list

# Get IAM policy to confirm your permissions
gcloud organizations get-iam-policy $GCP_ORG_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:$GCP_ADMIN_EMAIL" \
  --format="table(bindings.role)"

# Expected roles:
# roles/resourcemanager.organizationAdmin
# roles/billing.admin (optional)
```

**Test organization-level operations**:

```bash
# Try listing all projects in the organization
gcloud projects list --organization=$GCP_ORG_ID

# Try viewing organization IAM policy
gcloud organizations get-iam-policy $GCP_ORG_ID

# Both should succeed without permission errors
```

### Step 3: Verify Break-Glass Account

**Option A: If using Cloud Identity native account**:

```bash
# Load configuration
source config.sh

# Sign out M365 account
gcloud auth revoke --all

# Authenticate with break-glass account
gcloud auth login $GCP_BREAKGLASS_EMAIL

# Use the password stored in Azure Key Vault
# Complete 2FA challenge

# Verify active account
gcloud auth list

# Expected:
# *       $GCP_BREAKGLASS_EMAIL

# Verify organization access
gcloud organizations list
gcloud organizations describe $GCP_ORG_ID

# Verify admin permissions
gcloud organizations get-iam-policy $GCP_ORG_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:$GCP_BREAKGLASS_EMAIL" \
  --format="table(bindings.role)"

# Expected:
# roles/resourcemanager.organizationAdmin
# roles/iam.organizationRoleAdmin
```

**Option B: If using service account break-glass**:

```bash
# Load configuration
source config.sh

# Retrieve service account key from Azure Key Vault (using obscure secret name)
az keyvault secret show \
  --vault-name $AZURE_KEYVAULT_NAME \
  --name "gcp-svc-automation-key" \
  --query value -o tsv > sa-key.json

# Activate service account
gcloud auth activate-service-account \
  svc-automation@$GCP_DEV_PROJECT_ID.iam.gserviceaccount.com \
  --key-file=sa-key.json

# Verify active account
gcloud auth list

# Expected:
# *       svc-automation@$GCP_DEV_PROJECT_ID.iam.gserviceaccount.com

# Verify organization access
gcloud organizations list

# Clean up key file
rm sa-key.json
```

### Step 4: Verify Billing Account Linkage

**Check billing account exists**:

```bash
# Load configuration
source config.sh

# List all billing accounts
gcloud billing accounts list

# Expected output:
# ACCOUNT_ID               NAME                OPEN  MASTER_ACCOUNT_ID
# $GCP_BILLING_ACCOUNT_ID  Billing Account 1   True

# Get billing account details
gcloud billing accounts describe $GCP_BILLING_ACCOUNT_ID
```

**Verify billing permissions**:

```bash
# Check who has access to billing account
gcloud billing accounts get-iam-policy $GCP_BILLING_ACCOUNT_ID

# Should include:
# - $GCP_ADMIN_EMAIL with roles/billing.admin
# - Organization admins with billing access
```

**Test billing account assignment**:

```bash
# Load configuration
source config.sh

# When creating new projects, verify billing can be linked
gcloud projects create test-billing-check-001 \
  --organization=$GCP_ORG_ID \
  --labels=environment=test,purpose=verification

# Link billing to test project
gcloud billing projects link test-billing-check-001 \
  --billing-account=$GCP_BILLING_ACCOUNT_ID

# Verify billing is enabled
gcloud billing projects describe test-billing-check-001

# Clean up test project
gcloud projects delete test-billing-check-001 --quiet
```

### Step 5: Verify Service Account Strategy

**Check existing service accounts**:

```bash
# Load configuration
source config.sh

# List service accounts in dev project
gcloud iam service-accounts list --project=$GCP_DEV_PROJECT_ID

# Expected (from existing deployments):
# main-github-actions@$GCP_DEV_PROJECT_ID.iam.gserviceaccount.com
# terraform-automation@$GCP_DEV_PROJECT_ID.iam.gserviceaccount.com
```

**Verify Workload Identity Pool**:

```bash
# List workload identity pools
gcloud iam workload-identity-pools list \
  --location=global \
  --project=$GCP_DEV_PROJECT_ID

# Expected:
# github-actions-pool

# Get pool details
gcloud iam workload-identity-pools describe github-actions-pool \
  --location=global \
  --project=$GCP_DEV_PROJECT_ID
```

**Verify no long-lived service account keys** (security best practice):

```bash
# Check for service account keys (should be minimal)
gcloud iam service-accounts keys list \
  --iam-account=main-github-actions@$GCP_DEV_PROJECT_ID.iam.gserviceaccount.com

# Should only show system-managed keys, no user-managed keys
# Expected:
# KEY_ID                                    CREATED_AT            EXPIRES_AT            KEY_TYPE
# abc123...                                 2025-12-29T...        2025-01-05T...        SYSTEM_MANAGED

# User-managed keys indicate manual key creation (avoid this)
```

### Step 6: Verify Cloud Identity Configuration

**Check Cloud Identity users and SAML federation**:

```bash
# Load configuration
source config.sh

# Note: Cloud Identity user management requires Cloud Identity API or Admin Console
# Verify via Admin Console: https://admin.google.com/ac/users

# Alternative: Check organization IAM policy for user list
gcloud organizations get-iam-policy $GCP_ORG_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:user*" \
  --format="value(bindings.members)" | sort -u

# Expected users:
# user:$GCP_ADMIN_EMAIL (federated via SAML)
# user:$GCP_BREAKGLASS_EMAIL (native Cloud Identity)
```

**Verify SAML SSO configuration**:

```bash
# In Cloud Identity Admin Console (https://admin.google.com/):
# Security → Authentication → SSO with third-party IdP
# Should show:
# - Provider: Microsoft Entra ID
# - Status: Active
# - Domain: $GCP_ORG_DOMAIN

echo "Verify SAML SSO at: https://admin.google.com/ac/security/sso"
echo "Domain configured: $GCP_ORG_DOMAIN"
echo "Federated user: $GCP_ADMIN_EMAIL"
```

**Verify domain is NOT verified in GCP** (correct for SAML SSO):

```bash
# M365 owns the domain DNS, GCP uses SAML for authentication
# Domain verification is NOT needed for SAML federation
echo "Domain $GCP_ORG_DOMAIN is federated via SAML, not verified in GCP"
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
gcloud resource-manager org-policies list --organization=$GCP_ORG_ID

# Expected: Empty or minimal policies
# Organization policies will be implemented in next phase
```

## Verification Summary

After running all commands, you should have confirmed:

| Component | Status | Command |
|-----------|--------|---------|
| ✅ Organization exists | ACTIVE | `gcloud organizations list` |
| ✅ SAML SSO configured | Active | Cloud Identity Admin Console |
| ✅ Entra ID app configured | Active | Azure Portal Enterprise Apps |
| ✅ M365 account access | Working | `gcloud auth login $GCP_ADMIN_EMAIL` |
| ✅ Break-glass account | Working | `gcloud auth login $GCP_BREAKGLASS_EMAIL` |
| ✅ Organization Admin IAM | Granted | `gcloud organizations get-iam-policy` |
| ✅ Billing account linked | Active | `gcloud billing accounts list` |
| ✅ Service accounts exist | Configured | `gcloud iam service-accounts list` |
| ✅ Workload Identity Pool | Active | `gcloud iam workload-identity-pools list` |
| ✅ Configuration loaded | Ready | `source config.sh` |
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
source config.sh
gcloud organizations get-iam-policy $GCP_ORG_ID
# Error: Permission denied
```

**Solutions**:
1. Verify SAML authentication completed successfully:
   ```bash
   gcloud auth list
   # Should show: $GCP_ADMIN_EMAIL as ACTIVE
   ```
2. Re-authenticate with break-glass account and grant permissions:
   ```bash
   gcloud auth login $GCP_BREAKGLASS_EMAIL
   gcloud organizations add-iam-policy-binding $GCP_ORG_ID \
     --member="user:$GCP_ADMIN_EMAIL" \
     --role="roles/resourcemanager.organizationAdmin"
   ```
3. Verify user is assigned in Entra ID Enterprise Application
4. Wait 60 seconds for IAM propagation, then retry

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
   gcloud organizations add-iam-policy-binding $GCP_ORG_ID \
     --member="user:<YOUR-ADMIN-EMAIL>" \
     --role="roles/billing.admin"
   ```
3. Check billing account ID is correct: `<BILLING-ACCOUNT-ID>`

### Issue 4: Emergency Access Account 2FA Issues

**Symptom**: Can't complete 2FA challenge for emergency access account

**Solutions**:
1. Use backup codes stored in Azure Key Vault (using obscure secret name):
   ```bash
   source config.sh
   az keyvault secret show \
     --vault-name $AZURE_KEYVAULT_NAME \
     --name "gcp-svc-auth-2fa"
   ```
2. Reset 2FA using M365 admin account via Cloud Identity Admin Console
3. Generate new backup codes and update Key Vault

### Issue 5: M365 SAML Authentication Issues

**Symptom**: Browser keeps redirecting, or "Account not found" error

**Solutions**:
1. **Verify SAML configuration**:
   - Cloud Identity: https://admin.google.com/ac/security/sso
   - Entra ID: https://portal.azure.com (Enterprise Applications)

2. **Check user assignment**:
   ```bash
   source config.sh
   echo "Verify $GCP_ADMIN_EMAIL is assigned in:"
   echo "Azure Portal → Enterprise Applications → Google Cloud Platform - $GCP_ORG_DOMAIN → Users and groups"
   ```

3. **Test SAML flow manually**:
   - Clear browser cache and cookies
   - Use incognito/private browsing window
   - Navigate to: https://accounts.google.com
   - Enter: `$GCP_ADMIN_EMAIL`
   - Should redirect to: login.microsoftonline.com
   - If redirect doesn't happen, SAML is not configured

4. **Check Conditional Access policies** in Azure AD that might block GCP
5. **Verify SAML metadata** was uploaded correctly to Cloud Identity

## Security Audit Commands

Run these regularly to audit security configuration:

```bash
# Load configuration
source config.sh

# List all organization admins
gcloud organizations get-iam-policy $GCP_ORG_ID \
  --flatten="bindings[].members" \
  --filter="bindings.role:roles/resourcemanager.organizationAdmin" \
  --format="value(bindings.members)"

# Expected: Only $GCP_ADMIN_EMAIL and $GCP_BREAKGLASS_EMAIL

# Check for service account keys (should be minimal)
for SA in $(gcloud iam service-accounts list --format="value(email)"); do
  echo "Checking keys for: $SA"
  gcloud iam service-accounts keys list --iam-account=$SA \
    --filter="keyType=USER_MANAGED" \
    --format="table(name,validAfterTime,validBeforeTime)"
done

# Expected: No USER_MANAGED keys (only SYSTEM_MANAGED)

# Audit Cloud Audit Logs configuration
gcloud logging sinks list --organization=$GCP_ORG_ID

# Expected: Will be configured in next phase

# Check organization policies
gcloud resource-manager org-policies list --organization=$GCP_ORG_ID

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
# Load configuration
source config.sh

# Create verification log
cat > verification-results.txt << EOF
GCP Organization Verification Results
Date: $(date)
Verified by: $(gcloud auth list --filter=status:ACTIVE --format="value(account)")

Organization ID: $GCP_ORG_ID
Organization Domain: $GCP_ORG_DOMAIN
Organization State: $(gcloud organizations describe $GCP_ORG_ID --format="value(state)")
Billing Account: $GCP_BILLING_ACCOUNT_ID

SAML SSO: ✅ Configured
M365 Account Access ($GCP_ADMIN_EMAIL): ✅ Verified
Break-Glass Account ($GCP_BREAKGLASS_EMAIL): ✅ Verified
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
