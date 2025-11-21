# Export-AzureIAMReport.ps1
# Reports all Azure subscriptions, management groups, and IAM assignments to CSV and JSON with timestamped filenames.
# Enriches principal details using Microsoft Graph SDK and verifies required modules.

# Verify required modules
$requiredModules = @("Az.Accounts", "Az.Resources", "Microsoft.Graph.Authentication", "Microsoft.Graph.Users", "Microsoft.Graph.Groups", "Microsoft.Graph.Applications")
foreach ($module in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Write-Host "Installing module: $module"
        Install-Module $module -Scope CurrentUser -Force
    }
    # Import the module if not already loaded
    if (-not (Get-Module -Name $module)) {
        Write-Host "Importing module: $module"
        Import-Module $module -Force
    }
}

# Prompt for tenant ID
$tenantId = Read-Host "Enter your Azure Tenant ID"

# Connect to Azure and Microsoft Graph using the specified tenant
Connect-AzAccount -Tenant $tenantId
Connect-MgGraph -TenantId $tenantId -Scopes "Directory.Read.All" -NoWelcome

# Get all management groups
$mgGroups = Get-AzManagementGroup

# Get all subscriptions
$subscriptions = Get-AzSubscription

$results = @()

# Query IAM assignments for management groups
foreach ($mg in $mgGroups) {
    $mgAssignments = Get-AzRoleAssignment -Scope $mg.Id
    foreach ($assignment in $mgAssignments) {
        # Enrich principal details using Graph SDK
        $principalName = ""
        switch ($assignment.ObjectType) {
            "User"            { $principal = Get-MgUser -UserId $assignment.ObjectId -ErrorAction SilentlyContinue; $principalName = $principal.DisplayName }
            "Group"           { $principal = Get-MgGroup -GroupId $assignment.ObjectId -ErrorAction SilentlyContinue; $principalName = $principal.DisplayName }
            "ServicePrincipal"{ $principal = Get-MgServicePrincipal -ServicePrincipalId $assignment.ObjectId -ErrorAction SilentlyContinue; $principalName = $principal.DisplayName }
            default           { $principalName = $assignment.DisplayName }
        }
        $results += [PSCustomObject]@{
            ScopeType       = "ManagementGroup"
            ScopeName       = $mg.DisplayName
            ScopeId         = $mg.Id
            ObjectType      = $assignment.ObjectType
            ObjectId        = $assignment.ObjectId
            PrincipalName   = $principalName
            Role            = $assignment.RoleDefinitionName
        }
    }
}

# Query IAM assignments for subscriptions
foreach ($sub in $subscriptions) {
    Set-AzContext -SubscriptionId $sub.Id | Out-Null
    $subAssignments = Get-AzRoleAssignment
    foreach ($assignment in $subAssignments) {
        # Enrich principal details using Graph SDK
        $principalName = ""
        switch ($assignment.ObjectType) {
            "User"            { $principal = Get-MgUser -UserId $assignment.ObjectId -ErrorAction SilentlyContinue; $principalName = $principal.DisplayName }
            "Group"           { $principal = Get-MgGroup -GroupId $assignment.ObjectId -ErrorAction SilentlyContinue; $principalName = $principal.DisplayName }
            "ServicePrincipal"{ $principal = Get-MgServicePrincipal -ServicePrincipalId $assignment.ObjectId -ErrorAction SilentlyContinue; $principalName = $principal.DisplayName }
            default           { $principalName = $assignment.DisplayName }
        }
        $results += [PSCustomObject]@{
            ScopeType       = "Subscription"
            ScopeName       = $sub.Name
            ScopeId         = $sub.Id
            ObjectType      = $assignment.ObjectType
            ObjectId        = $assignment.ObjectId
            PrincipalName   = $principalName
            Role            = $assignment.RoleDefinitionName
        }
    }
}

# Get current date and time for filenames
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$csvFile = "azure_access_report_$timestamp.csv"
$jsonFile = "azure_access_report_$timestamp.json"

# Export to CSV
$results | Export-Csv -Path $csvFile -NoTypeInformation

# Export to JSON
$results | ConvertTo-Json | Set-Content -Path $jsonFile

Write-Host "Export complete: $csvFile and $jsonFile"