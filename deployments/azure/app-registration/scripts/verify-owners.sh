#!/usr/bin/env bash
#
# verify-owners.sh
# Verifies app registration owners exist in Entra ID, are enabled, and meet requirements
# Enforces: minimum 2 total owners, minimum 1 human owner, maximum 1 placeholder service principal
#
# Usage: ./verify-owners.sh <path-to-terraform-files> [app-registration-id]
# Outputs: JSON with owner verification results

set -euo pipefail

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

TF_DIR="${1:-.}"
APP_REG_ID="${2:-}"

echo "👥 Verifying app registration owners..."
echo "📂 Scanning: $TF_DIR"
echo ""

# Check Azure CLI
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI not installed${NC}" >&2
    exit 1
fi

# Check if logged in
if ! az account show &> /dev/null; then
    echo -e "${RED}Error: Not logged into Azure CLI. Run 'az login'${NC}" >&2
    exit 1
fi

# Extract app_owners from Terraform files
OWNERS_RAW=$(grep -r "app_owners\s*=" "$TF_DIR" -A 20 2>/dev/null | grep -E '^\s*"[^"]+"\s*,?' | sed 's/[",]//g' | tr -d ' ' || echo "")

if [[ -z "$OWNERS_RAW" ]]; then
    echo -e "${RED}❌ No app_owners variable found in Terraform files${NC}" >&2
    echo '{"validation_errors": ["No app_owners variable found"], "requested_owners": [], "human_owner_count": 0, "placeholder_count": 0}'
    exit 1
fi

# Parse owners into array
IFS=$'\n' read -rd '' -a OWNERS_ARRAY <<< "$OWNERS_RAW" || true

TOTAL_OWNERS=${#OWNERS_ARRAY[@]}
HUMAN_COUNT=0
PLACEHOLDER_COUNT=0
VERIFIED_OWNERS='[]'
VALIDATION_ERRORS='[]'
DISABLED_OWNERS='[]'

echo "Found $TOTAL_OWNERS owner(s) in configuration"
echo ""

# Verify each owner
for owner in "${OWNERS_ARRAY[@]}"; do
    if [[ -z "$owner" ]]; then
        continue
    fi
    
    echo "🔍 Verifying: $owner"
    
    # Try to query as user first
    USER_INFO=$(az ad user show --id "$owner" 2>/dev/null || echo "")
    
    if [[ -n "$USER_INFO" ]]; then
        # It's a user
        DISPLAY_NAME=$(echo "$USER_INFO" | jq -r '.displayName // "Unknown"')
        OBJECT_ID=$(echo "$USER_INFO" | jq -r '.id')
        ACCOUNT_ENABLED=$(echo "$USER_INFO" | jq -r '.accountEnabled // false')
        
        echo "  ✓ Type: User"
        echo "  ✓ Display Name: $DISPLAY_NAME"
        echo "  ✓ Object ID: $OBJECT_ID"
        
        if [[ "$ACCOUNT_ENABLED" == "true" ]]; then
            echo -e "  ${GREEN}✓ Status: Enabled${NC}"
            ((HUMAN_COUNT++))
        else
            echo -e "  ${RED}✗ Status: Disabled${NC}"
            VALIDATION_ERRORS=$(echo "$VALIDATION_ERRORS" | jq --arg email "$owner" '. += ["User account disabled: \($email)"]')
            
            # Check for days since disabled (requires audit logs - simplified here)
            DISABLED_OWNERS=$(echo "$DISABLED_OWNERS" | jq --arg email "$owner" --argjson days 0 '. += [{"email": $email, "type": "user", "days_disabled": $days}]')
        fi
        
        VERIFIED_OWNERS=$(echo "$VERIFIED_OWNERS" | jq \
            --arg email "$owner" \
            --arg objectId "$OBJECT_ID" \
            --arg displayName "$DISPLAY_NAME" \
            --arg type "user" \
            --argjson enabled "$ACCOUNT_ENABLED" \
            '. += [{"email": $email, "objectId": $objectId, "displayName": $displayName, "type": $type, "enabled": $enabled}]')
    else
        # Try as service principal
        SP_INFO=$(az ad sp show --id "$owner" 2>/dev/null || echo "")
        
        if [[ -n "$SP_INFO" ]]; then
            # It's a service principal
            DISPLAY_NAME=$(echo "$SP_INFO" | jq -r '.displayName // "Unknown"')
            OBJECT_ID=$(echo "$SP_INFO" | jq -r '.id')
            APP_ID=$(echo "$SP_INFO" | jq -r '.appId')
            
            echo "  ✓ Type: Service Principal"
            echo "  ✓ Display Name: $DISPLAY_NAME"
            echo "  ✓ Object ID: $OBJECT_ID"
            echo "  ✓ App ID: $APP_ID"
            echo -e "  ${YELLOW}⚠️  Non-human account (placeholder)${NC}"
            
            ((PLACEHOLDER_COUNT++))
            
            VERIFIED_OWNERS=$(echo "$VERIFIED_OWNERS" | jq \
                --arg email "$owner" \
                --arg objectId "$OBJECT_ID" \
                --arg displayName "$DISPLAY_NAME" \
                --arg type "servicePrincipal" \
                --arg appId "$APP_ID" \
                '. += [{"email": $email, "objectId": $objectId, "displayName": $displayName, "type": $type, "appId": $appId, "enabled": true}]')
        else
            echo -e "  ${RED}✗ Not found in Entra ID${NC}"
            VALIDATION_ERRORS=$(echo "$VALIDATION_ERRORS" | jq --arg owner "$owner" '. += ["Owner not found: \($owner)"]')
        fi
    fi
    echo ""
done

# Validate requirements
echo "📋 Validation Results:"
echo "  Total owners: $TOTAL_OWNERS"
echo "  Human owners: $HUMAN_COUNT"
echo "  Placeholder service principals: $PLACEHOLDER_COUNT"
echo ""

# Check minimum 2 owners
if [[ $TOTAL_OWNERS -lt 2 ]]; then
    echo -e "${RED}❌ FAIL: Minimum 2 owners required (found: $TOTAL_OWNERS)${NC}"
    VALIDATION_ERRORS=$(echo "$VALIDATION_ERRORS" | jq '. += ["Minimum 2 owners required"]')
fi

# Check minimum 1 human owner
if [[ $HUMAN_COUNT -lt 1 ]]; then
    echo -e "${RED}❌ FAIL: Minimum 1 human owner required (found: $HUMAN_COUNT)${NC}"
    VALIDATION_ERRORS=$(echo "$VALIDATION_ERRORS" | jq '. += ["Minimum 1 human owner required"]')
fi

# Check maximum 1 placeholder
if [[ $PLACEHOLDER_COUNT -gt 1 ]]; then
    echo -e "${RED}❌ FAIL: Maximum 1 placeholder service principal allowed (found: $PLACEHOLDER_COUNT)${NC}"
    VALIDATION_ERRORS=$(echo "$VALIDATION_ERRORS" | jq '. += ["Maximum 1 placeholder service principal allowed"]')
fi

# Check placeholder justification if placeholder present
if [[ $PLACEHOLDER_COUNT -gt 0 ]]; then
    JUSTIFICATION=$(grep -r "placeholder_owner_justification\s*=" "$TF_DIR" 2>/dev/null || echo "")
    if [[ -z "$JUSTIFICATION" ]]; then
        echo -e "${RED}❌ FAIL: Placeholder service principal requires placeholder_owner_justification variable${NC}"
        VALIDATION_ERRORS=$(echo "$VALIDATION_ERRORS" | jq '. += ["Placeholder owner requires 50-character justification"]')
    else
        # Extract justification text and check length (simplified)
        JUST_LENGTH=$(echo "$JUSTIFICATION" | wc -c)
        if [[ $JUST_LENGTH -lt 50 ]]; then
            echo -e "${RED}❌ FAIL: Placeholder justification must be minimum 50 characters (found: $JUST_LENGTH)${NC}"
            VALIDATION_ERRORS=$(echo "$VALIDATION_ERRORS" | jq --argjson len "$JUST_LENGTH" '. += ["Placeholder justification too short: \($len) chars, minimum 50 required"]')
        else
            echo -e "${GREEN}✓ Placeholder justification provided (≥50 chars)${NC}"
        fi
    fi
fi

ERROR_COUNT=$(echo "$VALIDATION_ERRORS" | jq 'length')

if [[ $ERROR_COUNT -eq 0 ]]; then
    echo ""
    echo -e "${GREEN}✅ All owner validations passed${NC}"
    EXIT_CODE=0
else
    echo ""
    echo -e "${RED}❌ Validation failed with $ERROR_COUNT error(s)${NC}"
    EXIT_CODE=1
fi

# Output JSON result
jq -n \
  --argjson owners "$VERIFIED_OWNERS" \
  --argjson errors "$VALIDATION_ERRORS" \
  --argjson disabled "$DISABLED_OWNERS" \
  --argjson humanCount "$HUMAN_COUNT" \
  --argjson placeholderCount "$PLACEHOLDER_COUNT" \
  --argjson totalCount "$TOTAL_OWNERS" \
  '{
    "requested_owners": $owners,
    "validation_errors": $errors,
    "disabled_owners_with_age": $disabled,
    "human_owner_count": $humanCount,
    "placeholder_count": $placeholderCount,
    "total_owner_count": $totalCount,
    "validation_passed": ($errors | length == 0)
  }'

exit $EXIT_CODE
