# Terraform Backend Configuration
# Stores state in S3 with DynamoDB locking

terraform {
  backend "s3" {
    # S3 bucket created by terraform-state-bootstrap module
    # AWS Account ID: 494367313227
    bucket = "fictional-octo-system-tfstate-494367313227"
    
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
