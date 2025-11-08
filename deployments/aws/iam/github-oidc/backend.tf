# Terraform Backend Configuration
# Stores state in S3 with DynamoDB locking

terraform {
  backend "s3" {
    # S3 bucket created by terraform-state-bootstrap module
    # AWS Account ID replaced with placeholder for security
    bucket = "fictional-octo-system-tfstate-<AWS_ACCOUNT_ID>"
    
    # Path within the bucket where this module's state is stored
    key = "aws/iam/github-oidc/terraform.tfstate"
    
    # Region where the S3 bucket was created
    region = "eu-north-1"
    
    # Enable encryption at rest
    encrypt = true
    
    # DynamoDB table for state locking
    dynamodb_table = "terraform-state-locks"
  }
}
