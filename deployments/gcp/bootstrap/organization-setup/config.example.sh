#!/bin/bash
# GCP Organization Configuration Template
# Copy this file to config.sh and fill in your actual values
# DO NOT commit config.sh to version control!

# Organization Details
export GCP_ORG_ID="your-org-id-here"              # e.g., 123456789012
export GCP_ORG_DOMAIN="your-domain.com"           # e.g., example.com

# Billing Account
export GCP_BILLING_ACCOUNT_ID="your-billing-id"  # e.g., ABCDEF-123456-789012

# Project IDs
export GCP_DEV_PROJECT_ID="your-dev-project-id"  # e.g., my-dev-project
export GCP_PROD_PROJECT_ID="your-prod-project-id" # e.g., my-prod-project

# User Accounts
export GCP_ADMIN_EMAIL="your-admin@your-domain.com"        # Your M365 admin account
export GCP_BREAKGLASS_EMAIL="svc-xe7k9m@your-domain.com"   # Emergency access account (use obscure name, not "breakglass")

# Azure Key Vault (for storing GCP secrets)
export AZURE_KEYVAULT_NAME="your-keyvault-name"

# Load configuration in scripts:
# source ./config.sh
