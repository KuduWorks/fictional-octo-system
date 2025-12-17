#!/bin/bash
# Script to clean up old IP addresses from storage account firewall

set -e

STORAGE_ACCOUNT="tfstate20251013"
RESOURCE_GROUP="rg-tfstate"

echo "🔍 Getting current IP address..."
CURRENT_IP=$(curl -s ifconfig.me)
echo "📍 Current IP: $CURRENT_IP"
echo ""

# Validate CURRENT_IP is a non-empty valid IPv4 address
if ! [[ "$CURRENT_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    echo "❌ Failed to retrieve a valid current IP address. Aborting cleanup."
    exit 1
fi

echo "📋 All whitelisted IPs:"
ALL_IPS=$(az storage account show \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --query "networkRuleSet.ipRules[].value" \
  --output tsv \
  --only-show-errors)

if [ -z "$ALL_IPS" ]; then
    echo "   (none)"
    echo ""
    echo "✅ No IPs to clean up!"
    exit 0
fi

while IFS= read -r IP; do
    if [ "$IP" = "$CURRENT_IP" ]; then
        echo "   $IP (current - will keep)"
    else
        echo "   $IP (old - will remove)"
    fi
done <<< "$ALL_IPS"

echo ""
read -p "❓ Remove all IPs except current ($CURRENT_IP)? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "🧹 Cleaning up old IPs..."
    
    # First, ensure current IP is added
    az storage account network-rule add \
        --account-name "$STORAGE_ACCOUNT" \
        --resource-group "$RESOURCE_GROUP" \
        --ip-address "$CURRENT_IP" \
        --only-show-errors \
        2>/dev/null || true
    
    # Remove all IPs except current
    while IFS= read -r IP; do
        if [ "$IP" != "$CURRENT_IP" ]; then
            echo "   Removing $IP..."
            az storage account network-rule remove \
                --account-name "$STORAGE_ACCOUNT" \
                --resource-group "$RESOURCE_GROUP" \
                --ip-address "$IP" \
                --only-show-errors
        fi
    done <<< "$ALL_IPS"
    
    echo ""
    echo "✅ Cleanup complete!"
    echo ""
    echo "📋 Remaining IPs:"
    az storage account show \
        --name "$STORAGE_ACCOUNT" \
        --resource-group "$RESOURCE_GROUP" \
        --query "networkRuleSet.ipRules[].value" \
        --output table \
        --only-show-errors
else
    echo ""
    echo "❌ Cleanup cancelled."
fi
