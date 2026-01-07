# AWS IAM Configurations

This directory contains IAM roles, policies, and identity federation configurations that mirror the Azure app-registration setup.

## Modules

### github-oidc/
Mirrors `azure/app-registration/` for GitHub Actions

Sets up:
- OIDC provider for GitHub Actions
- IAM roles for CI/CD workflows
- Trust policies for repository access
- Example workflows for deployment

### service-roles/
Cross-service IAM roles for:
- Lambda execution roles
- ECS task roles
- EC2 instance profiles
- Cross-account access roles

## Azure vs AWS Identity

| Azure | AWS |
|-------|-----|
| App Registration | IAM Role + OIDC Provider |
| Service Principal | IAM Role |
| Managed Identity | Instance Profile / ECS Task Role |
| Client Secret | IAM Access Keys (avoid) / OIDC |

## Best Practices

- Use OIDC federation instead of long-lived credentials
- Apply least-privilege principle
- Use IAM roles for service-to-service auth
- Enable CloudTrail for IAM audit logging

## Deployment steps

- See [deployments/aws/iam/docs/DEPLOYMENT_STEPS.md](deployments/aws/iam/docs/DEPLOYMENT_STEPS.md) for the end-to-end guide to enable IAM Identity Center with Entra ID, SCIM, permission sets, CLI SSO, rollback, and validation. The docs index is in [deployments/aws/iam/docs/README.md](deployments/aws/iam/docs/README.md).

## IAM Identity Center pricing

- IAM Identity Center itself is offered at no additional cost in supported regions; check the latest details on the AWS IAM Identity Center pricing page.
- Costs typically come from downstream services: AWS STS calls (billed per 10k requests), optional CloudTrail/CloudWatch/S3 logging and storage, AWS Config evaluations, and standard data transfer.
- CLI SSO (`aws configure sso`) does not add fees beyond the STS and logging costs above.
- Pricing is region-specific; confirm current rates for your chosen home region and any regions where workloads run.

## Downtime and rollback

- Enabling IAM Identity Center is additive: existing IAM users/roles/keys and their console/CLI access remain unchanged.
- If external IdP (for example, Entra ID) SAML/SCIM integration is misconfigured, use a break-glass IAM admin in the management account to adjust or roll back the identity source in IAM Identity Center settings.
- Switching identity sources (built-in directory ↔ external IdP) is near-immediate but you must re-establish user/group assignments to permission sets that match the active identity source.
- SCIM provisioning and permission set assignments can take a few minutes to propagate; users may need to re-run `aws configure sso` to refresh cached tokens after changes.
