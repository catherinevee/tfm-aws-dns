# Simple Private DNS Zone Example
# This example demonstrates a basic private DNS zone for internal VPC resolution

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

# Data sources for VPC information
data "aws_vpc" "selected" {
  count = var.vpc_id != null ? 1 : 0
  id    = var.vpc_id
}

data "aws_vpc" "default" {
  count   = var.vpc_id == null ? 1 : 0
  default = true
}

locals {
  vpc_id = var.vpc_id != null ? data.aws_vpc.selected[0].id : data.aws_vpc.default[0].id
}

# Create a private DNS zone with internal records
module "private_dns" {
  source = "../../"

  # Required
  domain_name          = var.domain_name
  private_zone_enabled = true

  # VPC association
  private_zone_vpc_associations = [
    {
      vpc_id  = local.vpc_id
      comment = "Primary VPC association"
    }
  ]

  # Internal DNS records
  private_records = {
    # Database servers
    db_primary = {
      name    = "db-primary"
      type    = "A"
      ttl     = 300
      records = [var.db_primary_ip]
    }

    db_replica = {
      name    = "db-replica"
      type    = "A"
      ttl     = 300
      records = [var.db_replica_ip]
    }

    # Database cluster CNAME
    database = {
      name    = "database"
      type    = "CNAME"
      ttl     = 300
      records = ["db-primary.${var.domain_name}"]
    }

    # Application servers
    app_server_1 = {
      name    = "app-01"
      type    = "A"
      ttl     = 300
      records = [var.app_server_1_ip]
    }

    app_server_2 = {
      name    = "app-02"
      type    = "A"
      ttl     = 300
      records = [var.app_server_2_ip]
    }

    # Cache servers
    redis_primary = {
      name    = "redis-primary"
      type    = "A"
      ttl     = 300
      records = [var.redis_primary_ip]
    }

    redis_replica = {
      name    = "redis-replica"
      type    = "A"
      ttl     = 300
      records = [var.redis_replica_ip]
    }

    # Cache cluster CNAME
    cache = {
      name    = "cache"
      type    = "CNAME"
      ttl     = 300
      records = ["redis-primary.${var.domain_name}"]
    }

    # Internal load balancer
    internal_lb = {
      name    = "internal-lb"
      type    = "A"
      ttl     = 300
      records = [var.internal_lb_ip]
    }

    # API internal endpoint
    api_internal = {
      name    = "api-internal"
      type    = "CNAME"
      ttl     = 300
      records = ["internal-lb.${var.domain_name}"]
    }

    # Monitoring services
    monitoring = {
      name    = "monitoring"
      type    = "A"
      ttl     = 300
      records = [var.monitoring_server_ip]
    }

    # Log aggregation
    logs = {
      name    = "logs"
      type    = "A"
      ttl     = 300
      records = [var.log_server_ip]
    }

    # Service discovery TXT records
    service_config = {
      name    = "_config"
      type    = "TXT"
      ttl     = 300
      records = [
        "env=${var.environment}",
        "region=${var.aws_region}",
        "vpc=${local.vpc_id}"
      ]
    }
  }

  # Tags
  tags = {
    Name        = "Private DNS Zone"
    Environment = var.environment
    Purpose     = "Internal service discovery"
    VPC         = local.vpc_id
  }
}
