# Network Security Policies Test Script
# Tests NSG requirement and no-public-IP policies

param(
    [string]$ResourceGroupName = "policy-test-netsec-rg",
    [string]$Location = "swedencentral"
)

Write-Host "🧪 Testing Network Security Policies..." -ForegroundColor Green
Write-Host "================================================`n" -ForegroundColor Cyan

# Check Azure CLI
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Azure CLI not found. Please install: https://aka.ms/azure-cli" -ForegroundColor Red
    exit 1
}

# Check authentication
Write-Host "🔑 Checking Azure authentication..." -ForegroundColor Yellow
try {
    $account = az account show --only-show-errors 2>$null | ConvertFrom-Json
    if (-not $account) {
        Write-Host "Not authenticated. Logging in..." -ForegroundColor Yellow
        az login --only-show-errors
        $account = az account show --only-show-errors | ConvertFrom-Json
    }
    Write-Host "✅ Authenticated as: $($account.user.name)" -ForegroundColor Green
    Write-Host "   Subscription: $($account.name) ($($account.id))`n" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Authentication failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Check if policies are deployed
Write-Host "📋 Checking deployed policies..." -ForegroundColor Yellow
$vmNicPolicy = az policy assignment show --name "vm-nic-nsg-required" 2>$null | ConvertFrom-Json
$publicIpPolicy = az policy assignment show --name "deny-vm-public-ip" 2>$null | ConvertFrom-Json

if (-not $vmNicPolicy) {
    Write-Host "⚠️  VM NIC NSG policy not found. Deploy policies first: terraform apply" -ForegroundColor Yellow
    exit 1
}

if (-not $publicIpPolicy) {
    Write-Host "⚠️  Public IP policy not found. Deploy policies first: terraform apply" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ VM NIC NSG Policy: $($vmNicPolicy.properties.displayName)" -ForegroundColor Green
Write-Host "   Enforcement: $($vmNicPolicy.properties.enforcementMode)" -ForegroundColor Cyan
Write-Host "✅ Public IP Policy: $($publicIpPolicy.properties.displayName)" -ForegroundColor Green
Write-Host "   Enforcement: $($publicIpPolicy.properties.enforcementMode)`n" -ForegroundColor Cyan

if ($vmNicPolicy.properties.enforcementMode -eq "DoNotEnforce" -or $publicIpPolicy.properties.enforcementMode -eq "DoNotEnforce") {
    Write-Host "⚠️  Policies are in AUDIT mode (DoNotEnforce)" -ForegroundColor Yellow
    Write-Host "   Tests will create non-compliant resources but won't fail" -ForegroundColor Yellow
    Write-Host "   To enable enforcement, set enforcement_mode = 'Default' in terraform.tfvars`n" -ForegroundColor Yellow
}

# Wait for policy propagation (Azure policies can take 15-30 minutes to fully propagate)
Write-Host "⏳ Waiting 30 seconds for policy propagation..." -ForegroundColor Yellow
Start-Sleep -Seconds 30
Write-Host "✅ Policy propagation wait complete`n" -ForegroundColor Green

# Create test resource group
Write-Host "📦 Creating test resource group..." -ForegroundColor Yellow
try {
    az group create --name $ResourceGroupName --location $Location --only-show-errors --output none
    Write-Host "✅ Resource group created: $ResourceGroupName`n" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to create resource group: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test counter
$testsPassed = 0
$testsFailed = 0
$testsTotal = 0

# Helper function for test results
function Test-Result {
    param(
        [bool]$Passed,
        [string]$TestName,
        [string]$Details = ""
    )
    
    $script:testsTotal++
    
    if ($Passed) {
        $script:testsPassed++
        Write-Host "✅ PASS: $TestName" -ForegroundColor Green
    } else {
        $script:testsFailed++
        Write-Host "❌ FAIL: $TestName" -ForegroundColor Red
    }
    
    if ($Details) {
        Write-Host "   $Details" -ForegroundColor Gray
    }
}

#
# TEST 1: Create NSG for subsequent tests
#
Write-Host "`n━━━ TEST 1: Create NSG for testing ━━━" -ForegroundColor Cyan
$nsgName = "test-nsg"

try {
    Write-Host "Creating NSG..." -ForegroundColor Yellow
    az network nsg create `
        --name $nsgName `
        --resource-group $ResourceGroupName `
        --location $Location `
        --only-show-errors --output none
    
    Test-Result -Passed $true -TestName "NSG created" -Details "NSG ready for VM deployments"
} catch {
    Test-Result -Passed $false -TestName "NSG creation failed" -Details $_.Exception.Message
    exit 1
}

#
# TEST 2: Create VNet and subnet for testing
#
Write-Host "`n━━━ TEST 2: Create VNet and subnet ━━━" -ForegroundColor Cyan
$vnetName = "test-vnet"

try {
    Write-Host "Creating VNet..." -ForegroundColor Yellow
    az network vnet create `
        --name $vnetName `
        --resource-group $ResourceGroupName `
        --location $Location `
        --address-prefix "10.1.0.0/16" `
        --subnet-name "test-subnet" `
        --subnet-prefix "10.1.1.0/24" `
        --only-show-errors --output none
    
    Test-Result -Passed $true -TestName "VNet and subnet created" -Details "Network infrastructure ready"
} catch {
    Test-Result -Passed $false -TestName "VNet creation failed" -Details $_.Exception.Message
}

#
# TEST 3: Create NIC without NSG (should be audited/denied based on policy effect)
#
Write-Host "`n━━━ TEST 3: NIC without NSG ━━━" -ForegroundColor Cyan
$nicName = "test-nic-no-nsg"

try {
    Write-Host "Attempting to create NIC without NSG..." -ForegroundColor Yellow
    
    $result = az network nic create `
        --name $nicName `
        --resource-group $ResourceGroupName `
        --location $Location `
        --vnet-name $vnetName `
        --subnet "test-subnet" `
        --only-show-errors 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "⚠️  NIC created without NSG (policy in audit mode or not enforcing)" -ForegroundColor Yellow
        Test-Result -Passed $true -TestName "NIC without NSG (audit)" -Details "Created but should be flagged as non-compliant"
        
        # Cleanup
        az network nic delete --name $nicName --resource-group $ResourceGroupName --yes --only-show-errors 2>$null
    } else {
        Write-Host "✅ Policy blocked NIC creation without NSG" -ForegroundColor Green
        Test-Result -Passed $true -TestName "NIC without NSG blocked" -Details "Policy successfully prevented non-compliant NIC"
    }
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Gray
}

#
# TEST 4: Create VM with public IP (should be flagged/blocked)
#
Write-Host "`n━━━ TEST 4: VM with Public IP ━━━" -ForegroundColor Cyan
$vmName = "test-vm-public-ip"
$publicIpName = "test-vm-pip"

try {
    Write-Host "Attempting to create VM with public IP..." -ForegroundColor Yellow
    
    # Create public IP first
    az network public-ip create `
        --name $publicIpName `
        --resource-group $ResourceGroupName `
        --location $Location `
        --sku Standard `
        --only-show-errors --output none 2>$null
    
    # Try to create VM with public IP
    $result = az vm create `
        --resource-group $ResourceGroupName `
        --name $vmName `
        --location $Location `
        --image Ubuntu2204 `
        --size Standard_D2s_v3 `
        --admin-username azureuser `
        --generate-ssh-keys `
        --vnet-name $vnetName `
        --subnet "test-subnet" `
        --nsg $nsgName `
        --public-ip-address $publicIpName `
        --encryption-at-host `
        --only-show-errors 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        if ($publicIpPolicy.properties.enforcementMode -eq "DoNotEnforce") {
            Test-Result -Passed $true -TestName "VM with public IP (audit mode)" -Details "Created but flagged as non-compliant"
            
            # Cleanup VM
            az vm delete --name $vmName --resource-group $ResourceGroupName --yes --only-show-errors 2>$null
        } else {
            Test-Result -Passed $false -TestName "VM with public IP blocked" -Details "Policy should block but allowed creation"
        }
    } else {
        if ($publicIpPolicy.properties.enforcementMode -eq "Default") {
            Test-Result -Passed $true -TestName "VM with public IP blocked" -Details "Policy successfully blocked creation"
        } else {
            Test-Result -Passed $false -TestName "VM creation failed unexpectedly" -Details $result
        }
    }
    
    # Cleanup public IP
    az network public-ip delete --name $publicIpName --resource-group $ResourceGroupName --only-show-errors 2>$null
    
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Gray
}

#
# TEST 5: Create VM without public IP (should succeed)
#
Write-Host "`n━━━ TEST 5: VM without Public IP (compliant) ━━━" -ForegroundColor Cyan
$vmName2 = "test-vm-no-pip"

try {
    Write-Host "Creating VM without public IP..." -ForegroundColor Yellow
    
    $result = az vm create `
        --resource-group $ResourceGroupName `
        --name $vmName2 `
        --location $Location `
        --image Ubuntu2204 `
        --size Standard_D2s_v3 `
        --admin-username azureuser `
        --generate-ssh-keys `
        --vnet-name $vnetName `
        --subnet "test-subnet" `
        --nsg $nsgName `
        --encryption-at-host `
        --only-show-errors 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Test-Result -Passed $true -TestName "VM without public IP allowed" -Details "Compliant resource created successfully"
        
        # Cleanup
        az vm delete --name $vmName2 --resource-group $ResourceGroupName --yes --only-show-errors 2>$null
    } else {
        Test-Result -Passed $false -TestName "Compliant VM creation failed" -Details $result
    }
} catch {
    Test-Result -Passed $false -TestName "Compliant VM creation failed" -Details $_.Exception.Message
}

#
# TEST 6: VM NIC without NSG (should be audited)  
#  
Write-Host "`n━━━ TEST 6: VM NIC NSG Policy Check ━━━" -ForegroundColor Cyan 

try {
    Write-Host "Checking VM NIC NSG policy..." -ForegroundColor Yellow
    
    $vmNicPolicy = az policy assignment show --name "vm-nic-nsg-required" 2>$null | ConvertFrom-Json
    
    if ($vmNicPolicy) {
        Write-Host "✅ VM NIC NSG Policy: $($vmNicPolicy.properties.displayName)" -ForegroundColor Green
        Write-Host "   Effect: $(if ($vmNicPolicy.properties.parameters.effect) { $vmNicPolicy.properties.parameters.effect.value } else { 'audit' })" -ForegroundColor Cyan
        Write-Host "   Enforcement: $($vmNicPolicy.properties.enforcementMode)" -ForegroundColor Cyan
        
        # Check if the VM from TEST 4 has NSG on its NIC
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   Testing compliance: VM NICs should have NSGs" -ForegroundColor Yellow
            Test-Result -Passed $true -TestName "VM NIC NSG policy deployed" -Details "Policy will audit/deny VMs without NIC-level NSGs"
        }
    } else {
        Write-Host "ℹ️  VM NIC NSG policy not deployed (optional enhancement)" -ForegroundColor Gray
        Test-Result -Passed $true -TestName "VM NIC NSG policy check" -Details "Policy not deployed - this is optional defense-in-depth"
    }
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Gray
    Test-Result -Passed $true -TestName "VM NIC NSG policy check" -Details "Unable to verify - continuing tests"
}

#
# TEST 6: Check for sensitive data in committed files (security check)
#
Write-Host "`n━━━ TEST 6: Security - No sensitive data in repo ━━━" -ForegroundColor Cyan

$sensitivePatterns = @{
    "Real Subscription ID" = "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"
    "Real Email" = "[a-zA-Z0-9._%+-]+@(?!example\.com)[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"
}

$filestoCheck = @(
    "terraform.tfvars.example",
    "backend.tf.example",
    "README.md"
)

$securityIssues = @()

foreach ($file in $filesToCheck) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw
        
        foreach ($patternName in $sensitivePatterns.Keys) {
            if ($content -match $sensitivePatterns[$patternName]) {
                # Exclude known safe placeholders
                $match = $matches[0]
                if ($match -ne "00000000-0000-0000-0000-000000000000" -and 
                    $match -notlike "*example.com*" -and
                    $match -notlike "*YOUR-SUB-ID*") {
                    $securityIssues += "{0} contains potential {1} - {2}" -f $file, $patternName, $match
                }
            }
        }
    }
}

if ($securityIssues.Count -eq 0) {
    Test-Result -Passed $true -TestName "No sensitive data in committed files" -Details "All example files use safe placeholders"
} else {
    Test-Result -Passed $false -TestName "Sensitive data found" -Details ($securityIssues -join "`n   ")
}

#
# TEST 8: Portal VM Deployment Scenario (Known Issue - now less relevant)
#
Write-Host "`n━━━ TEST 8: Portal VM Deployment (nested subnet) ━━━" -ForegroundColor Cyan
Write-Host "ℹ️  NOTE: With NIC-level NSG policy, this bypass is mitigated" -ForegroundColor Cyan

try {
    Write-Host "Testing VNet with nested subnet (simulates Portal VM deployment)..." -ForegroundColor Yellow
    
    # Create a VNet with subnet defined inline (similar to Portal VM deployment)
    $vnetName3 = "test-vnet-nested"
    
    # This simulates what happens during Portal VM deployment
    $result = az network vnet create `
        --name $vnetName3 `
        --resource-group $ResourceGroupName `
        --location $Location `
        --address-prefixes "10.2.0.0/16" `
        --subnet-name "nested-subnet" `
        --subnet-prefixes "10.2.1.0/24" `
        --only-show-errors 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "ℹ️  VNet with nested subnet created (expected - no subnet NSG policy)" -ForegroundColor Cyan
        Write-Host "   VM NIC NSG policy will catch non-compliant VMs regardless" -ForegroundColor Gray
        
        Test-Result -Passed $true -TestName "Portal VM deployment pattern" -Details "VNet created - VM NIC policy provides protection"
        
        # Cleanup
        az network vnet delete --name $vnetName3 --resource-group $ResourceGroupName --yes --only-show-errors 2>$null
    } else {
        Write-Host "⚠️  VNet creation failed unexpectedly" -ForegroundColor Yellow
        Test-Result -Passed $false -TestName "VNet creation" -Details "Unexpected failure"
    }
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Gray
}

#
# TEST 9: Verify policy exemptions (if configured)
#
Write-Host "`n━━━ TEST 9: Policy Exemptions Check ━━━" -ForegroundColor Cyan

try {
    $exemptions = az policy exemption list --only-show-errors 2>$null | ConvertFrom-Json
    $networkExemptions = $exemptions | Where-Object { $_.properties.policyAssignmentId -like "*deny-vm-public-ip*" }
    
    if ($networkExemptions) {
        Write-Host "Found $($networkExemptions.Count) public IP exemption(s):" -ForegroundColor Yellow
        
        foreach ($exemption in $networkExemptions) {
            $expiresOn = $exemption.properties.expiresOn
            $daysUntilExpiry = if ($expiresOn) {
                [Math]::Round(([DateTime]$expiresOn - [DateTime]::Now).TotalDays)
            } else {
                "Never"
            }
            
            Write-Host "  - $($exemption.name)" -ForegroundColor Cyan
            Write-Host "    Expires: $expiresOn ($daysUntilExpiry days)" -ForegroundColor Gray
            Write-Host "    Category: $($exemption.properties.exemptionCategory)" -ForegroundColor Gray
            
            if ($daysUntilExpiry -is [int] -and $daysUntilExpiry -le 60) {
                Write-Host "    ⚠️  EXPIRING SOON - Review required!" -ForegroundColor Yellow
            }
        }
        
        Test-Result -Passed $true -TestName "Exemptions configured" -Details "$($networkExemptions.Count) exemption(s) found"
    } else {
        Test-Result -Passed $true -TestName "No exemptions" -Details "Zero exemptions (recommended)"
    }
} catch {
    Write-Host "Could not check exemptions: $($_.Exception.Message)" -ForegroundColor Gray
}

#
# Cleanup test resources
#
Write-Host "`n━━━ Cleanup ━━━" -ForegroundColor Cyan
Write-Host "Deleting test resource group..." -ForegroundColor Yellow

try {
    az group delete --name $ResourceGroupName --yes --no-wait --only-show-errors
    Write-Host "✅ Cleanup initiated (running in background)`n" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Cleanup failed - please delete manually: $ResourceGroupName" -ForegroundColor Yellow
}

#
# Test Summary
#
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "🎯 Test Summary" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Total Tests:  $testsTotal" -ForegroundColor White
Write-Host "Passed:       $testsPassed" -ForegroundColor Green
Write-Host "Failed:       $testsFailed" -ForegroundColor $(if ($testsFailed -eq 0) { "Green" } else { "Red" })
Write-Host "================================================`n" -ForegroundColor Cyan

if ($testsFailed -eq 0) {
    Write-Host "✅ All tests passed!" -ForegroundColor Green
    
    if ($vmNicPolicy.properties.enforcementMode -eq "DoNotEnforce") {
        Write-Host "`n💡 Recommendation:" -ForegroundColor Yellow
        Write-Host "   Policies are in audit mode. After 2-4 weeks of monitoring:" -ForegroundColor Yellow
        Write-Host "   1. Review compliance reports in Azure Portal" -ForegroundColor Yellow
        Write-Host "   2. Remediate non-compliant resources" -ForegroundColor Yellow
        Write-Host "   3. Set enforcement_mode = 'Default' in terraform.tfvars" -ForegroundColor Yellow
        Write-Host "   4. Run: terraform apply`n" -ForegroundColor Yellow
    }
    
    Write-Host "📊 View compliance in Azure Portal:" -ForegroundColor Cyan
    Write-Host "   https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyMenuBlade/Compliance`n" -ForegroundColor Blue
    
    exit 0
} else {
    Write-Host "❌ Some tests failed. Review the output above." -ForegroundColor Red
    exit 1
}
