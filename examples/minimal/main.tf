# Minimal DNS Zone Example
# This example creates the most basic public DNS zone possible

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

# Create a minimal public DNS zone
module "minimal_dns" {
  source = "../../"

  # Required parameter
  domain_name = "example.com"

  # Enable public zone (default)
  public_zone_enabled = true

  # All other parameters will use module defaults
  # No DNS records will be created - just the hosted zone
}
