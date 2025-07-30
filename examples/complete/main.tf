# Complete DNS Example with All Features
# This example demonstrates all DNS module features including health checks,
# advanced routing policies, and comprehensive monitoring

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

# Data sources
data "aws_vpc" "main" {
  id = var.vpc_id
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "tag:Type"
    values = ["private"]
  }
}

# Security group for resolver endpoints
resource "aws_security_group" "resolver" {
  name_prefix = "complete-dns-resolver-"
  vpc_id      = var.vpc_id
  description = "Security group for Route 53 Resolver endpoints"

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
    description = "DNS TCP from VPC"
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
    description = "DNS UDP from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name        = "complete-dns-resolver-sg"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# CloudWatch Log Group for health check logging
resource "aws_cloudwatch_log_group" "health_checks" {
  name              = "/aws/route53/healthchecks"
  retention_in_days = 30

  tags = {
    Environment = var.environment
    Purpose     = "dns-health-checks"
    ManagedBy   = "terraform"
  }
}

module "complete_dns" {
  source = "../../"

  # Domain Configuration
  domain_name         = var.domain_name
  public_zone_enabled = true

  # Advanced public DNS records with routing policies
  public_records = {
    # Primary website with failover
    www_primary = {
      name            = "www"
      type            = "A"
      ttl             = 60
      records         = [var.primary_website_ip]
      set_identifier  = "primary"
      health_check_id = "primary"
      failover_routing_policy = {
        type = "PRIMARY"
      }
    }

    www_secondary = {
      name           = "www"
      type           = "A"
      ttl            = 60
      records        = [var.secondary_website_ip]
      set_identifier = "secondary"
      failover_routing_policy = {
        type = "SECONDARY"
      }
    }

    # Weighted routing for API endpoints
    api_us_east = {
      name            = "api"
      type            = "A"
      ttl             = 300
      records         = [var.api_us_east_ip]
      set_identifier  = "us-east-1"
      health_check_id = "api_us_east"
      weighted_routing_policy = {
        weight = 70
      }
    }

    api_us_west = {
      name            = "api"
      type            = "A"
      ttl             = 300
      records         = [var.api_us_west_ip]
      set_identifier  = "us-west-2"
      health_check_id = "api_us_west"
      weighted_routing_policy = {
        weight = 30
      }
    }

    # Geolocation routing for CDN
    cdn_us = {
      name           = "cdn"
      type           = "CNAME"
      ttl            = 300
      records        = ["us.cdn.example.com"]
      set_identifier = "us"
      geolocation_routing_policy = {
        country = "US"
      }
    }

    cdn_eu = {
      name           = "cdn"
      type           = "CNAME"
      ttl            = 300
      records        = ["eu.cdn.example.com"]
      set_identifier = "eu"
      geolocation_routing_policy = {
        continent = "EU"
      }
    }

    cdn_default = {
      name           = "cdn"
      type           = "CNAME"
      ttl            = 300
      records        = ["global.cdn.example.com"]
      set_identifier = "default"
      geolocation_routing_policy = {
        country = "*"
      }
    }

    # Standard records
    root = {
      name    = ""
      type    = "A"
      ttl     = 300
      records = [var.primary_website_ip]
    }

    mail = {
      name    = ""
      type    = "MX"
      ttl     = 300
      records = ["10 mail.${var.domain_name}"]
    }

    txt_spf = {
      name    = ""
      type    = "TXT"
      ttl     = 300
      records = ["v=spf1 include:_spf.google.com ~all"]
    }

    txt_dmarc = {
      name    = "_dmarc"
      type    = "TXT"
      ttl     = 300
      records = ["v=DMARC1; p=quarantine; rua=mailto:dmarc@${var.domain_name}"]
    }
  }

  # Private DNS Configuration
  private_zone_enabled = true
  private_domain_name  = var.private_domain_name
  vpc_id               = var.vpc_id
  vpc_region           = var.aws_region

  private_records = {
    # Internal services
    api_internal = {
      name    = "api"
      type    = "A"
      ttl     = 300
      records = ["10.0.1.100", "10.0.1.101"]
    }

    database_primary = {
      name    = "db-primary"
      type    = "A"
      ttl     = 300
      records = ["10.0.2.50"]
    }

    database_replica = {
      name    = "db-replica"
      type    = "A"
      ttl     = 300
      records = ["10.0.2.51", "10.0.2.52"]
    }

    cache = {
      name    = "cache"
      type    = "A"
      ttl     = 60
      records = ["10.0.3.10", "10.0.3.11", "10.0.3.12"]
    }

    # Load balancer aliases
    app_lb = {
      name    = "app"
      type    = "CNAME"
      ttl     = 300
      records = ["internal-app-lb-123456789.us-east-1.elb.amazonaws.com"]
    }

    # Microservices
    auth_service = {
      name    = "auth"
      type    = "A"
      ttl     = 60
      records = ["10.0.4.20", "10.0.4.21"]
    }

    user_service = {
      name    = "users"
      type    = "A"
      ttl     = 60
      records = ["10.0.4.30", "10.0.4.31"]
    }

    notification_service = {
      name    = "notifications"
      type    = "A"
      ttl     = 60
      records = ["10.0.4.40"]
    }
  }

  # Hybrid DNS with Resolver
  resolver_inbound_enabled  = var.enable_hybrid_dns
  resolver_outbound_enabled = var.enable_hybrid_dns

  resolver_inbound_name  = "complete-inbound-resolver"
  resolver_outbound_name = "complete-outbound-resolver"

  resolver_security_group_ids = [aws_security_group.resolver.id]

  resolver_inbound_ip_addresses = var.enable_hybrid_dns ? [
    for i, subnet_id in slice(data.aws_subnets.private.ids, 0, min(2, length(data.aws_subnets.private.ids))) : {
      subnet_id = subnet_id
      ip        = null # Auto-assign
    }
  ] : []

  resolver_outbound_ip_addresses = var.enable_hybrid_dns ? [
    for i, subnet_id in slice(data.aws_subnets.private.ids, 0, min(2, length(data.aws_subnets.private.ids))) : {
      subnet_id = subnet_id
      ip        = null # Auto-assign
    }
  ] : []

  resolver_rules = var.enable_hybrid_dns ? {
    corporate = {
      domain_name = var.on_premises_domain
      name        = "corporate-forward-rule"
      rule_type   = "FORWARD"
      target_ips  = var.on_premises_dns_servers
    }
  } : {}

  resolver_rule_associations = var.enable_hybrid_dns ? {
    main_vpc = {
      rule_key = "corporate"
      vpc_id   = var.vpc_id
    }
  } : {}

  # Comprehensive Health Checks
  health_checks = {
    primary = {
      fqdn                            = "www.${var.domain_name}"
      port                            = 443
      type                            = "HTTPS"
      resource_path                   = "/health"
      failure_threshold               = 3
      request_interval                = 30
      cloudwatch_logs_region          = var.aws_region
      cloudwatch_logs_log_group_name  = aws_cloudwatch_log_group.health_checks.name
      insufficient_data_health_status = "Failure"
      invert_healthcheck              = false
      measure_latency                 = true
      enable_sni                      = true
    }

    api_us_east = {
      fqdn                           = var.api_us_east_ip
      port                           = 443
      type                           = "HTTPS"
      resource_path                  = "/api/health"
      failure_threshold              = 2
      request_interval               = 30
      cloudwatch_logs_region         = var.aws_region
      cloudwatch_logs_log_group_name = aws_cloudwatch_log_group.health_checks.name
      measure_latency                = true
      enable_sni                     = false
    }

    api_us_west = {
      fqdn                           = var.api_us_west_ip
      port                           = 443
      type                           = "HTTPS"
      resource_path                  = "/api/health"
      failure_threshold              = 2
      request_interval               = 30
      cloudwatch_logs_region         = var.aws_region
      cloudwatch_logs_log_group_name = aws_cloudwatch_log_group.health_checks.name
      measure_latency                = true
      enable_sni                     = false
    }
  }

  # Comprehensive Tagging
  tags = {
    Environment = var.environment
    Project     = "complete-dns-infrastructure"
    ManagedBy   = "terraform"
    Owner       = var.owner
    CostCenter  = var.cost_center
  }

  public_zone_tags = {
    Type = "public"
    Zone = "external"
  }

  private_zone_tags = {
    Type = "private"
    Zone = "internal"
  }

  resolver_tags = {
    Type = "resolver"
    Zone = "hybrid"
  }

  health_check_tags = {
    Type       = "health-check"
    Monitoring = "enabled"
    AlertLevel = "critical"
  }
}
