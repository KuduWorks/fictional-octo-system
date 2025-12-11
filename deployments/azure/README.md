## Azure Deployments

Short, practical Azure Infrastructure-as-Code for app registration, Key Vault, VM automation, policies, reporting, and reusable modules — concise and usable.

Quick links
- [app-registration/](app-registration/) — Azure AD app registration automation
- [key-vault/](key-vault/) — Key Vault with RBAC
- [vm-automation/](vm-automation/) — VM deployment with Bastion and automation
- [policies/](policies/) — Policy templates and enforcement guidance
- [reporting/](reporting/) — export scripts and reports
- [modules/](modules/) — reusable Terraform modules (naming convention, etc.)

Quick Start
1. Pick a subfolder above and review its README.
2. Copy `terraform.tfvars.example` to `terraform.tfvars` and edit values.
3. Run:
```bash
terraform init
terraform plan
terraform apply
```

Owner & contact
- Owner: Infra Team — infra@example.com
- Open an issue or PR for questions or improvements.

Notes
- Keep changes small and well-documented; follow `CONTRIBUTING.md`.
- This README is intentionally brief — details live in the subfolders.
