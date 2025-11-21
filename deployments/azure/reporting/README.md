# Azure Reporting Scripts

This folder contains PowerShell and SDK-based scripts for reporting on Azure IAM, management groups, subscriptions, and access controls.

## Purpose
- Audit and export IAM assignments, users, groups, and service principals across management groups and subscriptions
- Generate reports in CSV and JSON formats for compliance and governance

## Scripts
- `Export-AzureIAMReport.ps1`: Export all role assignments and principal details from management groups and subscriptions

## Usage
The script automatically checks for required modules and installs them if missing. Simply run:

```powershell
.\Export-AzureIAMReport.ps1
```

When prompted:
1. Enter your Azure Tenant ID
2. Authenticate to Azure (browser-based login)
3. Authenticate to Microsoft Graph (browser-based login)

The script will:
- Query all management groups and subscriptions
- Retrieve role assignments for each scope
- Enrich principal details using Microsoft Graph SDK
- Export results with timestamp in filename

## Output
Reports are saved with timestamps:
- `azure_access_report_YYYYMMDD-HHMMSS.csv`
- `azure_access_report_YYYYMMDD-HHMMSS.json`

## Required Modules (auto-installed if missing)
- `Az.Accounts` - Azure authentication
- `Az.Resources` - Azure role assignments
- `Microsoft.Graph.Authentication` - Graph authentication
- `Microsoft.Graph.Users` - User details
- `Microsoft.Graph.Groups` - Group details
- `Microsoft.Graph.Applications` - Service principal details

## Notes
- Scripts are intended for audit, compliance, and governance use cases.
- You may need additional permissions to access all role assignments and principal details.
