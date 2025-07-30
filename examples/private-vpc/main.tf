# Private DNS with VPC Association Example
# This example demonstrates private hosted zones with VPC associations

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
  region = var.aws_region
}

# Data source for existing VPC
data "aws_vpc" "main" {
  id = var.vpc_id
}

module "private_dns" {
  source = "../../"

  domain_name          = var.private_domain_name
  public_zone_enabled  = false
  private_zone_enabled = true

  vpc_id     = var.vpc_id
  vpc_region = var.aws_region

  # Additional VPC associations if needed
  additional_vpc_associations = var.additional_vpc_ids != null ? [
    for vpc_id in var.additional_vpc_ids : {
      vpc_id     = vpc_id
      vpc_region = var.aws_region
    }
  ] : []

  private_records = {
    # Internal API endpoint
    api = {
      name    = "api"
      type    = "A"
      ttl     = 300
      records = ["10.0.1.100"]
    }

    # Database endpoint
    database = {
      name    = "db"
      type    = "A"
      ttl     = 300
      records = ["10.0.2.50"]
    }

    # Load balancer CNAME
    app = {
      name    = "app"
      type    = "CNAME"
      ttl     = 300
      records = ["internal-lb-123456789.us-east-1.elb.amazonaws.com"]
    }

    # Service discovery for microservices
    auth_service = {
      name    = "auth"
      type    = "A"
      ttl     = 60
      records = ["10.0.1.101", "10.0.1.102"]
    }

    user_service = {
      name    = "users"
      type    = "A"
      ttl     = 60
      records = ["10.0.1.103", "10.0.1.104"]
    }

    # Internal mail server
    mail = {
      name    = "mail"
      type    = "A"
      ttl     = 300
      records = ["10.0.3.10"]
    }

    # Monitoring and logging
    monitoring = {
      name    = "monitoring"
      type    = "A"
      ttl     = 300
      records = ["10.0.4.20"]
    }

    logs = {
      name    = "logs"
      type    = "A"
      ttl     = 300
      records = ["10.0.4.21"]
    }
  }

  tags = {
    Environment = var.environment
    Project     = "private-dns-infrastructure"
    ManagedBy   = "terraform"
    VPC         = data.aws_vpc.main.id
  }
}
