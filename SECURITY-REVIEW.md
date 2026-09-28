# Security Review Findings

Review date: 2026-09-28

This document records confirmed security findings from a read-only review of
application code, dependencies, CI/CD workflows, container configuration, and
infrastructure definitions. It intentionally uses generic identifiers because
this repository is public.

## Confirmed Vulnerabilities

| Priority | Severity | Area | Finding |
| --- | --- | --- | --- |
| 1 | High | Azure CI/CD | Pull request code can obtain an Azure identity with subscription-wide Contributor access. |
| 2 | High | Azure CI/CD | A manual workflow input is interpolated into a privileged shell command, allowing command injection. |
| 3 | High | GCP CI/CD | Workload Identity does not enforce the configured allowed branch restrictions. |
| 4 | Medium | AWS CI/CD | The OIDC read role can be assumed from every repository branch and tag. |

### 1. Azure pull-request identity has subscription Contributor access

The pull-request workflow authenticates to Azure before running code checked out
from the pull request. Its trusted identity accepts pull-request tokens and has
Contributor access at subscription scope. A contributor who can create a branch
and pull request could alter Terraform or workflow logic to use those
credentials to administer Azure resources.

**Remediation:** Use a separate, narrowly scoped read-only identity for pull
request validation. Restrict write-capable deployments to a protected branch
and approved deployment environment. Do not grant subscription-wide Contributor
to a pull-request identity.

### 2. Azure workflow input permits shell injection

The manual workflow accepts a free-form Terraform directory and substitutes it
directly into a Bash command after Azure authentication. A user allowed to
dispatch the workflow could provide shell syntax that executes arbitrary commands
using the authenticated Azure session.

**Remediation:** Replace the free-form input with an allowlisted choice of known
Terraform directories. Validate any supplied value against the same strict
allowlist before use, and avoid expression interpolation in shell source.

### 3. GCP Workload Identity does not enforce branch restrictions

The configuration exposes an allowed-branches setting, but the Workload Identity
provider condition checks only the repository claim. It does not map or evaluate
the GitHub ref claim. An unprotected branch can therefore impersonate the CI
service account and use its configured cloud permissions.

**Remediation:** Map `assertion.ref` and require approved branch refs in the
provider condition. Separate a restricted pull-request identity from a
write-capable deployment identity limited to protected branches or an approved
deployment environment.

### 4. AWS OIDC read role is available from all branches and tags

The AWS trust policy permits all repository branches and tags to assume a role
with broad read-only account permissions. Any contributor able to push a branch
can use a workflow to discover cloud resources and potentially read data exposed
by service read APIs.

**Remediation:** Restrict the trust policy to protected branches or deployment
environments and replace broad managed read access with the minimum required
inline permissions.

## Hardening Recommendations

- Prevent creation of GCP service-account keys unless explicitly requested; use
  Workload Identity instead.
- Enable GCP organization-policy protections by default after a controlled
  rollout.
- Require explicit opt-in for Azure Key Vault administrative and deployment
  features.
- Do not run `terraform init -upgrade` in privileged CI; update providers in a
  separate reviewed change.

## Scope Notes

No confirmed application-level injection, authentication, hardcoded secret,
unpinned GitHub Action, publicly open inbound network rule, vulnerable
dependency, or container-definition finding was established from repository
evidence.
