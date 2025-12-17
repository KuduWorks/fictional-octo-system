# Terraform State Access (OIDC, UAMI)

## Default: Azure AD/OIDC

- Backend uses `use_azuread_auth = true` in [backend.tf](./backend.tf).
- Run locally with `az login`; run in GitHub Actions with `azure/login@v2` + UAMI federated credential (`repo:KuduWorks/fictional-octo-system:ref:refs/heads/main`).
- Required roles on state storage: `Storage Blob Data Contributor` (or Blob Data Owner if you hit lease issues).
- Required role for deployments: `Contributor` on the subscription (production only).

### Init commands
```bash
terraform init \
  -backend-config="use_azuread_auth=true"

terraform plan
terraform apply
```

## Public Repo Safeguards

- No cloud credentials for pull_request workflows; PRs run fmt/validate only.
- Deployments run only on `push` to `main`, gated by GitHub environment `production` with required manual approval.
- Protect `main` branch with required review + status checks.

## Legacy IP Scripts

- Dynamic IP wrappers are archived under `terraform/archive/dynamic-ip/` and no longer used.
- Storage access defaults to deny; prefer `storage_access_method = "managed_identity"` or private endpoints.

## Rollback (temporary shared key)

Use only if OIDC is broken and you must unblock.

1) Re-enable keys
```bash
az storage account update \
  --name tfstateprod20251215 \
  --resource-group rg-tfstate \
  --allow-shared-key-access true
```

2) Fetch key and re-init (temporary)
```bash
ACCESS_KEY=$(az storage account keys list \
  --name tfstateprod20251215 \
  --resource-group rg-tfstate \
  --query '[0].value' -o tsv)

terraform init -reconfigure \
  -backend-config="access_key=${ACCESS_KEY}" \
  -backend-config="use_azuread_auth=false"
```

3) Fix OIDC, then revert to AAD
```bash
terraform init -reconfigure \
  -backend-config="use_azuread_auth=true"

az storage account update \
  --name tfstateprod20251215 \
  --resource-group rg-tfstate \
  --allow-shared-key-access false
```

4) Rotate keys after rollback window (even though they will be disabled again).

## Notes

- Do not run apply from forks or PRs.
- Keep federated credential subject scoped to `repo:KuduWorks/fictional-octo-system:ref:refs/heads/main` (prod only).
- When a dev tenant is added later, create a separate UAMI and subject for that branch/environment.
