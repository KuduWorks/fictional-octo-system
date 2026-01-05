output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "readonly_role_arn" {
  description = "ARN of the read-only IAM role for GitHub Actions"
  value       = var.create_readonly_role ? aws_iam_role.github_readonly[0].arn : null
}

output "deploy_role_arn" {
  description = "ARN of the deployment IAM role for GitHub Actions"
  value       = var.create_deploy_role ? aws_iam_role.github_deploy[0].arn : null
}

output "admin_role_arn" {
  description = "ARN of the admin IAM role for GitHub Actions (main branch only)"
  value       = var.create_admin_role ? aws_iam_role.github_admin[0].arn : null
}

output "aws_account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "github_actions_workflow_example" {
  description = "Example GitHub Actions workflow configuration"
  value = "- name: Configure AWS Credentials\n  uses: aws-actions/configure-aws-credentials@v4\n  with:\n    role-to-assume: $${{ secrets.AWS_DEPLOY_ROLE_ARN }}\n    aws-region: us-east-1"
}
