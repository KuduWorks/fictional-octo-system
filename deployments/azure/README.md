## Azure Deployments 💠

This folder contains Azure Terraform modules and quick links. It's short on ceremony and long on links.

Quick Links
- `deployments/azure/app-registration/` — app registration examples and helper scripts
- `deployments/azure/key-vault/` — Key Vault patterns
- `deployments/azure/modules/` — shared module patterns

Quick Start
1. Login: `az login`
2. Set subscription: `az account set -s YOUR_SUBSCRIPTION_ID`
3. Bootstrap storage for state (see `terraform/` at repo root)

Owner
- Maintainer: Cloud Platform Team

Notes
- We favour Managed Identities and Key Vault-backed keys for encryption.
- Want a VNet example? Check `deployments/azure/modules/naming-convention` and the `vnet` examples in the `terraform/` folder.

If you want more jokes in README files, open a PR — I'm a big fan of puns. 😄

## Azure Deployments 🔵

Short, practical Azure IaC for app registration, Key Vault, VM automation, policies, reporting, and reusable modules — concise, slightly witty, and actually useful.

Quick links
- [app-registration/](app-registration/) — Azure AD app registration automation (secrets rotate themselves, mostly)
- [key-vault/](key-vault/) — Key Vault with RBAC (your secrets' safe room)
- [vm-automation/](vm-automation/) — VM deployment with Bastion and automation (no public SSH circus)
- [policies/](policies/) — Policy templates and enforcement guidance (ISO-friendly)
- [reporting/](reporting/) — export scripts and reports (for the auditors and curious humans)
- [modules/](modules/) — reusable Terraform modules (naming convention, etc.)

Quick Start
1. Pick a subfolder above and read its README — that's where the real instructions live.
2. Copy `terraform.tfvars.example` → `terraform.tfvars` and update values (don’t commit secrets).
3. Run the usual magic:
```bash
terraform init
terraform plan
terraform apply
```

Owner & contact
- Owner: Infra Team — infra@example.com (or just shout in Slack; we pretend to be surprised)
- Open an issue or PR for questions or improvements.

Notes
- Keep changes small and well-documented; follow `CONTRIBUTING.md`.
- This file is a primer — details and recipes live in the subfolders. Treat this as the table of contents with jokes.
