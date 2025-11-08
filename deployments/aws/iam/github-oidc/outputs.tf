# Outputs for GitHub Actions OIDC Configuration
# These values are needed in your GitHub Actions workflows

output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "oidc_provider_url" {
  description = "URL of the GitHub OIDC provider"
  value       = aws_iam_openid_connect_provider.github.url
}

output "readonly_role_arn" {
  description = "ARN of the read-only IAM role for GitHub Actions (use this in workflows for read operations)"
  value       = var.create_readonly_role ? aws_iam_role.github_actions_readonly[0].arn : null
}

output "readonly_role_name" {
  description = "Name of the read-only IAM role"
  value       = var.create_readonly_role ? aws_iam_role.github_actions_readonly[0].name : null
}

output "deploy_role_arn" {
  description = "ARN of the deployment IAM role for GitHub Actions (use this in workflows for deployments)"
  value       = var.create_deploy_role ? aws_iam_role.github_actions_deploy[0].arn : null
}

output "deploy_role_name" {
  description = "Name of the deployment IAM role"
  value       = var.create_deploy_role ? aws_iam_role.github_actions_deploy[0].name : null
}

output "admin_role_arn" {
  description = "ARN of the admin IAM role for GitHub Actions (use with caution)"
  value       = var.create_admin_role ? aws_iam_role.github_actions_admin[0].arn : null
}

output "admin_role_name" {
  description = "Name of the admin IAM role"
  value       = var.create_admin_role ? aws_iam_role.github_actions_admin[0].name : null
}

output "aws_account_id" {
  description = "AWS Account ID where resources are created"
  value       = data.aws_caller_identity.current.account_id
}

output "github_actions_example" {
  description = "Example GitHub Actions workflow configuration"
  value       = <<-EOT
    # Add this to your GitHub Actions workflow:
    
    permissions:
      id-token: write
      contents: read
    
    jobs:
      deploy:
        runs-on: ubuntu-latest
        steps:
          - uses: actions/checkout@v4
          
          - name: Configure AWS Credentials
            uses: aws-actions/configure-aws-credentials@v4
            with:
              role-to-assume: ${var.create_deploy_role ? aws_iam_role.github_actions_deploy[0].arn : "arn:aws:iam::ACCOUNT_ID:role/github-actions-deploy"}
              aws-region: ${var.aws_region}
          
          - name: Verify AWS Identity
            run: aws sts get-caller-identity
  EOT
}
