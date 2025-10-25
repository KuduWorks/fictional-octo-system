#!/bin/bash
# Terraform wrapper that ensures IP is whitelisted before operations

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Update IP before running Terraform
"$SCRIPT_DIR/update-ip.sh"

echo ""
echo "🚀 Running: terraform $@"
echo ""

# Run Terraform with all passed arguments
terraform "$@"
