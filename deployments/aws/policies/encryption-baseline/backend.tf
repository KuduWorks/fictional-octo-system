terraform {
  backend "s3" {
    bucket         = "fictional-octo-system-tfstate-494367313227"
    key            = "aws/policies/encryption-baseline/terraform.tfstate"
    region         = "eu-north-1"  # Stockholm - closest to Finland
    encrypt        = true
    dynamodb_table = "terraform-state-locks"
  }
}
