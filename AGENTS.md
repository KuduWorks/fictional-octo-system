# Copilot Agent Guide

This document helps align GitHub Copilot with repository standards, security expectations, and preferred workflows. Use it as reference before prompting Copilot so generated changes match project practices.

## Purpose and Scope
- Apply these guidelines when asking Copilot to generate code, infrastructure, documentation, or automation for this repository.
- Keep prompts concise and reference relevant folders (deployments/aws, deployments/azure, deployments/gcp, terraform) so Copilot scopes changes correctly.
- Favor modular, reviewable pull requests that follow contribution expectations from CONTRIBUTING.md.

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
- Direct Copilot to mask or omit environment-specific secrets, subscription IDs, or account numbers in generated examples.
- When creating diagnostics or logs, include instructions to sanitize outputs before sharing externally.
- Encourage prompts that request sample data only, clearly labeled as placeholder values, and reiterate that real credentials belong in secure stores.

## Further Assistance
- If Copilot suggests ambiguous changes, prompt it to reference README.md, CONTRIBUTING.md, PERFORMANCE_IMPROVEMENTS.md, SECURITY.md, or relevant deployment README files for authoritative guidance.
- Re-run Copilot with narrower scope if suggestions span multiple clouds or violate modular boundaries.
