# Hybrid DNS with Route 53 Resolver Example
# This example demonstrates hybrid DNS setup for on-premises integration

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

# Data sources for existing resources
data "aws_vpc" "main" {
  id = var.vpc_id
}

data "aws_subnets" "resolver" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "tag:Name"
    values = var.resolver_subnet_names
  }
}

# Security group for resolver endpoints
resource "aws_security_group" "resolver" {
  name_prefix = "dns-resolver-"
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
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = var.on_premises_cidr_blocks
    description = "DNS TCP to on-premises"
  }

  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = var.on_premises_cidr_blocks
    description = "DNS UDP to on-premises"
  }

  tags = {
    Name        = "dns-resolver-sg"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

module "hybrid_dns" {
  source = "../../"

  # Public zone for external domains
  domain_name         = var.public_domain_name
  public_zone_enabled = true

  public_records = {
    # Public website
    www = {
      name    = "www"
      type    = "A"
      ttl     = 300
      records = [var.public_website_ip]
    }

    # Mail server
    mail = {
      name    = ""
      type    = "MX"
      ttl     = 300
      records = ["10 mail.${var.public_domain_name}"]
    }
  }

  # Private zone for internal resources
  private_zone_enabled = true
  private_domain_name  = var.private_domain_name
  vpc_id               = var.vpc_id
  vpc_region           = var.aws_region

  private_records = {
    # Internal services
    api = {
      name    = "api"
      type    = "A"
      ttl     = 300
      records = ["10.0.1.100"]
    }

    database = {
      name    = "db"
      type    = "A"
      ttl     = 300
      records = ["10.0.2.50"]
    }
  }

  # Resolver endpoints for hybrid connectivity
  resolver_inbound_enabled  = var.enable_inbound_resolver
  resolver_outbound_enabled = var.enable_outbound_resolver

  resolver_inbound_name  = "corporate-inbound-resolver"
  resolver_outbound_name = "corporate-outbound-resolver"

  resolver_security_group_ids = [aws_security_group.resolver.id]

  # Inbound resolver IP addresses (for on-premises to query AWS)
  resolver_inbound_ip_addresses = var.enable_inbound_resolver ? [
    for i, subnet_id in slice(data.aws_subnets.resolver.ids, 0, min(2, length(data.aws_subnets.resolver.ids))) : {
      subnet_id = subnet_id
      ip        = var.inbound_resolver_ips != null ? var.inbound_resolver_ips[i] : null
    }
  ] : []

  # Outbound resolver IP addresses (for AWS to query on-premises)
  resolver_outbound_ip_addresses = var.enable_outbound_resolver ? [
    for i, subnet_id in slice(data.aws_subnets.resolver.ids, 0, min(2, length(data.aws_subnets.resolver.ids))) : {
      subnet_id = subnet_id
      ip        = var.outbound_resolver_ips != null ? var.outbound_resolver_ips[i] : null
    }
  ] : []

  # Resolver rules for forwarding to on-premises
  resolver_rules = var.enable_outbound_resolver ? {
    corporate = {
      domain_name = var.on_premises_domain
      name        = "corporate-forward-rule"
      rule_type   = "FORWARD"
      target_ips  = var.on_premises_dns_servers
    }

    # Additional domain forwarding if specified
    additional = var.additional_forward_domain != null ? {
      domain_name = var.additional_forward_domain
      name        = "additional-forward-rule"
      rule_type   = "FORWARD"
      target_ips  = var.on_premises_dns_servers
    } : null
  } : {}

  # Associate resolver rules with VPC
  resolver_rule_associations = var.enable_outbound_resolver ? {
    main_vpc = {
      rule_key = "corporate"
      vpc_id   = var.vpc_id
    }

    additional_vpc = var.additional_forward_domain != null ? {
      rule_key = "additional"
      vpc_id   = var.vpc_id
    } : null
  } : {}

  tags = {
    Environment = var.environment
    Project     = "hybrid-dns-infrastructure"
    ManagedBy   = "terraform"
    Type        = "hybrid"
  }
}
