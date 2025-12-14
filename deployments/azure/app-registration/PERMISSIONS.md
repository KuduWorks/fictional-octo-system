# Microsoft Graph Permissions Reference Guide

Quick reference for common Microsoft Graph permission IDs used in Azure AD app registrations.

## 🔍 How to Use This Guide

Each permission has:
- **ID**: The GUID to use in Terraform
- **Type**: `Scope` (delegated) or `Role` (application)
- **Name**: The permission string value
- **Description**: What it allows

## ⚠️ HIGH-RISK PERMISSIONS - EXTREME CAUTION REQUIRED

> **🚨 CRITICAL: The following permissions grant extensive control over your entire organization.**
> 
> **These permissions should ONLY be granted after:**
> 1. ✋ Security team review and written approval
> 2. 📝 Detailed justification documenting business need
> 3. 🔍 Evaluation of less privileged alternatives
> 4. 👥 Sign-off from CISO or equivalent authority
> 5. 📅 Scheduled quarterly reviews
> 6. 🔔 Monitoring and alerting enabled

### 🔴 Critical High-Risk Permissions

| Permission | Risk Level | What It Can Do |
|------------|------------|----------------|
| **Application.ReadWrite.All** | 🔴 CRITICAL | Delete/modify ALL app registrations and service principals |
| **AppRoleAssignment.ReadWrite.All** | 🔴 CRITICAL | Grant ANY permission to ANY application (privilege escalation) |
| **Directory.ReadWrite.All** | 🔴 CRITICAL | Full read/write access to ALL directory objects |
| **RoleManagement.ReadWrite.Directory** | 🔴 CRITICAL | Assign ANY role to ANY user (including Global Admin) |
| **Directory.AccessAsUser.All** | 🔴 HIGH | Perform directory operations as signed-in user |
| **Directory.Read.All** | 🔴 HIGH | Read ALL directory data (full org visibility) |

**Why these are dangerous:**
- Can be used for privilege escalation attacks
- Enable complete takeover of your Azure AD tenant
- Allow data exfiltration of entire organization
- Can disable security controls
- Difficult to detect misuse without proper monitoring

**Default Answer: NO** - Unless there is an overwhelming business need with executive approval.

---

## 📊 User Permissions

### User.Read
- **ID**: `e1fe6dd8-ba31-4d61-89e7-88639da4683d`
- **Type**: Scope (Delegated)
- **Description**: Sign in and read user profile
- **Admin Consent**: No
- **Use Case**: Basic user authentication

```hcl
{
  id    = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
  type  = "Scope"
  value = "User.Read"
}
```

### User.Read.All
- **ID**: `df021288-bdef-4463-88db-98f22de89214`
- **Type**: Role (Application)
- **Description**: Read all users' full profiles
- **Admin Consent**: Yes (Required)
- **Use Case**: User synchronization services

```hcl
{
  id    = "df021288-bdef-4463-88db-98f22de89214"
  type  = "Role"
  value = "User.Read.All"
}
```

### User.ReadWrite.All
- **ID**: `741f803b-c850-494e-b5df-cde7c675a1ca`
- **Type**: Role (Application)
- **Description**: Read and write all users' full profiles
- **Admin Consent**: Yes (Required)
- **Use Case**: User provisioning and management

```hcl
{
  id    = "741f803b-c850-494e-b5df-cde7c675a1ca"
  type  = "Role"
  value = "User.ReadWrite.All"
}
```

### User.ReadBasic.All
- **ID**: `97235f07-e226-4f63-ace3-39588e11d3a1`
- **Type**: Scope (Delegated)
- **Description**: Read all users' basic profiles
- **Admin Consent**: No
- **Use Case**: People picker, basic user lookups

## 👥 Group Permissions

### Group.Read.All
- **ID**: `5b567255-7703-4780-807c-7be8301ae99b`
- **Type**: Role (Application)
- **Description**: Read all groups
- **Admin Consent**: Yes (Required)

```hcl
{
  id    = "5b567255-7703-4780-807c-7be8301ae99b"
  type  = "Role"
  value = "Group.Read.All"
}
```

### Group.ReadWrite.All
- **ID**: `62a82d76-70ea-41e2-9197-370581804d09`
- **Type**: Role (Application)
- **Description**: Read and write all groups
- **Admin Consent**: Yes (Required)

```hcl
{
  id    = "62a82d76-70ea-41e2-9197-370581804d09"
  type  = "Role"
  value = "Group.ReadWrite.All"
}
```

## 📁 Directory Permissions

### Directory.Read.All 🔴 HIGH-RISK
- **ID**: `7ab1d382-f21e-4acd-a863-ba3e13f7da61`
- **Type**: Role (Application)
- **Description**: Read ALL directory data across entire organization
- **Admin Consent**: Yes (Required)
- **Risk Level**: 🔴 HIGH
- **Use Case**: Reading organizational structure
- **⚠️ WARNING**: Grants read access to ALL users, groups, applications, devices, and directory objects. Can expose sensitive organizational data.

```hcl
{
  id    = "7ab1d382-f21e-4acd-a863-ba3e13f7da61"
  type  = "Role"
  value = "Directory.Read.All"
}
```

### Directory.ReadWrite.All 🔴 CRITICAL
- **ID**: `19dbc75e-c2e2-444c-a770-ec69d8559fc7`
- **Type**: Role (Application)
- **Description**: Read and write ALL directory data
- **Admin Consent**: Yes (Required)
- **Risk Level**: 🔴 CRITICAL
- **⚠️ WARNING**: FULL CONTROL over directory. Can create/modify/delete ANY users, groups, applications, devices. Enables complete tenant takeover.

### Directory.AccessAsUser.All 🔴 HIGH-RISK
- **ID**: `0e263e50-5827-48a4-b97c-d940288653c7`
- **Type**: Scope (Delegated)
- **Description**: Access directory as the signed-in user
- **Admin Consent**: Yes (Required)
- **Risk Level**: 🔴 HIGH
- **⚠️ WARNING**: Allows app to impersonate user for directory operations. Inherits ALL permissions of signed-in user.

```hcl
{
  id    = "0e263e50-5827-48a4-b97c-d940288653c7"
  type  = "Scope"
  value = "Directory.AccessAsUser.All"
}
```

## 📧 Mail Permissions

### Mail.Read
- **ID**: `810c84a8-4a9e-49e6-bf7d-12d183f40d01`
- **Type**: Scope (Delegated)
- **Description**: Read user mail
- **Admin Consent**: No

```hcl
{
  id    = "810c84a8-4a9e-49e6-bf7d-12d183f40d01"
  type  = "Scope"
  value = "Mail.Read"
}
```

### Mail.Send
- **ID**: `e383f46e-2787-4529-855e-0e479a3ffac0`
- **Type**: Scope (Delegated)
- **Description**: Send mail as a user
- **Admin Consent**: No

```hcl
{
  id    = "e383f46e-2787-4529-855e-0e479a3ffac0"
  type  = "Scope"
  value = "Mail.Send"
}
```

### Mail.ReadWrite
- **ID**: `024d486e-b451-40bb-833d-3e66d98c5c73`
- **Type**: Scope (Delegated)
- **Description**: Read and write user mail
- **Admin Consent**: No

## 📅 Calendar Permissions

### Calendars.Read
- **ID**: `465a38f9-76ea-45b9-9f34-9e8b0d4b0b42`
- **Type**: Scope (Delegated)
- **Description**: Read user calendars
- **Admin Consent**: No

### Calendars.ReadWrite
- **ID**: `1ec239c2-d7c9-4623-a91a-a9775856bb36`
- **Type**: Scope (Delegated)
- **Description**: Read and write user calendars
- **Admin Consent**: No

## 📝 Files Permissions

### Files.Read.All
- **ID**: `01d4889c-1287-42c6-ac1f-5d1e02578ef6`
- **Type**: Scope (Delegated)
- **Description**: Read all files that user can access
- **Admin Consent**: No

### Files.ReadWrite.All
- **ID**: `863451e7-0667-486c-a5d6-d135439485f0`
- **Type**: Scope (Delegated)
- **Description**: Read and write all files that user can access
- **Admin Consent**: No

## 👤 Profile Permissions

### email
- **ID**: `64a6cdd6-aab1-4aaf-94b8-3cc8405e90d0`
- **Type**: Scope (Delegated)
- **Description**: View users' email address
- **Admin Consent**: No

```hcl
{
  id    = "64a6cdd6-aab1-4aaf-94b8-3cc8405e90d0"
  type  = "Scope"
  value = "email"
}
```

### profile
- **ID**: `14dad69e-099b-42c9-810b-d002981feec1`
- **Type**: Scope (Delegated)
- **Description**: View users' basic profile
- **Admin Consent**: No

```hcl
{
  id    = "14dad69e-099b-42c9-810b-d002981feec1"
  type  = "Scope"
  value = "profile"
}
```

### openid
- **ID**: `37f7f235-527c-4136-accd-4a02d197296e`
- **Type**: Scope (Delegated)
- **Description**: Sign users in
- **Admin Consent**: No

## 🔐 Security Permissions

### SecurityEvents.Read.All
- **ID**: `bf394140-e372-4bf9-a898-299cfc7564e5`
- **Type**: Role (Application)
- **Description**: Read organization's security events
- **Admin Consent**: Yes (Required)

### SecurityEvents.ReadWrite.All
- **ID**: `d903a879-88e0-4c09-b0c9-82f6a1333f84`
- **Type**: Role (Application)
- **Description**: Read and update organization's security events
- **Admin Consent**: Yes (Required)

## 📊 Audit Log Permissions

### AuditLog.Read.All
- **ID**: `b0afded3-3588-46d8-8b3d-9842eff778da`
- **Type**: Role (Application)
- **Description**: Read all audit log data
- **Admin Consent**: Yes (Required)

```hcl
{
  id    = "b0afded3-3588-46d8-8b3d-9842eff778da"
  type  = "Role"
  value = "AuditLog.Read.All"
}
```

## 🏢 Organization Permissions

### Organization.Read.All
- **ID**: `498476ce-e0fe-48b0-b801-37ba7e2685c6`
- **Type**: Role (Application)
- **Description**: Read organization information
- **Admin Consent**: Yes (Required)

### Organization.ReadWrite.All
- **ID**: `292d869f-3427-49a8-9dab-8c70152b74e9`
- **Type**: Role (Application)
- **Description**: Read and write organization information
- **Admin Consent**: Yes (Required)

## 🛡️ Policy Permissions

### Policy.Read.All
- **ID**: `246dd0d5-5bd0-4def-940b-0421030a5b68`
- **Type**: Role (Application)
- **Description**: Read organization's policies
- **Admin Consent**: Yes (Required)

### Policy.ReadWrite.ConditionalAccess
- **ID**: `01c0a623-fc9b-48e9-b794-0756f8e8f067`
- **Type**: Role (Application)
- **Description**: Read and write conditional access policies
- **Admin Consent**: Yes (Required)

## � Role Management Permissions

### RoleManagement.Read.Directory
- **ID**: `483bed4a-2ad3-4361-a73b-c83ccdbdc53c`
- **Type**: Role (Application)
- **Description**: Read role-based access control (RBAC) settings
- **Admin Consent**: Yes (Required)
- **Use Case**: Audit role assignments and permissions

### RoleManagement.ReadWrite.Directory 🔴 CRITICAL
- **ID**: `9e3f62cf-ca93-4989-b6ce-bf83c28f9fe8`
- **Type**: Role (Application)
- **Description**: Read and write role-based access control (RBAC) settings
- **Admin Consent**: Yes (Required)
- **Risk Level**: 🔴 CRITICAL
- **⚠️ WARNING**: Can assign ANY Azure AD role to ANY user, including Global Administrator. Enables immediate privilege escalation to tenant-wide admin. One of the most dangerous permissions available.

```hcl
{
  id    = "9e3f62cf-ca93-4989-b6ce-bf83c28f9fe8"
  type  = "Role"
  value = "RoleManagement.ReadWrite.Directory"
}
```

**Common attack scenario:**
1. App granted this permission
2. App assigns Global Admin role to compromised account
3. Attacker has full tenant control
4. Can disable all security measures

## �🔑 Application Permissions

### Application.Read.All
- **ID**: `9a5d68dd-52b0-4cc2-bd40-abcf44ac3a30`
- **Type**: Role (Application)
- **Description**: Read all applications
- **Admin Consent**: Yes (Required)
- **Use Case**: Inventory and compliance scanning

### Application.ReadWrite.All 🔴 CRITICAL
- **ID**: `1bfefb4e-e0b5-418b-a88f-73c46d2cc8e9`
- **Type**: Role (Application)
- **Description**: Read and write ALL applications and service principals
- **Admin Consent**: Yes (Required)
- **Risk Level**: 🔴 CRITICAL
- **⚠️ WARNING**: Can DELETE any app registration or service principal. Can modify credentials of ANY application. Enables privilege escalation by creating apps with elevated permissions.

```hcl
{
  id    = "1bfefb4e-e0b5-418b-a88f-73c46d2cc8e9"
  type  = "Role"
  value = "Application.ReadWrite.All"
}
```

### AppRoleAssignment.ReadWrite.All 🔴 CRITICAL
- **ID**: `06b708a9-e830-4db3-a914-8e69da51d44f`
- **Type**: Role (Application)
- **Description**: Manage app permission grants and app role assignments
- **Admin Consent**: Yes (Required)
- **Risk Level**: 🔴 CRITICAL
- **⚠️ WARNING**: ULTIMATE PRIVILEGE ESCALATION permission. Can grant ANY permission to ANY application, including itself. Can assign ANY app role to ANY user/app. Effectively bypasses all permission controls.

```hcl
{
  id    = "06b708a9-e830-4db3-a914-8e69da51d44f"
  type  = "Role"
  value = "AppRoleAssignment.ReadWrite.All"
}
```

## 🌐 SharePoint Permissions

### Sites.Read.All
- **ID**: `332a536c-c7ef-4017-ab91-336970924f0d`
- **Type**: Role (Application)
- **Description**: Read items in all site collections
- **Admin Consent**: Yes (Required)

### Sites.ReadWrite.All
- **ID**: `9492366f-7969-46a4-8d15-ed1a20078fff`
- **Type**: Role (Application)
- **Description**: Read and write items in all site collections
- **Admin Consent**: Yes (Required)

## 💬 Teams Permissions

### Team.ReadBasic.All
- **ID**: `2280dda6-0bfd-44ee-a2f4-cb867cfc4c1e`
- **Type**: Role (Application)
- **Description**: Read the names and descriptions of teams
- **Admin Consent**: Yes (Required)

### TeamSettings.Read.All
- **ID**: `242607bd-1d2c-432c-82eb-bdb27baa23ab`
- **Type**: Role (Application)
- **Description**: Read all teams' settings
- **Admin Consent**: Yes (Required)

## 🔎 How to Find More Permission IDs

### Using Azure CLI

```bash
# List all delegated permissions (Scopes)
az ad sp show --id 00000003-0000-0000-c000-000000000000 \
  --query "oauth2PermissionScopes[].{ID:id, Name:value, Type:'Scope', AdminConsent:adminConsentDisplayName}" \
  --output table

# List all application permissions (Roles)
az ad sp show --id 00000003-0000-0000-c000-000000000000 \
  --query "appRoles[].{ID:id, Name:value, Type:'Role', AdminConsent:displayName}" \
  --output table

# Search for specific permission
az ad sp show --id 00000003-0000-0000-c000-000000000000 \
  --query "oauth2PermissionScopes[?contains(value, 'User')].{ID:id, Name:value}" \
  --output table
```

### Using PowerShell

```powershell
# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Application.Read.All"

# Get Microsoft Graph Service Principal
$graphSP = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"

# List delegated permissions
$graphSP.Oauth2PermissionScopes | Select-Object Id, Value, AdminConsentDisplayName | Format-Table

# List application permissions
$graphSP.AppRoles | Select-Object Id, Value, DisplayName | Format-Table

# Search for specific permission
$graphSP.Oauth2PermissionScopes | Where-Object { $_.Value -like "*User*" }
```

## 📚 References

- [Microsoft Graph Permissions Reference](https://learn.microsoft.com/en-us/graph/permissions-reference)
- [Delegated vs Application Permissions](https://learn.microsoft.com/en-us/azure/active-directory/develop/v2-permissions-and-consent)
- [Azure AD App Permissions](https://learn.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-auth-code-flow)

## ⚠️ Important Notes

1. **HIGH-RISK PERMISSIONS**: The 6 permissions listed at the top require CISO-level approval, detailed justification, and quarterly reviews. Default answer: NO.
2. **Application Permissions (Role)**: Always require admin consent
3. **Delegated Permissions (Scope)**: May require admin consent depending on the permission
4. **Least Privilege**: Only request permissions your app actually needs. Never request high-risk permissions "just in case."
5. **Regular Review**: Audit permissions quarterly (monthly for high-risk). Remove unused permissions immediately.
6. **Documentation**: Document why each permission is needed, including security review tickets and approval dates
7. **Monitoring**: Enable audit logging and alerts for all high-risk permission usage
8. **Privilege Escalation**: Be especially careful with AppRoleAssignment.ReadWrite.All and RoleManagement.ReadWrite.Directory - these enable complete tenant takeover

## 💡 Common Permission Combinations

### Web App with User Sign-In
```hcl
graph_permissions = [
  { id = "e1fe6dd8-ba31-4d61-89e7-88639da4683d", type = "Scope", value = "User.Read" },
  { id = "64a6cdd6-aab1-4aaf-94b8-3cc8405e90d0", type = "Scope", value = "email" },
  { id = "14dad69e-099b-42c9-810b-d002981feec1", type = "Scope", value = "profile" }
]
```

### Background Service Reading Users
```hcl
graph_permissions = [
  { id = "df021288-bdef-4463-88db-98f22de89214", type = "Role", value = "User.Read.All" },
  { id = "5b567255-7703-4780-807c-7be8301ae99b", type = "Role", value = "Group.Read.All" }
]
grant_admin_consent = true
```

### Audit and Compliance App
```hcl
graph_permissions = [
  { id = "b0afded3-3588-46d8-8b3d-9842eff778da", type = "Role", value = "AuditLog.Read.All" },
  { id = "7ab1d382-f21e-4acd-a863-ba3e13f7da61", type = "Role", value = "Directory.Read.All" }
]
grant_admin_consent = true
```
