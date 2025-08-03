# Terraform and Provider Version Constraints

terraform {
  required_version = "~> 1.13.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.2.0"
    }
  }

  # Backend configuration for remote state management
  # Uncomment and configure for production use
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "dns/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}
