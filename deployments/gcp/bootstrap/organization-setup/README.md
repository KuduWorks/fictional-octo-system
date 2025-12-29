# GCP Organization Setup - Cloud Identity Free

This guide walks through setting up a GCP Organization using Cloud Identity Free, with support for external Microsoft 365 accounts and a native GCP break-glass account.

## Overview

**Authentication Strategy:**
- **Primary**: Service accounts + Workload Identity Federation (for automation)
- **External Users**: Microsoft 365 accounts via external identity
- **Break-Glass**: One native GCP-only account for emergency access
- **No Domain Verification Required**: M365 and GCP coexist peacefully

## Prerequisites

- ✅ Google account (any Gmail address for initial setup)
- ✅ Access to Microsoft 365 account with admin privileges
- ✅ GCP Billing Account ID
- ✅ Custom domain (if using M365, not verified in GCP)

## Architecture

```
GCP Organization (<YOUR-DOMAIN>)
├── Cloud Identity Free (No Domain Verification)
│   ├── Super Admin: <YOUR-ADMIN-EMAIL> (M365 External Identity)
│   └── Break-Glass: breakglass-<RANDOM>@<YOUR-DOMAIN> (Native GCP)
│
├── Folders
│   ├── dev/
│   └── prod/
│
├── Projects
│   ├── <DEV-PROJECT-ID>
│   └── <PROD-PROJECT-ID>
│
└── Service Accounts (Primary Authentication)
    ├── terraform-automation@<PROJECT-ID>.iam.gserviceaccount.com
    ├── github-actions@<PROJECT-ID>.iam.gserviceaccount.com
    └── app-workloads@<PROJECT-ID>.iam.gserviceaccount.com
```

## Part 1: Cloud Identity Free Setup (Manual)

### Step 1: Sign Up for Cloud Identity Free

**Important**: Do NOT use domain verification. We'll add external accounts afterward.

1. **Navigate to Cloud Identity Admin Console**:
   ```
   https://admin.google.com/
   ```
   
2. **Sign in with any Google Account**:
   - Use a temporary Gmail account for initial setup
   - Example: `temp-setup@gmail.com`
   - This account will create the organization

3. **Start Cloud Identity Free Trial**:
   - Select "Cloud Identity Free"
   - **Skip domain verification** when prompted
   - Accept terms and conditions

4. **Create GCP Organization**:
   - Navigate to: https://console.cloud.google.com/
   - Sign in with the same Google account
   - The organization is **automatically created** when you first access Google Cloud Console
   - Organization name will default to your account name

### Step 2: Link Billing Account

```bash
# List available billing accounts
gcloud billing accounts list

# Link billing account to organization (replace ORG_ID)
gcloud organizations add-iam-policy-binding ORG_ID \
  --member="user:temp-setup@gmail.com" \
  --role="roles/billing.admin"

# Associate billing account
gcloud beta billing accounts get-iam-policy 01B0BF-5CA797-5BB7B8
```

### Step 3: Add External M365 Account as Organization Admin

**Critical**: This allows your M365 account to authenticate with Microsoft credentials.

1. **Open Cloud Identity Admin Console**:
   ```
   https://admin.google.com/ac/users
   ```

2. **Add New User** (External Identity):
   - Click "Add User"
   - Email: `<YOUR-ADMIN-EMAIL>` (your M365 email address)
   - Select "External user" or "Add as guest"
   - **Do NOT set a password** (will use M365 authentication)
   
3. **Grant Organization Admin Role**:
   ```bash
   # Get organization ID
   ORG_ID=$(gcloud organizations list --format="value(ID)")
   
   # Grant organization admin role
   gcloud organizations add-iam-policy-binding $ORG_ID \
     --member="user:<YOUR-ADMIN-EMAIL>" \
     --role="roles/resourcemanager.organizationAdmin"
   
   # Grant billing admin (optional)
   gcloud organizations add-iam-policy-binding $ORG_ID \
     --member="user:<YOUR-ADMIN-EMAIL>" \
     --role="roles/billing.admin"
   ```

4. **Test M365 Authentication**:
   ```bash
   # Sign out current account
   gcloud auth revoke
   
   # Sign in with M365 account
   gcloud auth login <YOUR-ADMIN-EMAIL>
   
   # When browser opens, use Microsoft 365 credentials
   # GCP will redirect to login.microsoftonline.com
   
   # Verify access
   gcloud organizations list
   ```

### Step 4: Create Native GCP Break-Glass Account

**Purpose**: Emergency access when M365 is unavailable or compromised.

**Option A: Cloud Identity Native Account** (Recommended)

1. **Create via Admin Console**:
   ```
   https://admin.google.com/ac/users
   ```
   
2. **User Details**:
   - First name: `Break Glass`
   - Last name: `Admin`
   - Email: `breakglass-<RANDOM>@<YOUR-DOMAIN>` (e.g., breakglass-a7f2@example.com)
   - Password: Generate strong password (store in Azure Key Vault)
   - Recovery email: `<YOUR-ADMIN-EMAIL>`
   - Require password change: No (you control it)
   
   **Note**: Use a randomized identifier (e.g., 4-character alphanumeric) for the break-glass account name to avoid predictable account names in public repositories.
   
3. **Enable 2-Step Verification**:
   - **Mandatory** for security
   - Use hardware security key (YubiKey) recommended
   - Backup codes stored in Azure Key Vault

4. **Grant Organization Admin**:
   ```bash
   gcloud organizations add-iam-policy-binding $ORG_ID \
     --member="user:breakglass-<RANDOM>@<YOUR-DOMAIN>" \
     --role="roles/resourcemanager.organizationAdmin"
   
   gcloud organizations add-iam-policy-binding $ORG_ID \
     --member="user:breakglass-<RANDOM>@<YOUR-DOMAIN>" \
     --role="roles/iam.organizationRoleAdmin"
   ```

**Option B: Service Account Break-Glass** (Alternative)

```bash
# Create break-glass service account
gcloud iam service-accounts create breakglass-admin \
  --display-name="Break-Glass Emergency Admin" \
  --description="Emergency access when M365 unavailable"

# Grant organization admin
gcloud organizations add-iam-policy-binding $ORG_ID \
  --member="serviceAccount:breakglass-admin@<PROJECT-ID>.iam.gserviceaccount.com" \
  --role="roles/resourcemanager.organizationAdmin"

# Create key (store securely in Azure Key Vault)
gcloud iam service-accounts keys create breakglass-key.json \
  --iam-account=breakglass-admin@<PROJECT-ID>.iam.gserviceaccount.com

# Test authentication
gcloud auth activate-service-account \
  --key-file=breakglass-key.json

# IMPORTANT: Delete local key file after storing in vault
rm breakglass-key.json
```

## Part 2: Service Account Strategy (Primary Authentication)

**Philosophy**: Human users for console/emergency only. Service accounts for all automation.

### Recommended Service Accounts

Following patterns from `deployments/gcp/iam/workload-identity/`:

1. **Terraform Automation Service Account**:
   ```bash
   gcloud iam service-accounts create terraform-automation \
     --display-name="Terraform Infrastructure Automation" \
     --project=<DEV-PROJECT-ID>
   
   # Grant organization-level permissions
   gcloud organizations add-iam-policy-binding $ORG_ID \
     --member="serviceAccount:terraform-automation@<DEV-PROJECT-ID>.iam.gserviceaccount.com" \
     --role="roles/resourcemanager.folderAdmin"
   
   gcloud organizations add-iam-policy-binding $ORG_ID \
     --member="serviceAccount:terraform-automation@<DEV-PROJECT-ID>.iam.gserviceaccount.com" \
     --role="roles/resourcemanager.projectCreator"
   ```

2. **GitHub Actions Service Account** (Already Implemented):
   ```bash
   # Extend to organization level
   gcloud organizations add-iam-policy-binding $ORG_ID \
     --member="serviceAccount:main-github-actions@<PROJECT-ID>.iam.gserviceaccount.com" \
     --role="roles/viewer"
   ```

3. **Monitoring & Logging Service Account**:
   ```bash
   gcloud iam service-accounts create monitoring-agent \
     --display-name="Monitoring and Logging Agent" \
     --project=<DEV-PROJECT-ID>
   
   gcloud organizations add-iam-policy-binding $ORG_ID \
     --member="serviceAccount:monitoring-agent@<DEV-PROJECT-ID>.iam.gserviceaccount.com" \
     --role="roles/logging.logWriter"
   
   gcloud organizations add-iam-policy-binding $ORG_ID \
     --member="serviceAccount:monitoring-agent@<DEV-PROJECT-ID>.iam.gserviceaccount.com" \
     --role="roles/monitoring.metricWriter"
   ```

### Workload Identity Federation for External Services

Continue the pattern from `deployments/gcp/iam/workload-identity/main.tf`:

```hcl
# Organization-level workload identity pool
resource "google_iam_workload_identity_pool" "github_org" {
  workload_identity_pool_id = "github-actions-org-pool"
  display_name              = "GitHub Actions - Organization Level"
  description               = "Workload Identity Pool for GitHub Actions across all projects"
  project                   = var.project_id
}

resource "google_iam_workload_identity_pool_provider" "github_org" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_org.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-org-provider"
  display_name                       = "GitHub Organization Provider"
  
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }
  
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}
```

## Part 3: M365 and GCP Coexistence

### Domain Considerations

**Your Setup**:
- Domain: `<YOUR-DOMAIN>`
- M365 Tenant: Active (for email/identity)
- GCP Organization: No domain verification needed

**How They Coexist**:

1. **M365 Domain Records** (Existing):
   ```dns
   # MX records for email
   <YOUR-DOMAIN>.  MX  10  <YOUR-DOMAIN-SANITIZED>.mail.protection.outlook.com
   
   # TXT records for M365 verification
   <YOUR-DOMAIN>.  TXT  "MS=msXXXXXXXX"
   
   # CNAME for Autodiscover
   autodiscover.<YOUR-DOMAIN>.  CNAME  autodiscover.outlook.com
   ```

2. **GCP Domain Records** (NOT NEEDED):
   - ✅ No TXT verification required for Cloud Identity Free
   - ✅ External accounts use their native identity provider (Microsoft)
   - ✅ Service accounts don't require domain verification

3. **Authentication Flow for M365 Users**:
   ```
   User: <YOUR-ADMIN-EMAIL>
   ↓
   GCP Console Login → Redirects to login.microsoftonline.com
   ↓
   Microsoft 365 Authentication (Azure AD)
   ↓
   GCP grants access based on IAM bindings
   ```

### Benefits of This Approach

- ✅ No DNS conflicts between M365 and GCP
- ✅ No need to manage separate passwords for GCP
- ✅ M365 MFA policies apply automatically
- ✅ Single identity across Microsoft and Google clouds
- ✅ Service accounts remain primary for automation

## Part 4: Security Best Practices

### Break-Glass Account Management

**Storage**: Azure Key Vault (following your existing pattern)

```bash
# Store break-glass credentials in Azure Key Vault
az keyvault secret set \
  --vault-name <YOUR-KEYVAULT> \
  --name "gcp-breakglass-password" \
  --value "<STRONG-PASSWORD>"

# Store 2FA backup codes
az keyvault secret set \
  --vault-name <YOUR-KEYVAULT> \
  --name "gcp-breakglass-2fa-codes" \
  --value "<BACKUP-CODES>"

# Store service account key (if using Option B)
az keyvault secret set \
  --vault-name <YOUR-KEYVAULT> \
  --name "gcp-breakglass-sa-key" \
  --file breakglass-key.json
```

### Testing Break-Glass Access

**Quarterly Test Procedure**:

1. **Retrieve credentials from Azure Key Vault**:
   ```bash
   az keyvault secret show \
     --vault-name <YOUR-KEYVAULT> \
     --name "gcp-breakglass-password" \
     --query value -o tsv
   ```

2. **Authenticate**:
   ```bash
   gcloud auth login breakglass-<RANDOM>@<YOUR-DOMAIN>
   # Or for service account:
   gcloud auth activate-service-account --key-file=<key-from-vault>
   ```

3. **Verify organization access**:
   ```bash
   gcloud organizations list
   gcloud organizations get-iam-policy $ORG_ID
   ```

4. **Document test in audit log**:
   ```bash
   echo "Break-glass test: $(date)" >> break-glass-tests.log
   git add break-glass-tests.log
   git commit -m "Quarterly break-glass access test"
   ```

### M365 Account Security

**Recommendations**:
- ✅ Enable Conditional Access in Azure AD (IP restrictions)
- ✅ Require MFA for all users
- ✅ Monitor sign-ins to both M365 and GCP
- ✅ Use Azure AD Privileged Identity Management (PIM) if available

### Service Account Key Management

**Following existing workspace pattern** (`deployments/gcp/iam/workload-identity/`):
- ✅ **Never create service account keys** for automation
- ✅ Use Workload Identity Federation (keyless)
- ✅ Only create keys for break-glass scenarios
- ✅ Store keys in Azure Key Vault with expiration alerts
- ✅ Rotate keys every 90 days

## Part 5: Verification Steps

After completing setup, proceed to [VERIFICATION.md](./VERIFICATION.md).

## Next Steps

Once organization is verified:

1. ✅ Create folder hierarchy: `deployments/gcp/organization/folders/`
2. ✅ Implement organization policies: `deployments/gcp/organization/policies/`
3. ✅ Create dev and prod projects: `deployments/gcp/projects/`
4. ✅ Configure centralized logging: `deployments/gcp/organization/logging/`
5. ✅ Set up budget alerts: `deployments/gcp/cost-management/budgets/`

## Cost Breakdown

| Component | Cost | Notes |
|-----------|------|-------|
| Cloud Identity Free | $0/month | Up to 50 users |
| GCP Organization | $0/month | No charge for organization itself |
| External Identity | $0/month | No additional cost for M365 integration |
| Service Accounts | $0/month | Unlimited |
| Workload Identity Pool | $0/month | No charge for federation |

**Total Setup Cost**: $0/month

## Troubleshooting

### M365 Account Won't Authenticate

**Issue**: GCP doesn't recognize `postforyves@kuduworks.net`

**Solution**:
```bash
# Ensure account added as external user in Cloud Identity
gcloud organizations get-iam-policy $ORG_ID \
  | grep <YOUR-ADMIN-EMAIL>

# Re-add if missing
gcloud organizations add-iam-policy-binding $ORG_ID \
  --member="user:<YOUR-ADMIN-EMAIL>" \
  --role="roles/resourcemanager.organizationAdmin"
```

### Break-Glass Account Locked

**Issue**: 2FA device lost or account locked

**Solution**:
1. Use M365 account (`postforyves@kuduworks.net`) to reset
2. Access Cloud Identity Admin Console
3. Reset 2FA for break-glass account
4. Generate new backup codes
5. Update Azure Key Vault

### Organization Not Created

**Issue**: `gcloud organizations list` returns empty

**Solution**:
```bash
# Verify you have organization admin permission
gcloud projects list

# Organizations are created automatically when:
# 1. First GCP resource is created, OR
# 2. Cloud Identity is linked to GCP

# Force organization creation
gcloud projects create temp-org-trigger --folder=<any-folder>
```

## References

- [Cloud Identity Free Documentation](https://cloud.google.com/identity/docs/set-up-cloud-identity-admin)
- [External Identities in Cloud Identity](https://support.google.com/cloudidentity/answer/9415374)
- [Workload Identity Federation Best Practices](https://cloud.google.com/iam/docs/workload-identity-federation)
- [Organization Resource Hierarchy](https://cloud.google.com/resource-manager/docs/cloud-platform-resource-hierarchy)
- Existing workspace patterns: `deployments/gcp/iam/workload-identity/README.md`
