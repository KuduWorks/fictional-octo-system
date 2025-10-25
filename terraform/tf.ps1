# Terraform wrapper that ensures IP is whitelisted before operations

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

# Update IP before running Terraform
& "$SCRIPT_DIR\update-ip.ps1"

Write-Host ""
Write-Host "🚀 Running: terraform $args" -ForegroundColor Cyan
Write-Host ""

# Run Terraform with all passed arguments
terraform @args
