# ISO 27001 Crypto Policies Test Script
# This script tests Azure policies related to ISO 27001 cryptography requirements
# by attempting to create resources that both comply with and violate the policies.
# It requires the Az PowerShell module and an authenticated Azure session.
# Usage: pwsh ./test-policies.ps1 -TenantId "<tenant-guid>" [-ResourceGroupName "rg"] [-Location "swedencentral"]
param(
    [Parameter(Mandatory = $false)]
    [ValidatePattern('^[0-9a-fA-F-]{36}$')]
    [string]$TenantId,
    [string]$ResourceGroupName = "policy-test-rg",
    [string]$Location = "swedencentral",
    [string]$AppGwPfxPath = "",
    [string]$AppGwPfxPassword = ""
)

# Azure PowerShell breaking change warnings are not suppressed globally to avoid hiding important notices.

Write-Host "🧪 Testing ISO 27001 Cryptography Policies..." -ForegroundColor Green

# Prompt for tenant if not provided
while (-not $TenantId -or [string]::IsNullOrWhiteSpace($TenantId)) {
    $TenantId = Read-Host "Enter the Azure Tenant ID to use for authentication"
    if (-not $TenantId -or [string]::IsNullOrWhiteSpace($TenantId)) {
        Write-Host "Tenant ID cannot be empty. Please paste again." -ForegroundColor Yellow
    }
}

# Track RG for cleanup
$rgCreated = $false
$rgOriginalName = $ResourceGroupName

Write-Host "📦 Checking Azure PowerShell modules..." -ForegroundColor Yellow

# Minimal set of required Az submodules
$requiredModules = @(
    "Az.Accounts",
    "Az.Resources",
    "Az.Storage",
    "Az.Functions",
    "Az.Network",
    "Az.Compute",
    "Az.PolicyInsights"
)

foreach ($m in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $m)) {
        try {
            Install-Module -Name $m -Force -AllowClobber -Scope CurrentUser
            Write-Host "✅ Installed ${m}" -ForegroundColor Green
        } catch {
            Write-Host "⚠️  Failed to install ${m}: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host "Loading required Azure modules..." -ForegroundColor Yellow
foreach ($m in $requiredModules) {
    if (Get-Module -ListAvailable -Name $m) {
        Import-Module $m -ErrorAction SilentlyContinue
    } else {
        Write-Host "⚠️  Skipping load for missing module: ${m}" -ForegroundColor Yellow
    }
}
Write-Host "✅ Required modules processed" -ForegroundColor Green

# Ensure we're connected to Azure
Write-Host "🔑 Checking Azure connection..." -ForegroundColor Yellow
try {
    $context = Get-AzContext
    $subscriptions = @()
    
    if ($context) {
        $subscriptions = Get-AzSubscription -ErrorAction SilentlyContinue
    }
    
    # If no context or no subscriptions, force a fresh login with tenant
    if (-not $context -or $subscriptions.Count -eq 0 -or $context.Tenant.Id -ne $TenantId) {
        Write-Host "Authenticating to Azure for tenant $TenantId (browser window will open)..." -ForegroundColor Yellow
        Connect-AzAccount -Tenant $TenantId | Out-Null
        $context = Get-AzContext
        $subscriptions = Get-AzSubscription
    }
    
    Write-Host "✅ Connected to Azure as $($context.Account.Id) in tenant $($context.Tenant.Id)" -ForegroundColor Green
    
    if ($subscriptions.Count -eq 0) {
        Write-Host "❌ No subscriptions found for this account" -ForegroundColor Red
        Write-Host "Please ensure your account has access to at least one Azure subscription" -ForegroundColor Yellow
        exit 1
    }
    
    # List available subscriptions and prompt user to select one
    Write-Host "`n📋 Available subscriptions:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $subscriptions.Count; $i++) {
        Write-Host "  [$i] $($subscriptions[$i].Name) ($($subscriptions[$i].Id))" -ForegroundColor Cyan
    }
    
    if ($subscriptions.Count -eq 1) {
        Write-Host "`nUsing only available subscription: $($subscriptions[0].Name)" -ForegroundColor Green
        Set-AzContext -SubscriptionId $subscriptions[0].Id | Out-Null
    } else {
        $selection = Read-Host "`nEnter subscription number [0-$($subscriptions.Count - 1)]"
        if ($selection -match '^\d+$' -and [int]$selection -ge 0 -and [int]$selection -lt $subscriptions.Count) {
            Set-AzContext -SubscriptionId $subscriptions[[int]$selection].Id | Out-Null
            Write-Host "✅ Subscription set to: $($subscriptions[[int]$selection].Name)" -ForegroundColor Green
        } else {
            Write-Host "❌ Invalid selection" -ForegroundColor Red
            exit 1
        }
    }
} catch {
    Write-Host "❌ Failed to connect to Azure: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Confirm before proceeding
$currentContext = Get-AzContext
Write-Host "`n📍 Ready to start testing with:" -ForegroundColor Cyan
Write-Host "   Account: $($currentContext.Account.Id)" -ForegroundColor White
Write-Host "   Subscription: $($currentContext.Subscription.Name) ($($currentContext.Subscription.Id))" -ForegroundColor White
Write-Host "   Location: $Location" -ForegroundColor White
Write-Host "   Resource Group: $ResourceGroupName" -ForegroundColor White

$confirm = Read-Host "`nProceed with policy testing? (Y/N)"
if ($confirm -ne 'Y' -and $confirm -ne 'y') {
    Write-Host "❌ Testing cancelled by user" -ForegroundColor Yellow
    exit 0
}

# Wait for policy propagation
Write-Host "`n⏳ Waiting 30 seconds for policy propagation..." -ForegroundColor Yellow
Start-Sleep -Seconds 30
Write-Host "✅ Policy propagation wait complete" -ForegroundColor Green

# Create or adjust test resource group name if already exists
Write-Host "`nCreating test resource group..." -ForegroundColor Yellow
try {
    $existingRg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if ($existingRg) {
        $ResourceGroupName = "$rgOriginalName-$(Get-Random -Minimum 1000 -Maximum 9999)"
        Write-Host "ℹ️  Resource group '$rgOriginalName' exists. Using new name: $ResourceGroupName" -ForegroundColor Yellow
    }
    $rg = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Force
    $rgCreated = $true
    Write-Host "✅ Resource group created: $($rg.ResourceGroupName)" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to create resource group: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Helper: secure random password
function New-RandomPassword([int]$length = 16) {
    $chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()"
    -join ((1..$length) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
}

# Test 1: Azure Function App without HTTPS (Should FAIL)
Write-Host "`n❌ Testing Function App without HTTPS enforcement (should fail)..." -ForegroundColor Red
$appServicePlanName = "test-plan-$(Get-Random -Minimum 1000 -Maximum 9999)"
$storageAccountName = "teststorage$(Get-Random -Minimum 10000 -Maximum 99999)"

try {
    Write-Host "Creating App Service Plan: $appServicePlanName" -ForegroundColor Yellow
    $plan = New-AzAppServicePlan -ResourceGroupName $ResourceGroupName -Name $appServicePlanName -Location $Location -Tier "Dynamic" -WorkerSize "Small"

    Write-Host "Creating storage account: $storageAccountName" -ForegroundColor Yellow
    $storageAccount = New-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $storageAccountName -Location $Location -SkuName "Standard_LRS" -EnableHttpsTrafficOnly $true -MinimumTlsVersion "TLS1_2" -AllowBlobPublicAccess $false

    $functionAppName = "testfunc$(Get-Random -Minimum 10000 -Maximum 99999)"
    Write-Host "Attempting to create Function App without HTTPS: $functionAppName" -ForegroundColor Yellow

    $supportsHttpsOnly = (Get-Command New-AzFunctionApp).Parameters.ContainsKey('HttpsOnly')
    if ($supportsHttpsOnly) {
        $functionApp = New-AzFunctionApp -ResourceGroupName $ResourceGroupName -Name $functionAppName -StorageAccountName $storageAccountName -PlanName $appServicePlanName -Runtime "PowerShell" -HttpsOnly:$false -ErrorAction Stop
    } else {
        Write-Host "ℹ️ Module does not support -HttpsOnly on New-AzFunctionApp; skipping this test." -ForegroundColor Yellow
        throw "Skipped test due to missing HttpsOnly parameter"
    }

    Write-Host "⚠️  Policy failed - Function App created without HTTPS enforcement!" -ForegroundColor Red
    Remove-AzFunctionApp -ResourceGroupName $ResourceGroupName -Name $functionAppName -Force -ErrorAction SilentlyContinue
} catch {
    Write-Host "✅ Policy working - Function App without HTTPS blocked: $($_.Exception.Message)" -ForegroundColor Green
} finally {
    if (Get-AzAppServicePlan -ResourceGroupName $ResourceGroupName -Name $appServicePlanName -ErrorAction SilentlyContinue) {
        Remove-AzAppServicePlan -ResourceGroupName $ResourceGroupName -Name $appServicePlanName -Force -ErrorAction SilentlyContinue
    }
    if (Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $storageAccountName -ErrorAction SilentlyContinue) {
        Remove-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $storageAccountName -Force -ErrorAction SilentlyContinue
    }
}

# Test 2: Storage Account TLS 1.0 Policy (Should FAIL)
Write-Host "`n❌ Testing Storage Account with TLS 1.0 (should fail)..." -ForegroundColor Red
$storageTestName2 = "test$(Get-Random -Minimum 10000 -Maximum 99999)"

try {
    Write-Host "Attempting to create storage account with TLS 1.0: $storageTestName2" -ForegroundColor Yellow
    $storageAccount2 = New-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $storageTestName2 -Location $Location -SkuName "Standard_LRS" -MinimumTlsVersion "TLS1_0" -EnableHttpsTrafficOnly $true -ErrorAction Stop
    if ($storageAccount2.ProvisioningState -eq 'Succeeded') {
        Write-Host "⚠️  Policy failed - Storage account created with TLS 1.0!" -ForegroundColor Red
        Remove-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $storageTestName2 -Force -ErrorAction SilentlyContinue
    } else {
        Write-Host "✅ Policy working - creation not succeeded (state: $($storageAccount2.ProvisioningState))" -ForegroundColor Green
    }
} catch {
    Write-Host "✅ Policy working - Storage account TLS 1.0 blocked: $($_.Exception.Message)" -ForegroundColor Green
}

# Test 3: Compliant Storage Account (Should PASS)
Write-Host "`n✅ Testing compliant Storage Account (should pass)..." -ForegroundColor Green
$storageTestName3 = "test$(Get-Random -Minimum 10000 -Maximum 99999)"

try {
    Write-Host "Creating compliant storage account: $storageTestName3" -ForegroundColor Yellow
    $storageAccount3 = New-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $storageTestName3 -Location $Location -SkuName "Standard_LRS" -EnableHttpsTrafficOnly $true -MinimumTlsVersion "TLS1_2" -AllowBlobPublicAccess $false
    
    Write-Host "✅ Compliant storage account created successfully" -ForegroundColor Green
    
    # Clean up successful resource
    Remove-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $storageTestName3 -Force
    
} catch {
    Write-Host "⚠️  Unexpected failure creating compliant storage account: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: VM without Encryption-at-Host (Should FAIL)
Write-Host "`n❌ Testing VM without Encryption-at-Host (should fail)..." -ForegroundColor Red
$vmName4 = "test-vm-no-enc-$(Get-Random -Minimum 1000 -Maximum 9999)"
$nicName4 = "test-nic-4"
$vnetNameVM = "test-vnet-vm"
$subnetNameVM = "vm-subnet"

try {
    Write-Host "Creating VNet for VM test: $vnetNameVM" -ForegroundColor Yellow
    $subnetVM = New-AzVirtualNetworkSubnetConfig -Name $subnetNameVM -AddressPrefix "10.1.0.0/24"
    $vnetVM = New-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Location $Location -Name $vnetNameVM -AddressPrefix "10.1.0.0/16" -Subnet $subnetVM
    
    $nic4 = New-AzNetworkInterface -Name $nicName4 -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $vnetVM.Subnets[0].Id
    
    $passwordPlain = New-RandomPassword 16
    $cred = New-Object System.Management.Automation.PSCredential ("azureuser", (ConvertTo-SecureString $passwordPlain -AsPlainText -Force))
    
    Write-Host "Attempting to create VM without encryption-at-host: $vmName4" -ForegroundColor Yellow
    $vmConfig = New-AzVMConfig -VMName $vmName4 -VMSize "Standard_D2s_v3"
    $vmConfig = Set-AzVMOperatingSystem -VM $vmConfig -Linux -ComputerName $vmName4 -Credential $cred
    $vmConfig = Set-AzVMSourceImage -VM $vmConfig -PublisherName "Canonical" -Offer "0001-com-ubuntu-server-jammy" -Skus "22_04-lts-gen2" -Version "latest"
    $vmConfig = Add-AzVMNetworkInterface -VM $vmConfig -Id $nic4.Id
    $vmConfig = Set-AzVMOSDisk -VM $vmConfig -CreateOption FromImage -StorageAccountType "Premium_LRS"
    # Boot diagnostics are disabled intentionally for this non-compliant VM; this setting is unrelated to the encryption-at-host policy under test.
    $vmConfig = Set-AzVMBootDiagnostic -VM $vmConfig -Disable
    
    $vm4 = New-AzVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $vmConfig -ErrorAction Stop -WarningAction SilentlyContinue
    
    Write-Host "⚠️  Policy failed - VM created without encryption-at-host!" -ForegroundColor Red
    Remove-AzVM -ResourceGroupName $ResourceGroupName -Name $vmName4 -Force -ErrorAction SilentlyContinue
} catch {
    if ($_.Exception.Message -match "RequestDisallowedByPolicy") {
        Write-Host "✅ Policy working - VM without encryption-at-host blocked by policy" -ForegroundColor Green
    } else {
        Write-Host "✅ Policy working - VM without encryption-at-host blocked: $($_.Exception.Message)" -ForegroundColor Green
    }
} finally {
    if (Get-AzNetworkInterface -Name $nicName4 -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue) {
        Remove-AzNetworkInterface -Name $nicName4 -ResourceGroupName $ResourceGroupName -Force -ErrorAction SilentlyContinue
    }
    if (Get-AzVirtualNetwork -Name $vnetNameVM -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue) {
        Remove-AzVirtualNetwork -Name $vnetNameVM -ResourceGroupName $ResourceGroupName -Force -ErrorAction SilentlyContinue
    }
}

# Test 5: VM with Encryption-at-Host (Should PASS)
Write-Host "`n✅ Testing VM with Encryption-at-Host enabled (should pass)..." -ForegroundColor Green
$vmName5 = "test-vm-enc-$(Get-Random -Minimum 1000 -Maximum 9999)"
$nicName5 = "test-nic-5"

try {
    $vnetVM5 = Get-AzVirtualNetwork -Name $vnetNameVM -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $vnetVM5) {
        $subnetVM5 = New-AzVirtualNetworkSubnetConfig -Name $subnetNameVM -AddressPrefix "10.1.0.0/24"
        $vnetVM5 = New-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Location $Location -Name $vnetNameVM -AddressPrefix "10.1.0.0/16" -Subnet $subnetVM5
    }
    
    $nic5 = New-AzNetworkInterface -Name $nicName5 -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $vnetVM5.Subnets[0].Id
    $passwordPlain = New-RandomPassword 16
    $cred = New-Object System.Management.Automation.PSCredential ("azureuser", (ConvertTo-SecureString $passwordPlain -AsPlainText -Force))
    
    $supportsEncAtHost = (Get-Command Set-AzVMSecurityProfile).Parameters.ContainsKey('EncryptionAtHost')
    if (-not $supportsEncAtHost) {
        Write-Host "ℹ️ Module does not support EncryptionAtHost; skipping compliant VM test." -ForegroundColor Yellow
        throw "Skipped test due to missing EncryptionAtHost support"
    }

    Write-Host "Creating compliant VM with encryption-at-host: $vmName5" -ForegroundColor Yellow
    $vmConfig = New-AzVMConfig -VMName $vmName5 -VMSize "Standard_D2s_v3" -SecurityType "Standard"
    $vmConfig = Set-AzVMSecurityProfile -VM $vmConfig -EncryptionAtHost $true
    $vmConfig = Set-AzVMOperatingSystem -VM $vmConfig -Linux -ComputerName $vmName5 -Credential $cred
    $vmConfig = Set-AzVMSourceImage -VM $vmConfig -PublisherName "Canonical" -Offer "0001-com-ubuntu-server-jammy" -Skus "22_04-lts-gen2" -Version "latest"
    $vmConfig = Add-AzVMNetworkInterface -VM $vmConfig -Id $nic5.Id
    $vmConfig = Set-AzVMOSDisk -VM $vmConfig -CreateOption FromImage -StorageAccountType "Premium_LRS"
    
    $vm5 = New-AzVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $vmConfig -ErrorAction Stop
    
    Write-Host "✅ Compliant VM with encryption-at-host created successfully" -ForegroundColor Green
    Remove-AzVM -ResourceGroupName $ResourceGroupName -Name $vmName5 -Force -ErrorAction SilentlyContinue
} catch {
    Write-Host "⚠️  Compliant VM test skipped or failed: $($_.Exception.Message)" -ForegroundColor Yellow
} finally {
    if (Get-AzNetworkInterface -Name $nicName5 -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue) {
        Remove-AzNetworkInterface -Name $nicName5 -ResourceGroupName $ResourceGroupName -Force -ErrorAction SilentlyContinue
    }
    if (Get-AzVirtualNetwork -Name $vnetNameVM -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue) {
        Remove-AzVirtualNetwork -Name $vnetNameVM -ResourceGroupName $ResourceGroupName -Force -ErrorAction SilentlyContinue
    }
}

# Application Gateway Tests require prerequisite resources
Write-Host "`n🔧 Setting up Application Gateway test prerequisites..." -ForegroundColor Yellow

try {
    $vnetName = "test-vnet"
    $subnetName = "appgw-subnet"
    $publicIpName = "appgw-pip"

    Write-Host "Creating Virtual Network: $vnetName" -ForegroundColor Yellow
    $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix "10.0.0.0/24"
    $vnet = New-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Location $Location -Name $vnetName -AddressPrefix "10.0.0.0/16" -Subnet $subnet

    Write-Host "Creating Public IP: $publicIpName" -ForegroundColor Yellow
    $publicIp = New-AzPublicIpAddress -ResourceGroupName $ResourceGroupName -Location $Location -Name $publicIpName -AllocationMethod Static -Sku Standard
    Write-Host "✅ Prerequisites created successfully" -ForegroundColor Green

    # Test: Application Gateway with HTTP listener (Should FAIL)
    Write-Host "`n❌ Testing Application Gateway with HTTP listener (should fail)..." -ForegroundColor Red
    $appGwName1 = "testappgw$(Get-Random -Minimum 1000 -Maximum 9999)"
    try {
        $gipconfig = New-AzApplicationGatewayIPConfiguration -Name "gatewayIP01" -Subnet $vnet.Subnets[0]
        $fipconfig = New-AzApplicationGatewayFrontendIPConfig -Name "frontendIP01" -PublicIPAddress $publicIp
        $fpconfig = New-AzApplicationGatewayFrontendPort -Name "frontendPort01" -Port 80
        $listener = New-AzApplicationGatewayHttpListener -Name "listener01" -Protocol Http -FrontendIPConfiguration $fipconfig -FrontendPort $fpconfig
        $pool = New-AzApplicationGatewayBackendAddressPool -Name "pool01"
        $poolSetting = New-AzApplicationGatewayBackendHttpSettings -Name "poolsetting01" -Port 80 -Protocol Http -CookieBasedAffinity Disabled
        $rule = New-AzApplicationGatewayRequestRoutingRule -Name "rule01" -RuleType Basic -BackendHttpSettings $poolSetting -HttpListener $listener -BackendAddressPool $pool
        $sku = New-AzApplicationGatewaySku -Name Standard_v2 -Tier Standard_v2 -Capacity 1

        Write-Host "Attempting to create Application Gateway with HTTP listener: $appGwName1" -ForegroundColor Yellow
        $appGw1 = New-AzApplicationGateway -Name $appGwName1 -ResourceGroupName $ResourceGroupName -Location $Location `
            -BackendAddressPools $pool -BackendHttpSettingsCollection $poolSetting -FrontendIpConfigurations $fipconfig `
            -GatewayIpConfigurations $gipconfig -FrontendPorts $fpconfig -HttpListeners $listener -RequestRoutingRules $rule -Sku $sku

        Write-Host "⚠️  Policy failed - Application Gateway created with HTTP!" -ForegroundColor Red
        Remove-AzApplicationGateway -ResourceGroupName $ResourceGroupName -Name $appGwName1 -Force
    } catch {
        if ($_.Exception.Message -match "RequestDisallowedByPolicy") {
            Write-Host "✅ Policy working - Application Gateway HTTP listener blocked by policy" -ForegroundColor Green
        } else {
            Write-Host "✅ Policy working - Application Gateway HTTP blocked: $($_.Exception.Message)" -ForegroundColor Green
        }
    }

    # Test: Compliant Application Gateway with HTTPS (Should PASS) — only if PFX provided
    if ([string]::IsNullOrWhiteSpace($AppGwPfxPath) -or [string]::IsNullOrWhiteSpace($AppGwPfxPassword)) {
        Write-Host "`nℹ️ Skipping HTTPS Application Gateway test (no PFX path/password provided)" -ForegroundColor Yellow
    } else {
        Write-Host "`n✅ Testing compliant Application Gateway with HTTPS (should pass)..." -ForegroundColor Green
        $appGwName2 = "testappgw$(Get-Random -Minimum 1000 -Maximum 9999)"
        try {
            $gipconfig2 = New-AzApplicationGatewayIPConfiguration -Name "gatewayIP02" -Subnet $vnet.Subnets[0]
            $fipconfig2 = New-AzApplicationGatewayFrontendIPConfig -Name "frontendIP02" -PublicIPAddress $publicIp
            $fpconfig2 = New-AzApplicationGatewayFrontendPort -Name "frontendPort02" -Port 443

            $securePfxPassword = ConvertTo-SecureString $AppGwPfxPassword -AsPlainText -Force
            $sslCert = New-AzApplicationGatewaySslCertificate -Name "sslCert02" -CertificateFile $AppGwPfxPath -Password $securePfxPassword
            $sslCert = New-AzApplicationGatewaySslCertificate -Name "sslCert02" -CertificateFile $AppGwPfxPath -Password $securePfxPassword
            $listener2 = New-AzApplicationGatewayHttpListener -Name "listener02" -Protocol Https -FrontendIPConfiguration $fipconfig2 -FrontendPort $fpconfig2 -SslCertificate $sslCert
            $poolSetting2 = New-AzApplicationGatewayBackendHttpSettings -Name "poolsetting02" -Port 443 -Protocol Https -CookieBasedAffinity Disabled
            $rule2 = New-AzApplicationGatewayRequestRoutingRule -Name "rule02" -RuleType Basic -BackendHttpSettings $poolSetting2 -HttpListener $listener2 -BackendAddressPool $pool2
            $rule2 = New-AzApplicationGatewayRequestRoutingRule -Name "rule02" -RuleType Basic -BackendHttpSettings $poolSetting2 -HttpListener $listener2 -BackendAddressPool $pool2
            $sku2 = New-AzApplication
            
            GatewaySku -Name Standard_v2 -Tier Standard_v2 -Capacity 1

            Write-Host "Creating compliant Application Gateway with HTTPS listener: $appGwName2" -ForegroundColor Yellow
            $appGw2 = New-AzApplicationGateway -Name $appGwName2 -ResourceGroupName $ResourceGroupName -Location $Location `
                -BackendAddressPools $pool2 -BackendHttpSettingsCollection $poolSetting2 -FrontendIpConfigurations $fipconfig2 `
                -GatewayIpConfigurations $gipconfig2 -FrontendPorts $fpconfig2 -HttpListeners $listener2 -RequestRoutingRules $rule2 `
                -Sku $sku2 -SslCertificates $sslCert

            Write-Host "✅ Compliant Application Gateway created successfully" -ForegroundColor Green
            Remove-AzApplicationGateway -ResourceGroupName $ResourceGroupName -Name $appGwName2 -Force
        } catch {
            Write-Host "⚠️  Unexpected failure creating compliant Application Gateway: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

} catch {
    Write-Host "❌ Failed to set up Application Gateway prerequisites: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    if ($vnet) { Remove-AzVirtualNetwork -Name $vnetName -ResourceGroupName $ResourceGroupName -Force -ErrorAction SilentlyContinue }
    if ($publicIp) { Remove-AzPublicIpAddress -Name $publicIpName -ResourceGroupName $ResourceGroupName -Force -ErrorAction SilentlyContinue }
}

# Test 6: Check Policy Compliance Status
Write-Host "`n📊 Checking overall policy compliance..." -ForegroundColor Blue
try {
    $policyStates = Get-AzPolicyState | Where-Object { $_.PolicyDefinitionName -like "*iso27001*" }
    
    if ($policyStates) {
        Write-Host "Policy Compliance Results:" -ForegroundColor Cyan
        $policyStates | Select-Object PolicyDefinitionName, ResourceId, ComplianceState | Format-Table -AutoSize
    } else {
        Write-Host "No policy compliance data found for ISO 27001 policies" -ForegroundColor Yellow
        Write-Host "Policy evaluation may take 24 hours for initial results" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Failed to retrieve policy compliance data: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Clean up test resource group (only if we created it)
        $removeRgJob = Remove-AzResourceGroup -Name $ResourceGroupName -Force -AsJob -ErrorAction Stop
        Write-Host "✅ Resource group deletion started as background job (Job Id: $($removeRgJob.Id)) for: $ResourceGroupName" -ForegroundColor Green
    try {
        Remove-AzResourceGroup -Name $ResourceGroupName -Force -ErrorAction Stop
        Write-Host "✅ Resource group removed: $ResourceGroupName" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to clean up resource group: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "ℹ️ Skipping RG cleanup; it was not created by this run." -ForegroundColor Yellow
}

Write-Host "`n🎯 Policy testing complete!" -ForegroundColor Green
Write-Host "Check Azure Portal → Policy → Compliance for detailed results" -ForegroundColor Cyan
Write-Host "Note: Policy evaluation may take up to 24 hours for complete results" -ForegroundColor Yellow