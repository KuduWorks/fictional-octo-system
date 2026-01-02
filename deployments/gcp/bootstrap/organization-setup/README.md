# GCP Organization Setup - Cloud Identity Free

This guide walks through setting up a GCP Organization using Cloud Identity Free, with support for external Microsoft 365 accounts and a native GCP break-glass account.

## ⚠️ Security Notice

**This repository is public.** Never commit sensitive values like:
- Organization IDs
- Project IDs
- Email addresses
- Billing account IDs
- Service account keys

**Setup your configuration:**
```bash
cd deployments/gcp/bootstrap/organization-setup
cp config.example.sh config.sh
# Edit config.sh with your actual values
source ./config.sh
```

The actual `config.sh` file is gitignored and will never be committed.

## Overview

**Authentication Strategy:**
- **Primary**: Service accounts + Workload Identity Federation (for automation)
- **Human Users**: Microsoft 365 accounts via SAML SSO (Workforce Identity Federation)
- **Break-Glass**: One native GCP-only account for emergency access
- **Domain Consideration**: M365 owns domain DNS, GCP uses SAML for authentication

## Prerequisites

- ✅ Google account (any Gmail address for initial setup)
- ✅ Access to Microsoft 365 account with admin privileges
- ✅ GCP Billing Account ID
- ✅ Custom domain verified in both M365 and GCP (via DNS TXT record)
- ✅ DNS access to add TXT verification records

## Architecture

```
GCP Organization ($GCP_ORG_DOMAIN)
├── Cloud Identity Free
│   ├── SAML Federation: Entra ID (Microsoft 365)
│   │   └── Federated User: $GCP_ADMIN_EMAIL
│   └── Break-Glass: $GCP_BREAKGLASS_EMAIL (Native Cloud Identity)
│
├── Folders
│   ├── dev/
│   └── prod/
│
├── Projects
│   ├── $GCP_DEV_PROJECT_ID (dev)
│   └── $GCP_PROD_PROJECT_ID (prod)
│
└── Service Accounts (Primary Authentication)
    ├── terraform-automation@$GCP_DEV_PROJECT_ID.iam.gserviceaccount.com
    ├── github-actions@$GCP_DEV_PROJECT_ID.iam.gserviceaccount.com
    └── app-workloads@$GCP_DEV_PROJECT_ID.iam.gserviceaccount.com
```

## Part 1: Cloud Identity Free Setup (Manual)

### Step 1: Sign Up for Cloud Identity Free

**Important**: You WILL need to verify your domain to create Cloud Identity users.

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
   - Enter your domain: `$GCP_ORG_DOMAIN`
   - Accept terms and conditions

4. **Verify Domain Ownership**:
   - Cloud Identity will provide a TXT record: `google-site-verification=XXXXXXX`
   - Add this to your DNS (same DNS where M365 MX records are)
   - Wait for verification (can take up to 48 hours, usually minutes)
   - **Note**: This does NOT conflict with M365 - both can verify the same domain

5. **Create GCP Organization**:
   - Navigate to: https://console.cloud.google.com/
   - Sign in with the same Google account
   - The organization is **automatically created** when you first access Google Cloud Console
   - Organization name will be your verified domain

### Step 2: Link Billing Account

```bash
# Load configuration
source config.sh

# List available billing accounts
gcloud billing accounts list

# Copy your billing account ID to config.sh as GCP_BILLING_ACCOUNT_ID

# Verify billing account access
gcloud beta billing accounts get-iam-policy $GCP_BILLING_ACCOUNT_ID

# Link billing account to organization
gcloud organizations add-iam-policy-binding $GCP_ORG_ID \
  --member="user:$(gcloud config get-value account)" \
  --role="roles/billing.admin"
```

### Step 3: Set Up M365 SAML Federation

**Critical**: This enables M365 users to authenticate with Microsoft credentials when accessing GCP.

**Setup Order** (Important):
1. Create Entra ID Enterprise Application (Part A)
2. Configure SAML profile in GCP Cloud Identity (Part B)
3. Update Entra ID app with GCP Entity ID and ACS URL (Part C)
4. Configure user provisioning in Entra ID (Part D)
5. Assign SSO profile in GCP (Part E)
6. Grant IAM permissions to synced users (Part F)

#### Part A: Create Entra ID Enterprise Application

1. **Create Enterprise Application in Entra ID**:
   - Navigate to: https://portal.azure.com/#view/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/~/Overview
   - Go to **Enterprise Applications** → **New application** → **Create your own application**
   - Name: `Google Cloud Platform - $GCP_ORG_DOMAIN`
   - Select: **Integrate any other application you don't find in the gallery (Non-gallery)**
   - Click **Create**

2. **Initial SAML Setup** (placeholder values for now):
   - In the application, go to **Single sign-on** → Select **SAML**
   - Click **Edit** on **Basic SAML Configuration**
   - Add temporary values (you'll update these in Part C):
     ```
     Identifier (Entity ID): https://accounts.google.com/o/saml2?idpid=TEMP
     Reply URL: https://www.google.com/a/$GCP_ORG_DOMAIN/acs
     Sign on URL: https://www.google.com/a/$GCP_ORG_DOMAIN
     ```
   - Click **Save**

3. **Configure Attributes & Claims**:
   - Use **default attribute mappings** (should already be configured):
     - Unique User Identifier: user.userprincipalname
     - Email: user.mail  
     - First Name: user.givenname
     - Last Name: user.surname
   - **Only modify if** your Entra ID attributes differ from defaults

4. **Download SAML Certificate** (IMPORTANT - use Base64 format):
   - In **SAML Certificates** section
   - Find **Certificate (Base64)** (NOT Federation Metadata XML)
   - Click **Download** → Saves as `.cer` file
   - **Note**: GCP requires a Base64-encoded certificate (PEM format), NOT XML
   - **Optional**: Add additional certificates for rotation before expiration

5. **Copy IdP URLs** (needed for Part B):
   - In **Set up Google Cloud Platform** section (Step 4), copy:
     - **Login URL** (e.g., `https://login.microsoftonline.com/.../saml2`)
     - **Microsoft Entra Identifier** (e.g., `https://sts.windows.net/.../`)
     - **Logout URL** (e.g., `https://login.microsoftonline.com/.../saml2`)

#### Part B: Configure SAML Profile in GCP Cloud Identity

1. **Access Cloud Identity Admin Console**:
   ```
   https://admin.google.com/
   ```
   - Sign in with your break-glass account (`$GCP_BREAKGLASS_EMAIL` from config.sh)

2. **Create SAML SSO Profile**:
   - Navigate to: **Security** → **Authentication** → **SSO with third-party IdP**
   - Click **Add SSO profile**
   - **SSO Profile Name**: `Microsoft Entra ID - $GCP_ORG_DOMAIN`

3. **Configure IdP Details** (from Part A Step 5):
   - **Sign-in page URL**: Paste **Login URL** from Entra ID
   - **Sign-out page URL**: Paste **Logout URL** from Entra ID
   - **Change password URL**: `https://mysignins.microsoft.com/security-info/password/change`
   - **Verification certificate**: Upload the **Base64 .cer file** from Part A Step 4
   - Click **Upload**

4. **Configure SSO Settings**:
   - **Use a domain-specific issuer**: ✅ Enabled
   - **Network mask**: Leave empty (allow from any network)
   - Click **Save**

5. **Copy GCP SSO URLs** (needed for Part C):
   - After saving, GCP displays:
     - **Entity ID**: `google.com/a/$GCP_ORG_DOMAIN` (copy this)
     - **ACS URL**: `https://www.google.com/a/$GCP_ORG_DOMAIN/acs` (copy this)
   - **Keep this page open** - you'll need these values next

#### Part C: Update Entra ID with GCP URLs

**Now that GCP SSO profile is created, update Entra ID with correct values**:

1. **Return to Azure Portal**:
   - Navigate to: **Enterprise Applications** → **Google Cloud Platform - $GCP_ORG_DOMAIN**
   - Go to **Single sign-on**

2. **Update Basic SAML Configuration**:
   - Click **Edit** on **Basic SAML Configuration**
   - Replace with values from Part B Step 5:
     ```
     Identifier (Entity ID): google.com/a/$GCP_ORG_DOMAIN
     Reply URL (ACS URL): https://www.google.com/a/$GCP_ORG_DOMAIN/acs
     Sign on URL: https://www.google.com/a/$GCP_ORG_DOMAIN
     ```
   - Click **Save**

3. **Test SAML Connection**:
   - Scroll to bottom of Single sign-on page
   - Click **Test** button
   - Should redirect to GCP and back successfully
   - If successful, SAML configuration is working

#### Part D: Configure User Provisioning in Entra ID

**Sync Entra ID users to GCP Cloud Identity** (optional but recommended):

1. **Enable Provisioning**:
   - In Enterprise Application, go to **Provisioning**
   - Click **Get started**
   - **Provisioning Mode**: Automatic

2. **Configure Provisioning Scope**:
   - **Scope**: 
     - **Assigned users and groups** (recommended - sync only specific users)
     - OR **Sync all users and groups** (sync entire directory)

3. **Assign Users/Groups** (if using scoped provisioning):
   - Go to **Users and groups** → **Add user/group**
   - Add users: `$GCP_ADMIN_EMAIL`
   - **OR** Add Entra ID group containing GCP users
   - This controls which users are provisioned to GCP

4. **Start Provisioning**:
   - Go back to **Provisioning**
   - Click **Start provisioning**
   - **Sync frequency**: Every 40 minutes (default)
   - **Initial sync**: Can take 20-40 minutes
   - Monitor under **Provisioning logs**

5. **Verify Users Synced to GCP**:
   - After initial sync completes, go to: https://admin.google.com/ac/users
   - Should see provisioned users from Entra ID
   - Users will have @$GCP_ORG_DOMAIN email addresses

#### Part E: Assign SSO Profile in GCP

**Critical**: SSO profile must be assigned to org/group/user to work.

1. **Access Cloud Identity Admin Console**:
   - Navigate to: https://admin.google.com/
   - Go to: **Security** → **Authentication** → **SSO with third-party IdP**

2. **Assign SSO Profile**:
   - Find your **Microsoft Entra ID** SSO profile
   - Click **Assign to org units, groups, or users**
   - Choose assignment scope:
     - **Organization** (all users in org - recommended)
     - **Specific OU** (organizational unit)
     - **Specific group** (useful for phased migration)
     - **Specific users** (testing only)
   - Click **Assign**

3. **Verify Assignment**:
   - SSO profile should show as **Assigned** with scope
   - Users in scope will now be redirected to Microsoft login

#### Part F: Grant IAM Permissions to Synced Users

**After users are provisioned from Entra ID, grant them GCP IAM roles**:

1. **Via GCP Console** (recommended for viewing):
   - Navigate to: https://console.cloud.google.com/iam-admin/iam
   - **Organization level**: https://console.cloud.google.com/iam-admin/iam?organizationId=$GCP_ORG_ID
   - **Project level**: https://console.cloud.google.com/iam-admin/iam?project=$GCP_DEV_PROJECT_ID
   - Click **Grant Access**
   - **Add principals**: Enter user's email (e.g., `$GCP_ADMIN_EMAIL`)
   - **Assign roles**:
     - Organization Admin: `roles/resourcemanager.organizationAdmin`
     - Billing Admin: `roles/billing.admin`
     - Project Editor: `roles/editor`
   - Click **Save**

2. **Via gcloud CLI**:
   ```bash
   # Load configuration
   source config.sh
   
   # Grant organization admin role
   gcloud organizations add-iam-policy-binding $GCP_ORG_ID \
     --member="user:$GCP_ADMIN_EMAIL" \
     --role="roles/resourcemanager.organizationAdmin"
   
   # Grant billing admin
   gcloud organizations add-iam-policy-binding $GCP_ORG_ID \
     --member="user:$GCP_ADMIN_EMAIL" \
     --role="roles/billing.admin"
   
   # Grant project access
   gcloud projects add-iam-policy-binding $GCP_DEV_PROJECT_ID \
     --member="user:$GCP_ADMIN_EMAIL" \
     --role="roles/editor"
   
   gcloud projects add-iam-policy-binding $GCP_PROD_PROJECT_ID \
     --member="user:$GCP_ADMIN_EMAIL" \
     --role="roles/editor"
   ```

3. **Verify User Permissions**:
   ```bash
   # Check what roles a user has
   gcloud projects get-iam-policy $GCP_DEV_PROJECT_ID \
     --flatten="bindings[].members" \
     --filter="bindings.members:$GCP_ADMIN_EMAIL" \
     --format="table(bindings.role)"
   ```

#### Part G: Test M365 Authentication

1. **Browser Test** (test SAML redirect first):
   - Open **incognito/private browser** window
   - Navigate to: `https://accounts.google.com`
   - Enter your M365 email from config.sh: `$GCP_ADMIN_EMAIL`
   - **Should redirect** to: `https://login.microsoftonline.com`
   - **Entra ID Conditional Access** triggers:
     - MFA prompt (if enabled)
     - Device compliance checks
     - Location-based policies
     - Any other Conditional Access policies
   - After successful authentication, redirects back to GCP
   - **Success**: You're logged into GCP Console

2. **gcloud CLI Test**:
   ```bash
   # Load configuration
   source config.sh
   
   # Sign out current account
   gcloud auth revoke --all
   
   # Sign in with M365 account
   gcloud auth login $GCP_ADMIN_EMAIL
   
   # Browser opens → redirects to login.microsoftonline.com
   # Complete M365 authentication + MFA
   # Redirects back to complete gcloud auth
   
   # Verify authentication
   gcloud auth list
   # Should show: * $GCP_ADMIN_EMAIL (ACTIVE)
   
   # Test access
   gcloud organizations list
   gcloud projects list
   gcloud compute instances list --project=$GCP_DEV_PROJECT_ID
   ```

3. **Troubleshooting Failed Login**:
   - **"Account deleted"** → SSO profile not assigned (Part E)
   - **No redirect to Microsoft** → SAML profile not configured (Part B)
   - **"Access denied"** → User not provisioned (Part D) or missing IAM roles (Part F)
   - **MFA loop** → Conditional Access policy issue in Entra ID

**Expected Authentication Flow**:
```
1. User enters email: $GCP_ADMIN_EMAIL at accounts.google.com
   ↓
2. GCP recognizes domain has SAML SSO configured
   ↓
3. Redirects to Entra ID: login.microsoftonline.com
   ↓
4. User enters M365 password
   ↓
5. Entra ID Conditional Access evaluates:
   - MFA requirement
   - Device compliance
   - IP/location restrictions
   - Risk-based policies
   ↓
6. User completes MFA (if required)
   ↓
7. Entra ID generates SAML assertion
   ↓
8. SAML assertion sent to GCP ACS URL
   ↓
9. GCP validates SAML signature and claims
   ↓
10. User logged into GCP with IAM permissions
```

### Step 4: Create Native GCP Break-Glass Account

**Purpose**: Emergency access when M365 is unavailable or compromised.

**Option A: Cloud Identity Native Account** (Recommended)

1. **Create via Admin Console**:
   ```
   https://admin.google.com/ac/users
   ```
   
2. **User Details**:
   - First name: Use generic name (e.g., `Service`, `System`)
   - Last name: Use generic identifier (e.g., `Account`, `Admin`)
   - Email: Use obscure naming pattern to prevent identification
     - **Bad examples** (predictable): `breakglass-*`, `emergency-*`, `admin-*`
     - **Good examples** (obscure): `svc-<random-hash>@<DOMAIN>`, `sys-<uuid>@<DOMAIN>`
     - Example: `svc-xe7k9m@<YOUR-DOMAIN>` or `ops-tn4p8q@<YOUR-DOMAIN>`
   - Password: Generate strong password (store in Azure Key Vault)
   - Recovery email: Use another secure email (NOT primary admin)
   - Require password change: No (you control it)
   
   **Security Note**: Avoid predictable patterns like "breakglass", "emergency", "admin". Use random alphanumeric strings that don't reveal the account's purpose.
   
3. **Enable 2-Step Verification**:
   - **Mandatory** for security
   - Use hardware security key (YubiKey) recommended
   - Backup codes stored in Azure Key Vault

4. **Grant Organization Admin**:
   ```bash
   # Use $GCP_BREAKGLASS_EMAIL from config.sh (e.g., svc-xe7k9m@your-domain)
   gcloud organizations add-iam-policy-binding $GCP_ORG_ID \
     --member="user:$GCP_BREAKGLASS_EMAIL" \
     --role="roles/resourcemanager.organizationAdmin"
   
   gcloud organizations add-iam-policy-binding $GCP_ORG_ID \
     --member="user:$GCP_BREAKGLASS_EMAIL" \
     --role="roles/iam.organizationRoleAdmin"
   ```

**Option B: Service Account Break-Glass** (Alternative)

```bash
# Create service account with obscure name (avoid "breakglass", "emergency", "admin")
# Good examples: svc-automation, ops-sync, system-mgmt
gcloud iam service-accounts create svc-automation \
  --display-name="System Automation Service" \
  --description="Automated operations service account"

# Grant organization admin
gcloud organizations add-iam-policy-binding $GCP_ORG_ID \
  --member="serviceAccount:svc-automation@$GCP_DEV_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/resourcemanager.organizationAdmin"

# Create key (store securely in Azure Key Vault)
gcloud iam service-accounts keys create sa-key.json \
  --iam-account=svc-automation@$GCP_DEV_PROJECT_ID.iam.gserviceaccount.com

# Test authentication
gcloud auth activate-service-account \
  --key-file=sa-key.json

# IMPORTANT: Delete local key file after storing in vault
rm sa-key.json
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
   gcloud organizations add-iam-policy-binding $GCP_ORG_ID \
     --member="serviceAccount:terraform-automation@<DEV-PROJECT-ID>.iam.gserviceaccount.com" \
     --role="roles/resourcemanager.folderAdmin"
   
   gcloud organizations add-iam-policy-binding $GCP_ORG_ID \
     --member="serviceAccount:terraform-automation@<DEV-PROJECT-ID>.iam.gserviceaccount.com" \
     --role="roles/resourcemanager.projectCreator"
   ```

2. **GitHub Actions Service Account** (Already Implemented):
   ```bash
   # Extend to organization level
   gcloud organizations add-iam-policy-binding $GCP_ORG_ID \
     --member="serviceAccount:main-github-actions@<PROJECT-ID>.iam.gserviceaccount.com" \
     --role="roles/viewer"
   ```

3. **Monitoring & Logging Service Account**:
   ```bash
   gcloud iam service-accounts create monitoring-agent \
     --display-name="Monitoring and Logging Agent" \
     --project=<DEV-PROJECT-ID>
   
   gcloud organizations add-iam-policy-binding $GCP_ORG_ID \
     --member="serviceAccount:monitoring-agent@<DEV-PROJECT-ID>.iam.gserviceaccount.com" \
     --role="roles/logging.logWriter"
   
   gcloud organizations add-iam-policy-binding $GCP_ORG_ID \
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
- Domain: `$GCP_ORG_DOMAIN`
- M365 Tenant: Domain verified (for email/identity)
- GCP Organization: Domain verified (for Cloud Identity users)
- SAML SSO: Configured to redirect authentication to M365

**How They Coexist**:

1. **M365 Domain Records** (Existing):
   ```dns
   # MX records for email (M365 controls)
   $GCP_ORG_DOMAIN.  MX  10  $GCP_ORG_DOMAIN-sanitized.mail.protection.outlook.com
   
   # TXT record for M365 verification
   $GCP_ORG_DOMAIN.  TXT  "MS=msXXXXXXXX"
   
   # CNAME for Autodiscover
   autodiscover.$GCP_ORG_DOMAIN.  CNAME  autodiscover.outlook.com
   ```

2. **GCP Domain Verification** (REQUIRED):
   ```dns
   # TXT record for GCP domain verification (added to same DNS)
   $GCP_ORG_DOMAIN.  TXT  "google-site-verification=XXXXXXXXXXXXXXX"
   ```
   
   **Why needed**: Cloud Identity requires domain verification to create user accounts like `user@$GCP_ORG_DOMAIN`
   
   **How to add**:
   - Cloud Identity Admin Console → Domains → Verify domain
   - Copy the `google-site-verification` TXT record
   - Add to your DNS (where M365 MX records are)
   - Both M365 and GCP can verify the same domain via different TXT records

3. **Authentication Flow for M365 Users (SAML SSO)**:
   ```
   User enters: $GCP_ADMIN_EMAIL
   ↓
   GCP recognizes @$GCP_ORG_DOMAIN (verified domain)
   ↓
   SAML SSO configured → Redirects to login.microsoftonline.com
   ↓
   User authenticates with M365 password + MFA
   ↓
   Entra ID sends SAML assertion back to GCP
   ↓
   GCP validates assertion and grants access based on IAM bindings
   ```
   
   **Key Components**:
   - ✅ **Domain Verification**: Proves you own the domain (DNS TXT record)
   - ✅ **SAML SSO**: Controls WHERE users authenticate (redirects to Microsoft)
   - ✅ **IAM Permissions**: Controls WHAT users can access (organization/project roles)
   
   **All three are required** for M365 users to access GCP resources.

### Benefits of This Approach

- ✅ No DNS conflicts: Both platforms use different TXT records on same domain
- ✅ M365 controls email (MX records), GCP uses domain for identity
- ✅ No separate GCP passwords for M365 users (SAML authentication)
- ✅ M365 MFA and Conditional Access policies apply automatically
- ✅ Single identity across Microsoft and Google clouds
- ✅ Service accounts remain primary for automation
- ✅ Centralized user management in Entra ID
- ✅ Can revoke GCP access by removing user from Entra ID app assignment
- ✅ Domain verified in both places proves ownership, SAML controls authentication

## Part 4: Security Best Practices

### Break-Glass Account Management

**Storage**: Azure Key Vault (following your existing pattern)

```bash
# Load configuration
source config.sh

# Store emergency access credentials in Azure Key Vault
# Use obscure secret names that don't reveal their purpose
az keyvault secret set \
  --vault-name $AZURE_KEYVAULT_NAME \
  --name "gcp-svc-auth-password" \
  --value "<STRONG-PASSWORD>"

# Store 2FA backup codes
az keyvault secret set \
  --vault-name $AZURE_KEYVAULT_NAME \
  --name "gcp-svc-auth-2fa" \
  --value "<BACKUP-CODES>"

# Store service account key (if using Option B)
az keyvault secret set \
  --vault-name $AZURE_KEYVAULT_NAME \
  --name "gcp-svc-automation-key" \
  --file sa-key.json
```

### Testing Break-Glass Access

**Quarterly Test Procedure**:

1. **Retrieve credentials from Azure Key Vault**:
   ```bash
   az keyvault secret show \
     --vault-name $AZURE_KEYVAULT_NAME \
     --name "gcp-svc-auth-password" \
     --query value -o tsv
   ```

2. **Authenticate**:
   ```bash
   # Use $GCP_BREAKGLASS_EMAIL from config.sh
   gcloud auth login $GCP_BREAKGLASS_EMAIL
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
| SAML SSO (Entra ID) | $0/month | Included with M365 subscription |
| Service Accounts | $0/month | Unlimited |
| Workload Identity Pool | $0/month | No charge for federation |
| Compute/Storage | Variable | Standard GCP pricing |

**Total Setup Cost**: $0/month (excluding resource usage)

## Troubleshooting

### M365 Account Won't Authenticate

**Issue**: "Account has been deleted" or "Account not found" when trying to login with M365 account

**Root Cause**: SAML federation not configured, or user not assigned in Entra ID app

**Solution**:

1. **Verify SAML SSO is configured** (Step 3):
   ```bash
   # In Cloud Identity Admin Console:
   # Security → Authentication → SSO with third-party IdP
   # Should show Entra ID configuration
   ```

2. **Verify user assigned in Entra ID**:
   - Navigate to: https://portal.azure.com
   - **Enterprise Applications** → **Google Cloud Platform - $GCP_ORG_DOMAIN**
   - **Users and groups** → Ensure `$GCP_ADMIN_EMAIL` is assigned

3. **Verify IAM permissions exist**:
   ```bash
   source config.sh
   gcloud organizations get-iam-policy $GCP_ORG_ID | grep -i "$(echo $GCP_ADMIN_EMAIL | cut -d@ -f1)"
   # Should show: user:$GCP_ADMIN_EMAIL
   ```

4. **Test SSO in browser first**:
   - Open incognito: https://accounts.google.com
   - Enter: `$GCP_ADMIN_EMAIL` (from config.sh)
   - Should redirect to Microsoft login
   - If not, SAML federation is not configured

5. **Re-add IAM permissions if missing**:
   ```bash
   source config.sh
   gcloud organizations add-iam-policy-binding $GCP_ORG_ID \
     --member="user:$GCP_ADMIN_EMAIL" \
     --role="roles/resourcemanager.organizationAdmin"
   ```

### Break-Glass Account Locked

**Issue**: 2FA device lost or account locked

**Solution**:
1. Use your M365 admin account (`$GCP_ADMIN_EMAIL`) to reset
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
- [Configure Google Cloud for Single sign-on with Microsoft Entra ID](https://learn.microsoft.com/en-gb/entra/identity/saas-apps/google-apps-tutorial)
