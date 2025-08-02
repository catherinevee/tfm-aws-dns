# Alias Records Example
# This example demonstrates Route 53 alias records for AWS resources

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

# Data sources for AWS resources (examples)
data "aws_lb" "example" {
  count = var.load_balancer_name != null ? 1 : 0
  name  = var.load_balancer_name
}

data "aws_cloudfront_distribution" "example" {
  count = var.cloudfront_distribution_id != null ? 1 : 0
  id    = var.cloudfront_distribution_id
}

# Create a public DNS zone with alias records
module "alias_dns_records" {
  source = "../../"

  # Required
  domain_name         = var.domain_name
  public_zone_enabled = true

  # Alias records for AWS resources
  public_alias_records = {
    # Root domain alias to load balancer
    root_lb = var.load_balancer_name != null ? {
      name                   = ""
      type                   = "A"
      alias_name             = data.aws_lb.example[0].dns_name
      alias_zone_id          = data.aws_lb.example[0].zone_id
      evaluate_target_health = true
    } : null

    # WWW alias to load balancer
    www_lb = var.load_balancer_name != null ? {
      name                   = "www"
      type                   = "A"
      alias_name             = data.aws_lb.example[0].dns_name
      alias_zone_id          = data.aws_lb.example[0].zone_id
      evaluate_target_health = true
    } : null

    # CDN alias to CloudFront distribution
    cdn = var.cloudfront_distribution_id != null ? {
      name                   = "cdn"
      type                   = "A"
      alias_name             = data.aws_cloudfront_distribution.example[0].domain_name
      alias_zone_id          = data.aws_cloudfront_distribution.example[0].hosted_zone_id
      evaluate_target_health = false
    } : null

    # Static content alias to CloudFront
    static = var.cloudfront_distribution_id != null ? {
      name                   = "static"
      type                   = "A"
      alias_name             = data.aws_cloudfront_distribution.example[0].domain_name
      alias_zone_id          = data.aws_cloudfront_distribution.example[0].hosted_zone_id
      evaluate_target_health = false
    } : null

    # API Gateway alias (example configuration)
    api = var.api_gateway_domain != null ? {
      name                   = "api"
      type                   = "A"
      alias_name             = var.api_gateway_domain
      alias_zone_id          = var.api_gateway_zone_id
      evaluate_target_health = true
    } : null
  }

  # Regular records for non-AWS resources
  public_records = {
    # CNAME for external services
    blog = {
      name    = "blog"
      type    = "CNAME"
      ttl     = 300
      records = ["myblog.medium.com"]
    }

    # A record for non-AWS server
    legacy = {
      name    = "legacy"
      type    = "A"
      ttl     = 300
      records = [var.legacy_server_ip]
    }

    # TXT record for domain verification
    verification = {
      name    = ""
      type    = "TXT"
      ttl     = 300
      records = ["google-site-verification=your-verification-code"]
    }
  }

  # Tags
  tags = {
    Name        = "Alias DNS Records"
    Environment = "example"
    Purpose     = "AWS resource alias demonstration"
  }
}
