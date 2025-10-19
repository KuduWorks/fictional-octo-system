#!/bin/bash

# Azure CLI Script for Deploying Region Control Policies
# This script creates Azure policies to restrict resource deployment to Sweden Central

set -e

# Configuration Variables
ALLOWED_REGIONS='["swedencentral"]'
POLICY_ASSIGNMENT_NAME="allowed-regions-sweden-central"
POLICY_DISPLAY_NAME="Allowed Regions Policy - Sweden Central"
POLICY_DESCRIPTION="This policy restricts all Azure resource deployments to Sweden Central region only"
ENFORCEMENT_MODE="Default"  # Default or DoNotEnforce
SUBSCRIPTION_ID=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Azure Policy CLI Deployment Script ===${NC}"

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if user is logged in
if ! az account show &> /dev/null; then
    echo -e "${YELLOW}You are not logged in to Azure. Please log in...${NC}"
    az login
fi

# Get current subscription if not provided
if [ -z "$SUBSCRIPTION_ID" ]; then
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    echo -e "${BLUE}Using current subscription: $SUBSCRIPTION_ID${NC}"
fi

# Set the subscription
az account set --subscription "$SUBSCRIPTION_ID"

echo -e "${BLUE}Current subscription:${NC}"
az account show --query "{subscriptionId:id, subscriptionName:name, tenantId:tenantId}" -o table

# Function to create custom policy definition
create_custom_policy_definition() {
    echo -e "${YELLOW}Creating custom resource group location policy...${NC}"
    
    cat > rg-location-policy.json << EOF
{
  "mode": "All",
  "policyRule": {
    "if": {
      "allOf": [
        {
          "field": "type",
          "equals": "Microsoft.Resources/resourceGroups"
        },
        {
          "field": "location",
          "notIn": "[parameters('allowedLocations')]"
        }
      ]
    },
    "then": {
      "effect": "deny"
    }
  },
  "parameters": {
    "allowedLocations": {
      "type": "Array",
      "metadata": {
        "displayName": "Allowed locations",
        "description": "The list of locations that resource groups can be created in",
        "strongType": "location"
      }
    }
  }
}
EOF

    az policy definition create \
        --name "custom-rg-location-policy" \
        --display-name "Resource Groups must be in allowed locations" \
        --description "This policy ensures that resource groups are created only in approved Azure regions" \
        --rules rg-location-policy.json \
        --mode All \
        --subscription "$SUBSCRIPTION_ID"
    
    rm rg-location-policy.json
    echo -e "${GREEN}Custom policy definition created successfully!${NC}"
}

# Function to create policy set definition (initiative)
create_policy_set_definition() {
    echo -e "${YELLOW}Creating policy set definition (initiative)...${NC}"
    
    ALLOWED_LOCATIONS_POLICY_ID="/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
    CUSTOM_RG_POLICY_ID="/subscriptions/$SUBSCRIPTION_ID/providers/Microsoft.Authorization/policyDefinitions/custom-rg-location-policy"
    
    cat > policy-set-definition.json << EOF
{
  "policyDefinitions": [
    {
      "policyDefinitionId": "$ALLOWED_LOCATIONS_POLICY_ID",
      "parameters": {
        "listOfAllowedLocations": {
          "value": "[parameters('allowedLocations')]"
        }
      },
      "policyDefinitionReferenceId": "AllowedLocationsPolicy"
    },
    {
      "policyDefinitionId": "$CUSTOM_RG_POLICY_ID",
      "parameters": {
        "allowedLocations": {
          "value": "[parameters('allowedLocations')]"
        }
      },
      "policyDefinitionReferenceId": "ResourceGroupLocationPolicy"
    }
  ],
  "parameters": {
    "allowedLocations": {
      "type": "Array",
      "metadata": {
        "displayName": "Allowed locations",
        "description": "The list of locations that resources can be created in",
        "strongType": "location"
      },
      "defaultValue": $ALLOWED_REGIONS
    }
  }
}
EOF

    az policy set-definition create \
        --name "region-control-initiative" \
        --display-name "Region Control Initiative - Sweden Central" \
        --description "A collection of policies to control resource deployment regions" \
        --definitions policy-set-definition.json \
        --subscription "$SUBSCRIPTION_ID"
    
    rm policy-set-definition.json
    echo -e "${GREEN}Policy set definition created successfully!${NC}"
}

# Function to assign built-in allowed locations policy
assign_allowed_locations_policy() {
    echo -e "${YELLOW}Assigning built-in allowed locations policy...${NC}"
    
    ALLOWED_LOCATIONS_POLICY_ID="/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
    SCOPE="/subscriptions/$SUBSCRIPTION_ID"
    
    az policy assignment create \
        --name "$POLICY_ASSIGNMENT_NAME" \
        --display-name "$POLICY_DISPLAY_NAME" \
        --description "$POLICY_DESCRIPTION" \
        --policy "$ALLOWED_LOCATIONS_POLICY_ID" \
        --scope "$SCOPE" \
        --params "{ \"listOfAllowedLocations\": { \"value\": $ALLOWED_REGIONS } }" \
        --assign-identity \
        --location "swedencentral"
    
    echo -e "${GREEN}Built-in policy assigned successfully!${NC}"
}

# Function to assign custom resource group location policy
assign_custom_rg_policy() {
    echo -e "${YELLOW}Assigning custom resource group location policy...${NC}"
    
    CUSTOM_RG_POLICY_ID="/subscriptions/$SUBSCRIPTION_ID/providers/Microsoft.Authorization/policyDefinitions/custom-rg-location-policy"
    SCOPE="/subscriptions/$SUBSCRIPTION_ID"
    
    az policy assignment create \
        --name "rg-location-policy-assignment" \
        --display-name "Resource Group Location Control - Sweden Central" \
        --description "Ensures resource groups are created only in Sweden Central" \
        --policy "$CUSTOM_RG_POLICY_ID" \
        --scope "$SCOPE" \
        --params "{ \"allowedLocations\": { \"value\": $ALLOWED_REGIONS } }" \
        --assign-identity \
        --location "swedencentral"
    
    echo -e "${GREEN}Custom resource group policy assigned successfully!${NC}"
}

# Function to assign policy set (initiative)
assign_policy_set() {
    echo -e "${YELLOW}Assigning policy set (initiative)...${NC}"
    
    POLICY_SET_ID="/subscriptions/$SUBSCRIPTION_ID/providers/Microsoft.Authorization/policySetDefinitions/region-control-initiative"
    SCOPE="/subscriptions/$SUBSCRIPTION_ID"
    
    az policy assignment create \
        --name "region-control-initiative-assignment" \
        --display-name "Region Control Initiative Assignment - Sweden Central" \
        --description "Assignment of the region control initiative to enforce Sweden Central deployment" \
        --policy-set-definition "$POLICY_SET_ID" \
        --scope "$SCOPE" \
        --params "{ \"allowedLocations\": { \"value\": $ALLOWED_REGIONS } }" \
        --assign-identity \
        --location "swedencentral"
    
    echo -e "${GREEN}Policy set assigned successfully!${NC}"
}

# Function to list created policies
list_policies() {
    echo -e "${BLUE}Listing created policy assignments:${NC}"
    az policy assignment list \
        --query "[?contains(name, 'allowed-regions') || contains(name, 'rg-location') || contains(name, 'region-control')].{Name:name, DisplayName:displayName, Scope:scope}" \
        --output table
}

# Function to test policy enforcement
test_policy() {
    echo -e "${BLUE}Testing policy enforcement...${NC}"
    echo -e "${YELLOW}Attempting to create a resource group in a non-allowed region (should fail):${NC}"
    
    if az group create --name "test-policy-enforcement" --location "eastus" 2>/dev/null; then
        echo -e "${RED}WARNING: Policy enforcement failed - resource group was created in non-allowed region!${NC}"
        az group delete --name "test-policy-enforcement" --yes --no-wait
    else
        echo -e "${GREEN}SUCCESS: Policy enforcement working - resource group creation blocked!${NC}"
    fi
    
    echo -e "${YELLOW}Attempting to create a resource group in allowed region (should succeed):${NC}"
    if az group create --name "test-policy-allowed" --location "swedencentral"; then
        echo -e "${GREEN}SUCCESS: Resource group created in allowed region!${NC}"
        echo -e "${BLUE}Cleaning up test resource group...${NC}"
        az group delete --name "test-policy-allowed" --yes --no-wait
    else
        echo -e "${RED}ERROR: Could not create resource group in allowed region!${NC}"
    fi
}

# Main execution
echo -e "${BLUE}Starting policy deployment...${NC}"

# Ask for confirmation
echo -e "${YELLOW}This script will create Azure policies to restrict resource deployment to Sweden Central.${NC}"
echo -e "${YELLOW}Do you want to proceed? (y/N):${NC}"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Script cancelled.${NC}"
    exit 0
fi

# Execute deployment steps
create_custom_policy_definition
sleep 5  # Wait for policy definition to propagate

create_policy_set_definition
sleep 5  # Wait for policy set definition to propagate

assign_allowed_locations_policy
sleep 5  # Wait for policy assignment to propagate

assign_custom_rg_policy
sleep 5  # Wait for policy assignment to propagate

assign_policy_set
sleep 10  # Wait for all policies to propagate

list_policies

echo -e "${GREEN}=== Policy Deployment Complete! ===${NC}"
echo -e "${GREEN}All future resource deployments will be restricted to Sweden Central.${NC}"

# Ask if user wants to test the policies
echo -e "${YELLOW}Would you like to test the policy enforcement? (y/N):${NC}"
read -r test_response
if [[ "$test_response" =~ ^[Yy]$ ]]; then
    test_policy
fi

echo -e "${BLUE}=== Script Complete ===${NC}"