# ISO 27001 Crypto Policies Test Script
param(
    [string]$ResourceGroupName = "policy-test-rg",
    [string]$Location = "swedencentral"
)

Write-Host "🧪 Testing ISO 27001 Cryptography Policies..." -ForegroundColor Green

# Import required modules
Write-Host "📦 Checking Azure PowerShell modules..." -ForegroundColor Yellow

# Check if Az module is installed
if (-not (Get-Module -ListAvailable -Name "Az")) {
    Write-Host "Installing Az module (this may take a few minutes)..." -ForegroundColor Yellow
    try {
        # Install to local user scope to avoid OneDrive issues
        Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force -AllowClobber
        Write-Host "✅ Az module installed successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Failed to install Az module: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Please run: Install-Module -Name Az -Scope CurrentUser -Force" -ForegroundColor Yellow
        exit 1
    }
}

# Import the main Az module (this imports all sub-modules)
Write-Host "Loading Azure PowerShell modules..." -ForegroundColor Yellow
try {
    Import-Module Az -Force -Scope Local
    Write-Host "✅ Azure PowerShell modules loaded" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to import Az module: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Try running: Update-Module Az -Force" -ForegroundColor Yellow
    exit 1
}

# Ensure we're connected to Azure
Write-Host "🔑 Checking Azure connection..." -ForegroundColor Yellow
try {
    $context = Get-AzContext
    if (-not $context) {
        Connect-AzAccount
    }
    Write-Host "✅ Connected to Azure as $($context.Account.Id)" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to connect to Azure. Please run Connect-AzAccount" -ForegroundColor Red
    exit 1
}

# Create test resource group
Write-Host "Creating test resource group..." -ForegroundColor Yellow
try {
    $rg = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Force
    Write-Host "✅ Resource group created: $($rg.ResourceGroupName)" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to create resource group: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 1: Azure Function App without HTTPS (Should FAIL)
Write-Host "`n❌ Testing Function App without HTTPS enforcement (should fail)..." -ForegroundColor Red

# Initialize variables outside try block for proper scope
$appServicePlanName = "test-plan-$(Get-Random -Minimum 1000 -Maximum 9999)"
$storageAccountName = "teststorage$(Get-Random -Minimum 10000 -Maximum 99999)"

try {
    # Create App Service Plan for Function App (Consumption plan)
    Write-Host "Creating App Service Plan: $appServicePlanName" -ForegroundColor Yellow
    
    $plan = New-AzAppServicePlan -ResourceGroupName $ResourceGroupName -Name $appServicePlanName -Location $Location -Tier "Dynamic" -WorkerSize "Small"
    Write-Host "✅ App Service Plan created" -ForegroundColor Green

    # Create storage account for Function App (required)
    Write-Host "Creating storage account: $storageAccountName" -ForegroundColor Yellow
    
    $storageAccount = New-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $storageAccountName -Location $Location -SkuName "Standard_LRS" -EnableHttpsTrafficOnly $true -MinimumTlsVersion "TLS1_2" -AllowBlobPublicAccess $false
    
    # Try to create Function App without HTTPS enforcement
    $functionAppName = "testfunc$(Get-Random -Minimum 10000 -Maximum 99999)"
    Write-Host "Attempting to create Function App without HTTPS: $functionAppName" -ForegroundColor Yellow
    
    $functionApp = New-AzFunctionApp -ResourceGroupName $ResourceGroupName -Name $functionAppName -StorageAccountName $storageAccountName -PlanName $appServicePlanName -Runtime "PowerShell" -HttpsOnly $false
    
    Write-Host "⚠️  Policy failed - Function App created without HTTPS enforcement!" -ForegroundColor Red
    
    # Clean up if created
    Remove-AzFunctionApp -ResourceGroupName $ResourceGroupName -Name $functionAppName -Force
    
} catch {
    Write-Host "✅ Policy working - Function App without HTTPS blocked: $($_.Exception.Message)" -ForegroundColor Green
} finally {
    # Clean up resources
    if (Get-AzAppServicePlan -ResourceGroupName $ResourceGroupName -Name $appServicePlanName -ErrorAction SilentlyContinue) {
        Remove-AzAppServicePlan -ResourceGroupName $ResourceGroupName -Name $appServicePlanName -Force
    }
    if (Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $storageAccountName -ErrorAction SilentlyContinue) {
        Remove-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $storageAccountName -Force
    }
}

# Test 2: Storage Account TLS 1.0 Policy (Should FAIL)
Write-Host "`n❌ Testing Storage Account with TLS 1.0 (should fail)..." -ForegroundColor Red
$storageTestName2 = "test$(Get-Random -Minimum 10000 -Maximum 99999)"

try {
    Write-Host "Attempting to create storage account with TLS 1.0: $storageTestName2" -ForegroundColor Yellow
    $storageAccount2 = New-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $storageTestName2 -Location $Location -SkuName "Standard_LRS" -MinimumTlsVersion "TLS1_0" -EnableHttpsTrafficOnly $true
    
    Write-Host "⚠️  Policy failed - Storage account created with TLS 1.0!" -ForegroundColor Red
    Remove-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $storageTestName2 -Force
    
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

# Application Gateway Tests require prerequisite resources
Write-Host "`n🔧 Setting up Application Gateway test prerequisites..." -ForegroundColor Yellow

try {
    # Create VNet and Subnet for Application Gateway
    $vnetName = "test-vnet"
    $subnetName = "appgw-subnet"
    
    Write-Host "Creating Virtual Network: $vnetName" -ForegroundColor Yellow
    $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix "10.0.0.0/24"
    $vnet = New-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Location $Location -Name $vnetName -AddressPrefix "10.0.0.0/16" -Subnet $subnet
    
    # Create Public IP for Application Gateway
    $publicIpName = "appgw-pip"
    Write-Host "Creating Public IP: $publicIpName" -ForegroundColor Yellow
    $publicIp = New-AzPublicIpAddress -ResourceGroupName $ResourceGroupName -Location $Location -Name $publicIpName -AllocationMethod Static -Sku Standard
    
    Write-Host "✅ Prerequisites created successfully" -ForegroundColor Green

    # Test 4: Application Gateway with HTTP listener (Should FAIL - policy requires HTTPS)
    Write-Host "`n❌ Testing Application Gateway with HTTP listener (should fail)..." -ForegroundColor Red
    $appGwName1 = "testappgw$(Get-Random -Minimum 1000 -Maximum 9999)"
    
    try {
        # Create IP configurations
        $gipconfig = New-AzApplicationGatewayIPConfiguration -Name "gatewayIP01" -Subnet $vnet.Subnets[0]
        $fipconfig = New-AzApplicationGatewayFrontendIPConfig -Name "frontendIP01" -PublicIPAddress $publicIp
        $fpconfig = New-AzApplicationGatewayFrontendPort -Name "frontendPort01" -Port 80
        
        # Create HTTP listener (should be blocked by policy)
        $listener = New-AzApplicationGatewayHttpListener -Name "listener01" -Protocol Http -FrontendIPConfiguration $fipconfig -FrontendPort $fpconfig
        $pool = New-AzApplicationGatewayBackendAddressPool -Name "pool01"
        $poolSetting = New-AzApplicationGatewayBackendHttpSettings -Name "poolsetting01" -Port 80 -Protocol Http -CookieBasedAffinity Disabled
        $rule = New-AzApplicationGatewayRequestRoutingRule -Name "rule01" -RuleType Basic -BackendHttpSettings $poolSetting -HttpListener $listener -BackendAddressPool $pool
        $sku = New-AzApplicationGatewaySku -Name Standard_v2 -Tier Standard_v2 -Capacity 1
        
        Write-Host "Attempting to create Application Gateway with HTTP listener: $appGwName1" -ForegroundColor Yellow
        $appGw1 = New-AzApplicationGateway -Name $appGwName1 -ResourceGroupName $ResourceGroupName -Location $Location -BackendAddressPools $pool -BackendHttpSettingsCollection $poolSetting -FrontendIpConfigurations $fipconfig -GatewayIpConfigurations $gipconfig -FrontendPorts $fpconfig -HttpListeners $listener -RequestRoutingRules $rule -Sku $sku
        
        Write-Host "⚠️  Policy failed - Application Gateway created with HTTP!" -ForegroundColor Red
        Remove-AzApplicationGateway -ResourceGroupName $ResourceGroupName -Name $appGwName1 -Force
        
    } catch {
        Write-Host "✅ Policy working - Application Gateway HTTP blocked: $($_.Exception.Message)" -ForegroundColor Green
    }

    # Test 5: Compliant Application Gateway with HTTPS (Should PASS)  
    Write-Host "`n✅ Testing compliant Application Gateway with HTTPS (should pass)..." -ForegroundColor Green
    $appGwName2 = "testappgw$(Get-Random -Minimum 1000 -Maximum 9999)"
    
    try {
        # Create configurations for HTTPS
        $gipconfig2 = New-AzApplicationGatewayIPConfiguration -Name "gatewayIP02" -Subnet $vnet.Subnets[0]
        $fipconfig2 = New-AzApplicationGatewayFrontendIPConfig -Name "frontendIP02" -PublicIPAddress $publicIp
        # Create SSL certificate for HTTPS listener
        # NOTE: Replace the below with a valid PFX file path and password for real deployments
        $pfxFilePath = "testcert.pfx"
        $pfxPassword = "TestPassword123!"
        $sslCert = New-AzApplicationGatewaySslCertificate -Name "sslCert02" -CertificateFile $pfxFilePath -Password $pfxPassword
        
        # Create HTTPS listener (should be compliant)
        $listener2 = New-AzApplicationGatewayHttpListener -Name "listener02" -Protocol Https -FrontendIPConfiguration $fipconfig2 -FrontendPort $fpconfig2 -SslCertificate $sslCert
        $pool2 = New-AzApplicationGatewayBackendAddressPool -Name "pool02"  
        $poolSetting2 = New-AzApplicationGatewayBackendHttpSettings -Name "poolsetting02" -Port 443 -Protocol Https -CookieBasedAffinity Disabled
        $rule2 = New-AzApplicationGatewayRequestRoutingRule -Name "rule02" -RuleType Basic -BackendHttpSettings $poolSetting2 -HttpListener $listener2 -BackendAddressPool $pool2
        $sku2 = New-AzApplicationGatewaySku -Name Standard_v2 -Tier Standard_v2 -Capacity 1
        
        Write-Host "Creating compliant Application Gateway with HTTPS listener: $appGwName2" -ForegroundColor Yellow
        $appGw2 = New-AzApplicationGateway -Name $appGwName2 -ResourceGroupName $ResourceGroupName -Location $Location -BackendAddressPools $pool2 -BackendHttpSettingsCollection $poolSetting2 -FrontendIpConfigurations $fipconfig2 -GatewayIpConfigurations $gipconfig2 -FrontendPorts $fpconfig2 -HttpListeners $listener2 -RequestRoutingRules $rule2 -Sku $sku2 -SslCertificates $sslCert
        $poolSetting2 = New-AzApplicationGatewayBackendHttpSettings -Name "poolsetting02" -Port 443 -Protocol Https -CookieBasedAffinity Disabled
        $rule2 = New-AzApplicationGatewayRequestRoutingRule -Name "rule02" -RuleType Basic -BackendHttpSettings $poolSetting2 -HttpListener $listener2 -BackendAddressPool $pool2
        $sku2 = New-AzApplicationGatewaySku -Name Standard_v2 -Tier Standard_v2 -Capacity 1
        
        Write-Host "Creating compliant Application Gateway with HTTPS listener: $appGwName2" -ForegroundColor Yellow
        $appGw2 = New-AzApplicationGateway -Name $appGwName2 -ResourceGroupName $ResourceGroupName -Location $Location -BackendAddressPools $pool2 -BackendHttpSettingsCollection $poolSetting2 -FrontendIpConfigurations $fipconfig2 -GatewayIpConfigurations $gipconfig2 -FrontendPorts $fpconfig2 -HttpListeners $listener2 -RequestRoutingRules $rule2 -Sku $sku2 -SslCertificates $sslCert
        $poolSetting2 = New-AzApplicationGatewayBackendHttpSettings -Name "poolsetting02" -Port 443 -Protocol Https -CookieBasedAffinity Disabled
        $rule2 = New-AzApplicationGatewayRequestRoutingRule -Name "rule02" -RuleType Basic -BackendHttpSettings $poolSetting2 -HttpListener $listener2 -BackendAddressPool $pool2
        $sku2 = New-AzApplicationGatewaySku -Name Standard_v2 -Tier Standard_v2 -Capacity 1
        
        Write-Host "Creating compliant Application Gateway with HTTPS listener: $appGwName2" -ForegroundColor Yellow
        $appGw2 = New-AzApplicationGateway -Name $appGwName2 -ResourceGroupName $ResourceGroupName -Location $Location -BackendAddressPools $pool2 -BackendHttpSettingsCollection $poolSetting2 -FrontendIpConfigurations $fipconfig2 -GatewayIpConfigurations $gipconfig2 -FrontendPorts $fpconfig2 -HttpListeners $listener2 -RequestRoutingRules $rule2 -Sku $sku2 -SslCertificates $sslCert
        $poolSetting2 = New-AzApplicationGatewayBackendHttpSettings -Name "poolsetting02" -Port 443 -Protocol Https -CookieBasedAffinity Disabled
        $rule2 = New-AzApplicationGatewayRequestRoutingRule -Name "rule02" -RuleType Basic -BackendHttpSettings $poolSetting2 -HttpListener $listener2 -BackendAddressPool $pool2
        $sku2 = New-AzApplicationGatewaySku -Name Standard_v2 -Tier Standard_v2 -Capacity 1
        
        Write-Host "Creating compliant Application Gateway with HTTPS listener: $appGwName2" -ForegroundColor Yellow
        $appGw2 = New-AzApplicationGateway -Name $appGwName2 -ResourceGroupName $ResourceGroupName -Location $Location -BackendAddressPools $pool2 -BackendHttpSettingsCollection $poolSetting2 -FrontendIpConfigurations $fipconfig2 -GatewayIpConfigurations $gipconfig2 -FrontendPorts $fpconfig2 -HttpListeners $listener2 -RequestRoutingRules $rule2 -Sku $sku2 -SslCertificates $sslCert
        $poolSetting2 = New-AzApplicationGatewayBackendHttpSettings -Name "poolsetting02" -Port 443 -Protocol Https -CookieBasedAffinity Disabled
        $rule2 = New-AzApplicationGatewayRequestRoutingRule -Name "rule02" -RuleType Basic -BackendHttpSettings $poolSetting2 -HttpListener $listener2 -BackendAddressPool $pool2
        $sku2 = New-AzApplicationGatewaySku -Name Standard_v2 -Tier Standard_v2 -Capacity 1
        
        Write-Host "Creating compliant Application Gateway with HTTPS listener: $appGwName2" -ForegroundColor Yellow
        $appGw2 = New-AzApplicationGateway -Name $appGwName2 -ResourceGroupName $ResourceGroupName -Location $Location -BackendAddressPools $pool2 -BackendHttpSettingsCollection $poolSetting2 -FrontendIpConfigurations $fipconfig2 -GatewayIpConfigurations $gipconfig2 -FrontendPorts $fpconfig2 -HttpListeners $listener2 -RequestRoutingRules $rule2 -Sku $sku2 -SslCertificates $sslCert
        # Create HTTPS listener (should be compliant)
        $listener2 = New-AzApplicationGatewayHttpListener -Name "listener02" -Protocol Https -FrontendIPConfiguration $fipconfig2 -FrontendPort $fpconfig2 -SslCertificate $sslCert
        # Create HTTPS listener (should be compliant)
    Write-Host "❌ Failed to set up Application Gateway prerequisites: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    # Clean up Application Gateway prerequisites if they were created
    if ($vnet) {
        Remove-AzVirtualNetwork -Name $vnetName -ResourceGroupName $ResourceGroupName -Force -ErrorAction SilentlyContinue
    }
    if ($publicIp) {
        Remove-AzPublicIpAddress -Name $publicIpName -ResourceGroupName $ResourceGroupName -Force -ErrorAction SilentlyContinue
    }
} finally {
    # Clean up Application Gateway prerequisites if they were created
    if ($vnet) {
        Remove-AzVirtualNetwork -Name $vnetName -ResourceGroupName $ResourceGroupName -Force -ErrorAction SilentlyContinue
    }
    if ($publicIp) {
        Remove-AzPublicIpAddress -Name $publicIpName -ResourceGroupName $ResourceGroupName -Force -ErrorAction SilentlyContinue
    }
        $pool2 = New-AzApplicationGatewayBackendAddressPool -Name "pool02"  
        $poolSetting2 = New-AzApplicationGatewayBackendHttpSettings -Name "poolsetting02" -Port 443 -Protocol Https -CookieBasedAffinity Disabled
        $rule2 = New-AzApplicationGatewayRequestRoutingRule -Name "rule02" -RuleType Basic -BackendHttpSettings $poolSetting2 -HttpListener $listener2 -BackendAddressPool $pool2
        $sku2 = New-AzApplicationGatewaySku -Name Standard_v2 -Tier Standard_v2 -Capacity 1
        
        Write-Host "Creating compliant Application Gateway with HTTPS listener: $appGwName2" -ForegroundColor Yellow
        $appGw2 = New-AzApplicationGateway -Name $appGwName2 -ResourceGroupName $ResourceGroupName -Location $Location -BackendAddressPools $pool2 -BackendHttpSettingsCollection $poolSetting2 -FrontendIpConfigurations $fipconfig2 -GatewayIpConfigurations $gipconfig2 -FrontendPorts $fpconfig2 -HttpListeners $listener2 -RequestRoutingRules $rule2 -Sku $sku2
        
        Write-Host "✅ Compliant Application Gateway created successfully" -ForegroundColor Green
        Remove-AzApplicationGateway -ResourceGroupName $ResourceGroupName -Name $appGwName2 -Force
        
    } catch {
        Write-Host "⚠️  Unexpected failure creating compliant Application Gateway: $($_.Exception.Message)" -ForegroundColor Red
    }

} catch {
    Write-Host "❌ Failed to set up Application Gateway prerequisites: $($_.Exception.Message)" -ForegroundColor Red
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

# Clean up test resource group
Write-Host "`n🧹 Cleaning up test resources..." -ForegroundColor Yellow
try {
    Remove-AzResourceGroup -Name $ResourceGroupName -Force -AsJob
    Write-Host "✅ Resource group cleanup initiated (running in background)" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to clean up resource group: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🎯 Policy testing complete!" -ForegroundColor Green
Write-Host "Check Azure Portal → Policy → Compliance for detailed results" -ForegroundColor Cyan
Write-Host "Note: Policy evaluation may take up to 24 hours for complete results" -ForegroundColor Yellow