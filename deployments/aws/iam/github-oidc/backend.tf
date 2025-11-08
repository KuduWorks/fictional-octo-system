# Terraform Backend Configuration
# Stores state in S3 with DynamoDB locking

terraform {
  backend "s3" {
    # S3 bucket created by terraform-state-bootstrap module
    # IMPORTANT: Do NOT hardcode the bucket name with a placeholder.
    # Supply the actual bucket name and other backend config via -backend-config flags during terraform init.
    # Example:
    # terraform init \
    #   -backend-config="bucket=fictional-octo-system-tfstate-123456789012" \
    #   -backend-config="key=aws/iam/github-oidc/terraform.tfstate" \
    #   -backend-config="region=eu-north-1" \
    #   -backend-config="encrypt=true" \
    #   -backend-config="dynamodb_table=terraform-state-locks"
  }
}
