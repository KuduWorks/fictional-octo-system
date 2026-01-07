# AWS IAM Identity Center (sso-entra-id)

Purpose: document how to pair AWS IAM Identity Center with Entra ID as the identity provider so users can SSO into AWS (console and CLI) using their Entra ID credentials. This is a public repo—use placeholders (e.g., `<your-tenant>`, `<your-sso-portal>`, `<your-account-id>`) and store secrets only in secure locations.

## What’s here
- [DEPLOYMENT_STEPS.md](DEPLOYMENT_STEPS.md): step-by-step enablement of IAM Identity Center with Entra ID, SAML + SCIM wiring, permission sets, CLI SSO usage, rollback, validation, and cost reminders.

## Contributions
- Keep examples generic; never commit real tenant IDs, account IDs, or secrets.
- If adding Terraform examples, follow the repo pattern: `variables.tf`, `terraform.tfvars.example`, and add `.gitignore` entries for state and secrets.
- For new guides, link them from this docs README and the parent IAM README.
