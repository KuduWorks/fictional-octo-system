---
name: App Registration Change
about: Request approval for creating or modifying Azure AD application registration
title: "[APP-REG] "
labels: app-registration, needs-approval
assignees: ''
---

## 📝 Application Registration Information

### Application Details
**Application Name:** `<app-display-name>`

**Business Purpose:** _(50+ characters describing what this application does and why it's needed)_


**Environment:** _(e.g., Production, Staging, Development, Shared)_


### 👥 Application Owners (Minimum 2 Required)

> **🔒 GOVERNANCE REQUIREMENT:** All human owners MUST be from the approved governance/security list.
> See: `deployments/azure/app-registration/config/allowed-owners.json`
> 
> **Current approved owners:**
> - Security Administrators
> - Identity Administrators  
> - Compliance Officers
> 
> **Not on the list?** Submit PR to add yourself (requires CISO approval).

**Owner 1 (Human - Required from Approved List):**
- **Name:** 
- **Email:** _(Must be from approved governance list)_
- **Azure AD Object ID:** `<user-object-id>`
- **Role/Department:** 
- **Verified in approved list:** ☐ Yes

**Owner 2:**
- **Type:** ☐ Human User (from approved list)  ☐ Placeholder Service Principal
- **Name/Display Name:** 
- **Email (if human):** _(Must be from approved governance list)_
- **Azure AD Object ID:** `<user-or-sp-object-id>`
- **Role/Department (if human):** 
- **Verified in approved list:** ☐ Yes ☐ N/A (placeholder)

> **Note:** If using a placeholder service principal, you MUST provide justification below.

#### ⚠️ Placeholder Service Principal Justification (if applicable)
> **Required if Owner 2 is a service principal. Minimum 50 characters.**
> Explain:
> - Why 2 human owners are not available
> - Timeline for replacing placeholder with human owner
> - Business context requiring application creation before owners identified
>
> Placeholder service principals are reviewed quarterly (Q2/Q4 first Monday).
> Placeholders existing >6 months will be escalated to leadership.

<details>
<summary>📋 Placeholder Justification</summary>

```
[Provide detailed justification here - minimum 50 characters]
```

</details>

---

## 🔐 Permissions & Risk Assessment

### Application Type & Access Pattern

**Sign-in Audience:**
- ☐ AzureADMyOrg (Single tenant - This organization only)
- ☐ AzureADMultipleOrgs (Multi-tenant - Any Azure AD directory)
- ☐ AzureADandPersonalMicrosoftAccount (Azure AD + Personal Microsoft accounts)
- ☐ PersonalMicrosoftAccount (Personal Microsoft accounts only)

**Authentication Method:**
- ☐ Client Secret (password-based)
- ☐ Certificate (recommended for production)
- ☐ Federated Identity (OIDC with GitHub Actions / Kubernetes)
- ☐ Managed Identity (recommended for Azure-hosted apps)

### Microsoft Graph API Permissions

> **Instructions:**
> - List ALL Microsoft Graph permissions requested
> - Include permission ID, type (Delegated/Application), and permission name
> - HIGH-RISK permissions (ending in `.All`) require 100+ character justification
> - See [Microsoft Graph permissions reference](https://learn.microsoft.com/en-us/graph/permissions-reference)

| Permission Name | Permission ID | Type | Risk Level | Justification (Required for HIGH risk) |
|-----------------|---------------|------|------------|----------------------------------------|
| User.Read | 123e4567-... | Delegated | LOW | _(Optional for LOW/MEDIUM risk)_ |
| _Example: Directory.ReadWrite.All_ | _12345..._ | _Application_ | _**HIGH**_ | _**Required**: Detailed justification min 100 chars..._ |
| | | | | |
| | | | | |

> **Risk Classification:**
> - **HIGH**: Permissions ending in `.All` (broad tenant-wide access) - 100+ char justification REQUIRED
> - **MEDIUM**: Application permissions without `.All` suffix - Justification recommended
> - **LOW**: Delegated permissions - Document blast radius if sensitive

<details>
<summary>🔍 How to find Permission IDs</summary>

```bash
# Find Microsoft Graph Service Principal
az ad sp list --query "[?appId=='00000003-0000-0000-c000-000000000000'].{DisplayName:displayName, ObjectId:id}" --output table

# List all Microsoft Graph permissions
az ad sp show --id 00000003-0000-0000-c000-000000000000 --query "appRoles[].{Value:value, Id:id, DisplayName:displayName}" --output table

# Or use PowerShell
Get-AzureADServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'" | Select-Object -ExpandProperty AppRoles | Select-Object Value, Id, DisplayName
```

</details>

### Azure Resource Manager (ARM) Permissions (if applicable)

| Permission Name | Permission ID | Type | Justification |
|-----------------|---------------|------|---------------|
| | | | |

### Custom API Permissions (if applicable)

| API Name | Resource App ID | Permission Name | Permission ID | Type | Justification |
|----------|-----------------|-----------------|---------------|------|---------------|
| | | | | | |

---

## 🔒 Security Configuration

### Secrets & Credentials

**Secret Rotation Policy:** _(Default: 90 days. Range: 30-730 days)_


**Certificate Authentication:** ☐ Yes  ☐ No

<details>
<summary>Certificate Details (if applicable)</summary>

**Certificate Type:** _(e.g., Self-signed, CA-issued)_

**Certificate Expiration:** `YYYY-MM-DD`

**Certificate Thumbprint:** `<thumbprint>`

**Key Vault Storage:** ☐ Yes - Key Vault ID: `<kv-id>`  ☐ No

</details>

### Federated Identity (OIDC)

**GitHub Actions OIDC:** ☐ Yes  ☐ No

<details>
<summary>GitHub OIDC Configuration (if applicable)</summary>

**GitHub Organization:** `<org-name>`

**GitHub Repository:** `<repo-name>`

**Branch:** `<branch-name>` _(Default: main)_

</details>

**Kubernetes OIDC:** ☐ Yes  ☐ No

<details>
<summary>Kubernetes OIDC Configuration (if applicable)</summary>

**Issuer URL:** `<kubernetes-oidc-issuer-url>`

**Namespace:** `<namespace>`

**Service Account:** `<service-account-name>`

</details>

### Key Vault Integration

**Store secrets in Key Vault:** ☐ Yes  ☐ No

<details>
<summary>Key Vault Details (if applicable)</summary>

**Key Vault ID:** `<key-vault-resource-id>`

**Secrets to store:**
- ☐ Client ID
- ☐ Client Secret
- ☐ Tenant ID

</details>

---

## 🌐 Optional Configurations

### API Exposure (If this app exposes an API)

**Expose API:** ☐ Yes  ☐ No

<details>
<summary>API Exposure Configuration</summary>

**OAuth2 Scopes:**

| Scope Value | Admin Consent Display Name | Admin Consent Description | User Consent Display Name | User Consent Description |
|-------------|----------------------------|---------------------------|---------------------------|--------------------------|
| | | | | |

</details>

### Application Roles

**Define App Roles:** ☐ Yes  ☐ No

<details>
<summary>App Roles Configuration</summary>

| Role Value | Display Name | Description | Allowed Member Types |
|------------|--------------|-------------|----------------------|
| | | | ☐ User ☐ Application |

</details>

### Redirect URIs (for web/SPA apps)

**Redirect URIs:**
```
https://example.com/auth/callback
https://localhost:3000/auth/callback (dev only)
```

**Implicit Grant Flow:**
- ☐ Access Tokens
- ☐ ID Tokens
- ☐ None (Recommended: use authorization code flow instead)

### Service Principal Configuration

**App Role Assignment Required:** ☐ Yes (users must be assigned via role)  ☐ No

**Notification Emails:** _(Comma-separated emails for service principal notifications)_


**Enterprise Features:** ☐ Enable  ☐ Disable

**Gallery Features:** ☐ Enable  ☐ Disable

---

## 🚀 Deployment & Change Management

### Change Type
- ☐ New Application Registration
- ☐ Permission Change (Add/Remove)
- ☐ Owner Change (Add/Remove)
- ☐ Configuration Change (Secrets, Certificates, Redirect URIs)
- ☐ Decommission (Delete Application)

### Deployment Timeline

**Requested Deployment Date:** `YYYY-MM-DD`

**Business Justification for Timeline:** _(Why is this timeline needed?)_


**Rollback Plan:** _(How will you rollback if deployment fails?)_


### Testing & Validation

**Testing Environment:** _(Where was this tested? Dev/Staging subscription?)_


**Test Results:** _(Summary of testing performed)_


---

## 🛡️ Compliance & Governance

### Admin Consent

**Grant Admin Consent:** ☐ Yes  ☐ No

> **Note:** Admin consent automatically grants permissions. Requires administrator privileges.
> Only use for service-to-service applications with Application permissions.

**Admin Consent Justification:** _(Why is admin consent needed? Who approved?)_


### Tags & Metadata

**Department/Business Unit:** 

**Cost Center:** 

**Project/Product:** 

**Support Contact:** 

**Additional Tags:**
```hcl
tags = {
  Department = ""
  CostCenter = ""
  Project    = ""
  Environment = ""
}
```

---

## ⚠️ Manual Override (Emergency Use Only)

> **WARNING:** Manual overrides bypass automated validation.
> Use ONLY for:
> - Validation script false positives
> - Emergency business needs
> - Technical limitations preventing automated validation
>
> Manual overrides are logged and reviewed quarterly.

**Manual Override Requested:** ☐ Yes  ☐ No

<details>
<summary>Manual Override Justification (Required if override requested)</summary>

> **Minimum 50 characters required.**

```
[Explain why validation is being bypassed, risk assessment, mitigation plan, approval authority]
```

</details>

---

## ✅ Pre-Submission Checklist

Before submitting this PR, confirm:

- [ ] I have read the [Approval Workflow Documentation](../deployments/azure/app-registration/APPROVAL_WORKFLOW.md)
- [ ] At least 2 owners specified (minimum 1 human user)
- [ ] If using placeholder service principal, 50+ character justification provided
- [ ] All HIGH-RISK permissions (ending in `.All`) have 100+ character justifications
- [ ] Permission IDs and types verified against Microsoft documentation
- [ ] Authentication method selected and configured
- [ ] Secret rotation policy specified (if using secrets)
- [ ] Testing completed in non-production environment
- [ ] Rollback plan documented
- [ ] Admin consent justification provided (if requesting auto-consent)
- [ ] Tags and metadata completed for cost tracking
- [ ] Security review completed for HIGH-RISK permissions

---

## 📋 Validation Status

> **This section will be auto-populated by GitHub Actions workflows. Do not edit manually.**

### Owner Verification
```
Status: ⏳ Pending validation...
```

### Permission Risk Assessment
```
Status: ⏳ Pending validation...
```

### Terraform Plan
```
Status: ⏳ Pending validation...
```

---

## 👀 Reviewer Guide

### For Reviewers: What to Check

1. **Owner Validation**
   - At least 2 owners with minimum 1 human user
   - All owners have ENABLED Azure AD accounts
   - Placeholder justification substantive if service principal used

2. **Permission Risk Assessment**
   - HIGH-RISK permissions (`.All` suffix) have 100+ char justifications
   - Justifications include business need, alternatives considered, approval details
   - Principle of least privilege followed

3. **Security Configuration**
   - Certificate auth or managed identity used for production apps
   - Secret rotation policy appropriate (90-180 days recommended)
   - Key Vault storage enabled for secrets

4. **Change Management**
   - Testing evidence provided
   - Rollback plan documented
   - Timeline justified

5. **Compliance**
   - Admin consent justified if requested
   - Tags complete for cost tracking
   - Manual override substantive if used

### Approval Requirements

- **Normal Changes:** 2 reviewers required
- **Auto-Remediation:** 1 reviewer required (for drift detection fixes)
- **HIGH-RISK Permissions:** Security team review recommended

---

## 📚 Additional Resources

- [Microsoft Graph Permissions Reference](https://learn.microsoft.com/en-us/graph/permissions-reference)
- [Azure AD App Registration Best Practices](https://learn.microsoft.com/en-us/azure/active-directory/develop/security-best-practices-for-app-registration)
- [Placeholder Service Principal Module Documentation](../deployments/azure/app-registration/modules/placeholder-service-principal/README.md)
- [Permission Risk Classification Matrix](../deployments/azure/app-registration/permission-policies/graph-permissions-risk-matrix.json)
- [Approval Workflow Documentation](../deployments/azure/app-registration/APPROVAL_WORKFLOW.md)

---

**By submitting this PR, I acknowledge that:**
- I have provided accurate information
- I understand the security implications of requested permissions
- I will respond to reviewer feedback promptly
- I will replace placeholder service principals with human owners as soon as possible
- I acknowledge quarterly reviews for placeholder service principals and HIGH-RISK permissions
