# Subdomain Delegation Example
# This example demonstrates how to delegate subdomains to other DNS zones

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

# Create the main domain zone
module "main_domain" {
  source = "../../"

  # Main domain
  domain_name         = var.domain_name
  public_zone_enabled = true

  # Main domain records
  public_records = {
    # Root domain A record
    root = {
      name    = ""
      type    = "A"
      ttl     = 300
      records = [var.main_server_ip]
    }

    # WWW subdomain
    www = {
      name    = "www"
      type    = "A"
      ttl     = 300
      records = [var.main_server_ip]
    }

    # Subdomain delegation - API subdomain
    api_ns = {
      name    = "api"
      type    = "NS"
      ttl     = 300
      records = var.api_subdomain_nameservers
    }

    # Subdomain delegation - Blog subdomain
    blog_ns = {
      name    = "blog"
      type    = "NS"
      ttl     = 300
      records = var.blog_subdomain_nameservers
    }

    # Subdomain delegation - Staging environment
    staging_ns = {
      name    = "staging"
      type    = "NS"
      ttl     = 300
      records = var.staging_subdomain_nameservers
    }

    # Subdomain delegation - Development environment
    dev_ns = {
      name    = "dev"
      type    = "NS"
      ttl     = 300
      records = var.dev_subdomain_nameservers
    }

    # Regular records for non-delegated subdomains
    mail = {
      name    = "mail"
      type    = "A"
      ttl     = 300
      records = [var.mail_server_ip]
    }

    # MX record for main domain
    mx = {
      name    = ""
      type    = "MX"
      ttl     = 300
      records = ["10 mail.${var.domain_name}"]
    }

    # SPF record
    spf = {
      name    = ""
      type    = "TXT"
      ttl     = 300
      records = ["v=spf1 mx a:mail.${var.domain_name} ~all"]
    }

    # DMARC record
    dmarc = {
      name    = "_dmarc"
      type    = "TXT"
      ttl     = 300
      records = ["v=DMARC1; p=quarantine; rua=mailto:dmarc@${var.domain_name}"]
    }
  }

  # Tags
  tags = {
    Name        = "Main Domain Zone"
    Environment = "production"
    Purpose     = "Main domain with subdomain delegation"
  }
}

# Optional: Create subdomain zones (if managing them in same Terraform)
module "api_subdomain" {
  count  = var.create_api_subdomain ? 1 : 0
  source = "../../"

  # API subdomain zone
  domain_name         = "api.${var.domain_name}"
  public_zone_enabled = true

  # API subdomain records
  public_records = {
    # API root
    root = {
      name    = ""
      type    = "A"
      ttl     = 300
      records = [var.api_server_ip]
    }

    # API versions
    v1 = {
      name    = "v1"
      type    = "A"
      ttl     = 300
      records = [var.api_v1_server_ip]
    }

    v2 = {
      name    = "v2"
      type    = "A"
      ttl     = 300
      records = [var.api_v2_server_ip]
    }

    # API documentation
    docs = {
      name    = "docs"
      type    = "CNAME"
      ttl     = 300
      records = ["api-docs.external-service.com"]
    }
  }

  tags = {
    Name        = "API Subdomain Zone"
    Environment = "production"
    Purpose     = "API services subdomain"
  }
}

module "staging_subdomain" {
  count  = var.create_staging_subdomain ? 1 : 0
  source = "../../"

  # Staging subdomain zone
  domain_name         = "staging.${var.domain_name}"
  public_zone_enabled = true

  # Staging subdomain records
  public_records = {
    # Staging root
    root = {
      name    = ""
      type    = "A"
      ttl     = 300
      records = [var.staging_server_ip]
    }

    # Staging API
    api = {
      name    = "api"
      type    = "A"
      ttl     = 300
      records = [var.staging_api_server_ip]
    }

    # Staging database
    db = {
      name    = "db"
      type    = "A"
      ttl     = 300
      records = [var.staging_db_server_ip]
    }
  }

  tags = {
    Name        = "Staging Subdomain Zone"
    Environment = "staging"
    Purpose     = "Staging environment subdomain"
  }
}
