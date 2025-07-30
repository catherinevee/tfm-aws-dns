# Basic Public DNS Example
# This example demonstrates a simple public hosted zone with basic DNS records

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

module "public_dns" {
  source = "../../"

  domain_name         = var.domain_name
  public_zone_enabled = true

  public_records = {
    # Root domain A record
    root = {
      name    = ""
      type    = "A"
      ttl     = 300
      records = ["192.0.2.1"]
    }

    # WWW subdomain
    www = {
      name    = "www"
      type    = "A"
      ttl     = 300
      records = ["192.0.2.1"]
    }

    # Mail exchange record
    mail = {
      name    = ""
      type    = "MX"
      ttl     = 300
      records = ["10 mail.${var.domain_name}"]
    }

    # Text record for domain verification
    txt_verification = {
      name    = ""
      type    = "TXT"
      ttl     = 300
      records = ["v=spf1 include:_spf.google.com ~all"]
    }

    # CNAME for mail subdomain
    mail_cname = {
      name    = "mail"
      type    = "CNAME"
      ttl     = 300
      records = ["ghs.googlehosted.com"]
    }
  }

  tags = {
    Environment = "production"
    Project     = "basic-public-dns"
    ManagedBy   = "terraform"
  }
}
