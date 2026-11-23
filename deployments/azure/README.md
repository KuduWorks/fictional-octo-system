## Azure Deployments 🔵

Short, practical Azure IaC for app registration, Key Vault, VM automation, policies, reporting, and reusable modules — concise, slightly witty, and actually useful.

Quick links
- [agent-identity/](agent-identity/) — Entra Agent ID: App Regs, Blueprints, and why you don't hand blank logbooks to AI agents
- [app-registration/](app-registration/) — Azure AD app registration automation (secrets rotate themselves, mostly)
- [key-vault/](key-vault/) — Key Vault with RBAC (your secrets' safe room)
- [vm-automation/](vm-automation/) — VM deployment with Bastion and automation (no public SSH circus)
- [policies/](policies/) — Policy templates and enforcement guidance (ISO-friendly)
- [reporting/](reporting/) — export scripts and reports (for the auditors and curious humans)
- [modules/](modules/) — reusable Terraform modules (naming convention, etc.)
- [branding/](branding/) — Entra sign-in branding (partial layout, assets, CSS, terms)

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
