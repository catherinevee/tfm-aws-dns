# Simple DNS Records Example
# This example demonstrates basic DNS record types (A, CNAME, MX, TXT)

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

# Create a public DNS zone with basic records
module "simple_dns_records" {
  source = "../../"

  # Required
  domain_name         = var.domain_name
  public_zone_enabled = true

  # Basic DNS records
  public_records = {
    # Root domain A record (points to web server)
    root = {
      name    = ""
      type    = "A"
      ttl     = 300
      records = [var.web_server_ip]
    }

    # WWW subdomain (points to same web server)
    www = {
      name    = "www"
      type    = "A"
      ttl     = 300
      records = [var.web_server_ip]
    }

    # API subdomain
    api = {
      name    = "api"
      type    = "A"
      ttl     = 300
      records = [var.api_server_ip]
    }

    # CNAME for blog (points to external service)
    blog = {
      name    = "blog"
      type    = "CNAME"
      ttl     = 300
      records = ["myblog.wordpress.com"]
    }

    # Mail exchange record
    mail = {
      name    = ""
      type    = "MX"
      ttl     = 300
      records = [
        "10 mail.${var.domain_name}",
        "20 mail2.${var.domain_name}"
      ]
    }

    # Mail server A record
    mail_server = {
      name    = "mail"
      type    = "A"
      ttl     = 300
      records = [var.mail_server_ip]
    }

    # Backup mail server A record
    mail_server_backup = {
      name    = "mail2"
      type    = "A"
      ttl     = 300
      records = [var.mail_server_backup_ip]
    }

    # SPF record for email security
    spf = {
      name    = ""
      type    = "TXT"
      ttl     = 300
      records = ["v=spf1 mx include:_spf.google.com ~all"]
    }

    # Domain verification TXT record
    verification = {
      name    = ""
      type    = "TXT"
      ttl     = 300
      records = ["google-site-verification=your-verification-code"]
    }

    # DMARC record for email security
    dmarc = {
      name    = "_dmarc"
      type    = "TXT"
      ttl     = 300
      records = ["v=DMARC1; p=quarantine; rua=mailto:dmarc@${var.domain_name}"]
    }
  }

  # Tags
  tags = {
    Name        = "Simple DNS Records"
    Environment = "example"
    Purpose     = "Basic DNS configuration demonstration"
  }
}
