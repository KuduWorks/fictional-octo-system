# Azure Resource Janitor Plan

## Status

Awaiting implementation approval.

## Objective

Create a safe, auditable Azure Resource Janitor showcase. The Janitor inventories stale or orphaned Azure resources, produces a reviewable candidate manifest, and performs cleanup only after an approved GitHub Actions workflow starts a separate Automation runbook.

## Scope

- Azure Automation Account with a system-assigned managed identity.
- Discovery-only PowerShell runbook for deallocated virtual machines, deallocated virtual machine scale set instances, unattached managed disks, unattached network interfaces, unassociated public IP addresses, snapshots/images, and empty resource groups.
- Configurable 30-day stale threshold and exclusion tags.
- Terraform configuration, example variables, and a public-safe README.
- GitHub Actions workflow skeleton for protected-environment approval before cleanup.

## Safety Boundaries

- Scheduled discovery performs no delete, stop, or deallocate operation.
- Resource state alone is insufficient to prove a VM/VMSS instance has been stopped for 30 days. Discovery marks candidates as ambiguous when Activity Log or lifecycle-tag evidence is unavailable.
- Future cleanup accepts an approved candidate manifest, revalidates live state and exclusion tags, and skips resources that changed since discovery.
- VM scale-set cleanup applies to approved stale instances only, never the scale set definition or autoscale configuration.
- Empty resource groups remain report-only until every contained resource has passed independent review.

## Identity and Access

- Runtime: system-assigned managed identity on Azure Automation.
- Deployment/control plane: GitHub Actions OIDC identity.
- Scope Azure RBAC to explicit target resource groups. Start discovery with `Reader`; add narrowly scoped cleanup roles only in the separately approved cleanup phase.
- Do not create, store, or use client secrets.

## Architecture

1. A scheduled Automation job authenticates with its managed identity.
2. The discovery runbook inventories resources and evaluates tags, configuration, and available activity evidence.
3. The job emits a JSON candidate report to its job output for operator review.
4. A GitHub workflow publishes the report and requires the `azure-janitor-cleanup` protected environment before any cleanup dispatch.
5. A future cleanup runbook consumes the approved manifest and revalidates every candidate before taking action.

## Implementation Tasks

1. Create `deployments/azure/agent-janitor` with Terraform provider configuration, variables, outputs, ignore rules, and public-safe variable example.
2. Provision an Azure Automation Account, system-assigned identity, a discovery runbook, and a daily discovery schedule.
3. Assign `Reader` at configured target resource-group scopes for discovery only.
4. Add `Find-StaleAzureResources.ps1` with strict mode, managed-identity authentication, tag exclusions, and report-only candidate classification.
5. Add a README explaining evidence limitations, prerequisite Az modules, the tag contract, and the approval model.
6. Add a GitHub Actions manual workflow skeleton that uses OIDC and a protected environment for future cleanup approval without executing deletion commands.
7. Validate Terraform formatting and configuration, then run PowerShell static analysis.

## Azure Context

- Subscription: supplied at deployment time through authenticated Azure CLI/OIDC context; never committed.
- Location: configurable Terraform variable, defaulting to `swedencentral` as used by nearby Azure examples.
- Target resource groups: explicit Terraform input; no subscription-wide cleanup by default.

## Validation Plan

1. `terraform fmt -check` and `terraform validate` for the new package.
2. PSScriptAnalyzer against the discovery runbook.
3. Test discovery against a non-production resource group containing intentionally created disposable resources.
4. Confirm output separates confirmed candidates, excluded resources, ambiguous-evidence resources, and non-candidates.
5. Confirm the scheduled path contains no destructive Azure PowerShell command.

## Deployment

No deployment is included in this implementation phase. After validation, Azure deployment requires a configured Azure context and explicit user authorization to provision resources.