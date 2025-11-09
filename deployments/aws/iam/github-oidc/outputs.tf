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
  value = <<-EOT
    # Add this to your .github/workflows/deploy.yml
    
    name: Deploy to AWS
    on:
      push:
        branches: [main, develop]
    
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
              role-to-assume: ${try(aws_iam_role.github_deploy[0].arn, "<REPLACE_WITH_YOUR_DEPLOY_ROLE_ARN>")}
              # If you did not create the deploy role, replace <REPLACE_WITH_YOUR_DEPLOY_ROLE_ARN> with your actual role ARN or remove this line.
              aws-region: ${var.aws_region}
          
          - name: Verify AWS Identity
            run: aws sts get-caller-identity
          
          - name: Deploy with Terraform
            run: |
              cd terraform
              terraform init
              terraform plan
              terraform apply -auto-approve
  EOT
}
