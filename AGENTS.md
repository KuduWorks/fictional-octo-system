# Copilot Agent Guide

This document helps align GitHub Copilot with repository standards, security expectations, and preferred workflows. Use it as reference before prompting Copilot so generated changes match project practices.

## Purpose and Scope
- Apply these guidelines when asking Copilot to generate code, infrastructure, documentation, or automation for this repository.
- Keep prompts concise and reference relevant folders (deployments/aws, deployments/azure, deployments/gcp, terraform) so Copilot scopes changes correctly.
- Favor modular, reviewable pull requests that follow contribution expectations from CONTRIBUTING.md.

## ⚠️ Public Repository Guidelines
**This is a PUBLIC repository. All generated content must be safe for public visibility.**

- **Generalize all identifiers in documentation**: Never include actual subscription IDs, account IDs, tenant IDs, storage account names, or organization-specific resource names in README files or documentation.
  - ✅ Use: `yourstorageaccount`, `<your-subscription-id>`, `<your-org>/<your-repo>`
  - ❌ Avoid: `tfstateprod20251215`, `3025782a-c912-49dd-ab77-7167b5d3e0fa`, `KuduWorks/fictional-octo-system`

- **Always include .gitignore files**: Every deployment folder and Terraform project must have a `.gitignore` that excludes:
  - State files: `*.tfstate`, `*.tfstate.*`, `*.tfstate.backup`
  - Variables: `terraform.tfvars`, `*.auto.tfvars` (except `.example` files)
  - Secrets: `*.pem`, `*.key`, `*.pfx`, credentials files
  - Generated files: `.terraform/`, `crash.log`

- **Use the variables.tf and .tfvars.example pattern**: 
  - Define all configurable values in `variables.tf` with clear descriptions
  - Provide `terraform.tfvars.example` with placeholder/example values
  - Add `terraform.tfvars` and `*.auto.tfvars` to `.gitignore` - these files should NEVER be committed
  - Document in README how to copy and customize the example file

- **Sanitize workflow files**: GitHub Actions workflows should use repository secrets (`${{ secrets.AZURE_SUBSCRIPTION_ID }}`) instead of hardcoded values.

- **Prompt Copilot explicitly**: When asking Copilot to create documentation or examples, include: "This is a public repo - use generic placeholders for all subscription IDs, account numbers, and resource names."

## Coding and Testing Standards
- Terraform: request terraform fmt -recursive, terraform validate, and terraform plan before proposing changes. Use descriptive module names, enforce encryption defaults, and update terraform-docs style module docs when modules change.
- Shell scripts: adopt set -euo pipefail, avoid subshell while loops, use clear success/failure messaging, and prefer Azure CLI flags like --only-show-errors for cleaner output.
- PowerShell: include #Requires statements, use Set-StrictMode -Version Latest, and test with WhatIf when applicable.
- Documentation: ask Copilot to refresh README excerpts or module docs after code changes and explain rationale rather than restating code.
- Automation: mention existing pre-commit hooks and CI checks so Copilot keeps generated code compatible with repo automation.

## Security Expectations
- Never embed secrets or credentials; reference secure stores (Key Vault, AWS Secrets Manager, GCP Secret Manager) instead.
- When generating sensitive handling code, instruct Copilot to redact secrets in logs and describe how redaction works.
- Remind Copilot that security issues must be disclosed privately following the instructions in SECURITY.md, and only currently supported release lines receive fixes.

## Performance-Friendly Patterns
- Consolidate repeated cloud CLI calls, cache responses when practical, and surface progress clearly.
- Prefer direct loops or here-strings instead of pipe-to-while constructs that spawn subshells.
- Ask for graceful fallbacks when optional dependencies (jq, parallel) are missing.

## Deployment Folder Conventions
- Each new deployment package must include a .gitignore that excludes state files, local artifacts, and generated outputs.
- Never commit live terraform.tfvars files; always add them to .gitignore, provide terraform.tfvars.example templates only, and ensure prompts reinforce this rule.
- Reference the appropriate cloud folder when prompting so Copilot keeps provider-specific resources isolated.

## Quick Copilot Prompt Seeds
Use or adapt these short instructions when prompting Copilot:
- "In deployments/azure/key-vault, prepare steps: az login, terraform init, terraform plan, terraform apply, and document prerequisites."
- "For AWS state bootstrap, ensure workflow runs aws configure, cd deployments/aws/terraform-state-bootstrap, terraform init, terraform apply, with security notes."
- "For GCP bootstrap, include gcloud auth application-default login, cd deployments/gcp/bootstrap/state-storage, terraform init, terraform apply, and required roles."
- "Update Terraform module docs with terraform-docs format, inputs/outputs, and usage sample."
- "Create Export-AzureIAMReport.ps1 guidance covering Tenant ID prompt, Az and Microsoft Graph module installation, timestamped CSV/JSON outputs."
- "Generate branch plan using feature/ or fix/ prefix, conventional commit type(scope): subject, and list tests run (terraform fmt/validate/plan, shellcheck, PowerShell WhatIf)."

## Sensitive Data Handling
- **Critical**: This repository is PUBLIC - direct Copilot to mask or omit ALL environment-specific identifiers:
  - Subscription IDs, account IDs, tenant IDs
  - Resource names (storage accounts, resource groups, key vaults)
  - Email addresses, organization names
  - Any value that could identify production infrastructure
- When creating diagnostics or logs, include instructions to sanitize outputs before sharing externally.
- All examples must use clearly labeled placeholder values: `<placeholder>`, `example-value`, `your-resource-name`
- Real credentials and identifiers belong in:
  - Secure stores (Key Vault, AWS Secrets Manager, GCP Secret Manager)
  - Local `terraform.tfvars` files (gitignored)
  - GitHub repository secrets
  - Environment variables (documented but not hardcoded)

## Further Assistance
- If Copilot suggests ambiguous changes, prompt it to reference README.md, CONTRIBUTING.md, PERFORMANCE_IMPROVEMENTS.md, SECURITY.md, or relevant deployment README files for authoritative guidance.
- Re-run Copilot with narrower scope if suggestions span multiple clouds or violate modular boundaries.
