#!/bin/bash
# Script to clean up old IP addresses from storage account firewall

set -e

STORAGE_ACCOUNT="tfstate20251013"
RESOURCE_GROUP="rg-tfstate"

echo "🔍 Getting current IP address..."
CURRENT_IP=$(curl -s ifconfig.me)
echo "📍 Current IP: $CURRENT_IP"
echo ""

echo "📋 All whitelisted IPs:"
ALL_IPS=$(az storage account show \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --query "networkRuleSet.ipRules[].value" \
  --output tsv)

if [ -z "$ALL_IPS" ]; then
    echo "   (none)"
    echo ""
    echo "✅ No IPs to clean up!"
    exit 0
fi

echo "$ALL_IPS" | while read -r IP; do
    if [ "$IP" = "$CURRENT_IP" ]; then
        echo "   $IP (current - will keep)"
    else
        echo "   $IP (old - will remove)"
    fi
done

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
        2>/dev/null || true
    
    # Remove all IPs except current
    echo "$ALL_IPS" | while read -r IP; do
        if [ "$IP" != "$CURRENT_IP" ]; then
            echo "   Removing $IP..."
            az storage account network-rule remove \
                --account-name "$STORAGE_ACCOUNT" \
                --resource-group "$RESOURCE_GROUP" \
                --ip-address "$IP"
        fi
    done
    
    echo ""
    echo "✅ Cleanup complete!"
    echo ""
    echo "📋 Remaining IPs:"
    az storage account show \
        --name "$STORAGE_ACCOUNT" \
        --resource-group "$RESOURCE_GROUP" \
        --query "networkRuleSet.ipRules[].value" \
        --output table
else
    echo ""
    echo "❌ Cleanup cancelled."
fi
