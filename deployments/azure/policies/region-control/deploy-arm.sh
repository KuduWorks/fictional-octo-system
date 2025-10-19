#!/bin/bash

# ARM Template Deployment Script for Azure Region Control Policies
# This script deploys Azure policies using ARM templates to restrict resource deployment to Sweden Central

set -e

# Variables
SUBSCRIPTION_ID=""
DEPLOYMENT_NAME="azure-policy-arm-sweden-central-$(date +%Y%m%d-%H%M%S)"
TEMPLATE_FILE="arm-template.json"
PARAMETERS_FILE="arm-template.parameters.json"
LOCATION="swedencentral"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== ARM Template Deployment for Azure Region Control Policies ===${NC}"

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

# Validate the ARM template
echo -e "${YELLOW}Validating ARM template...${NC}"
if az deployment sub validate \
    --location "$LOCATION" \
    --template-file "$TEMPLATE_FILE" \
    --parameters "$PARAMETERS_FILE" \
    --only-show-errors; then
    echo -e "${GREEN}ARM template validation successful!${NC}"
else
    echo -e "${RED}ARM template validation failed. Please check the template and parameters.${NC}"
    exit 1
fi

# Preview the deployment (what-if)
echo -e "${YELLOW}Running deployment preview (what-if analysis)...${NC}"
az deployment sub what-if \
    --location "$LOCATION" \
    --template-file "$TEMPLATE_FILE" \
    --parameters "$PARAMETERS_FILE" \
    --name "$DEPLOYMENT_NAME"

# Ask for confirmation
echo -e "${YELLOW}Do you want to proceed with the ARM template deployment? (y/N):${NC}"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Deployment cancelled.${NC}"
    exit 0
fi

# Deploy the policies using ARM template
echo -e "${BLUE}Deploying Azure policies using ARM template...${NC}"
DEPLOYMENT_RESULT=$(az deployment sub create \
    --location "$LOCATION" \
    --template-file "$TEMPLATE_FILE" \
    --parameters "$PARAMETERS_FILE" \
    --name "$DEPLOYMENT_NAME" \
    --query "properties.provisioningState" -o tsv)

if [ "$DEPLOYMENT_RESULT" = "Succeeded" ]; then
    echo -e "${GREEN}=== ARM Template Deployment Successful! ===${NC}"
    
    # Get deployment outputs
    echo -e "${BLUE}Deployment outputs:${NC}"
    az deployment sub show \
        --name "$DEPLOYMENT_NAME" \
        --query "properties.outputs" \
        --output table
    
    # List the created policy assignments
    echo -e "${BLUE}Policy assignments created:${NC}"
    az policy assignment list \
        --query "[?contains(name, 'allowed-regions') || contains(name, 'rg-location') || contains(name, 'region-control')].{Name:name, DisplayName:displayName, Scope:scope, EnforcementMode:enforcementMode}" \
        --output table
    
    echo -e "${GREEN}Region control policies have been successfully deployed using ARM template!${NC}"
    echo -e "${GREEN}All future resource deployments will be restricted to Sweden Central.${NC}"
    
    # Show Azure Portal link
    echo -e "${BLUE}View your deployment in Azure Portal:${NC}"
    echo -e "${BLUE}https://portal.azure.com/#blade/HubsExtension/DeploymentDetailsBlade/overview/id/%2Fsubscriptions%2F${SUBSCRIPTION_ID}%2Fproviders%2FMicrosoft.Resources%2Fdeployments%2F${DEPLOYMENT_NAME}${NC}"
    
else
    echo -e "${RED}Deployment failed with status: $DEPLOYMENT_RESULT${NC}"
    echo -e "${RED}Please check the deployment details in Azure portal.${NC}"
    exit 1
fi

echo -e "${BLUE}=== ARM Template Deployment Complete ===${NC}"