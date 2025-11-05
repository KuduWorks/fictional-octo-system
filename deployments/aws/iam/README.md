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
