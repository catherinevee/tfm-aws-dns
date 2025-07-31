# ==============================================================================
# COMPREHENSIVE DNS EXAMPLE - MAXIMUM CUSTOMIZABILITY DEMONSTRATION
# ==============================================================================
# This example demonstrates the extensive customization capabilities of the
# enhanced DNS module, showcasing all available parameters and advanced features

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

# Data sources for networking
data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  filter {
    name   = "tag:Type"
    values = ["private"]
  }
}

# Security group for DNS resolver endpoints
resource "aws_security_group" "dns_resolver" {
  count = var.enable_resolver_endpoints ? 1 : 0
  
  name_prefix = "${var.project_name}-dns-resolver-"
  vpc_id      = data.aws_vpc.main.id
  description = "Security group for Route 53 Resolver endpoints"

  ingress {
    description = "DNS TCP"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }

  ingress {
    description = "DNS UDP"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-dns-resolver-sg"
    Environment = var.environment
    Purpose     = "DNS Resolver Endpoints"
  }
}

# Comprehensive DNS module with maximum customization
module "dns_comprehensive" {
  source = "../../"

  # ==============================================================================
  # CORE DOMAIN CONFIGURATION
  # ==============================================================================
  domain_name = var.domain_name
  
  # Global tags applied to all resources
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Module      = "tfm-aws-dns-comprehensive"
    Owner       = var.owner
    CostCenter  = var.cost_center
  }
  
  # Force destroy - CAUTION: Allows deletion with existing records
  force_destroy = var.force_destroy

  # ==============================================================================
  # PUBLIC HOSTED ZONE CONFIGURATION
  # ==============================================================================
  public_zone_enabled = var.enable_public_zone
  
  # Custom comment for public zone
  public_zone_comment = "Public DNS zone for ${var.domain_name} - Managed by Terraform"
  
  # Reusable delegation set for consistent name servers
  delegation_set_id = var.delegation_set_id
  
  # VPC associations for split-horizon DNS
  public_zone_vpc_associations = var.public_zone_vpc_associations
  
  # Additional tags specific to public zone
  public_zone_tags = {
    ZoneType    = "public"
    Visibility  = "internet"
    Purpose     = "External DNS resolution"
    Monitoring  = "enabled"
  }

  # ==============================================================================
  # PRIVATE HOSTED ZONE CONFIGURATION
  # ==============================================================================
  private_zone_enabled = var.enable_private_zone
  
  # Separate domain for private zone (optional)
  private_domain_name = var.private_domain_name
  
  # Custom comment for private zone
  private_zone_comment = "Private DNS zone for internal services - Managed by Terraform"
  
  # VPC configuration for private zone
  vpc_id     = var.enable_private_zone ? data.aws_vpc.main.id : null
  vpc_region = var.aws_region
  
  # Additional VPC associations for cross-region or multi-VPC scenarios
  additional_vpc_associations = var.additional_vpc_associations
  
  # Additional tags specific to private zone
  private_zone_tags = {
    ZoneType   = "private"
    Visibility = "vpc-internal"
    Purpose    = "Internal DNS resolution"
    Security   = "vpc-isolated"
  }

  # ==============================================================================
  # PUBLIC DNS RECORDS - COMPREHENSIVE ROUTING POLICIES
  # ==============================================================================
  public_records = var.enable_public_zone ? {
    # Simple A record with custom TTL
    "www" = {
      name    = "www.${var.domain_name}"
      type    = "A"
      ttl     = 300
      records = var.web_server_ips
    }
    
    # Apex domain with alias to CloudFront
    "apex-alias" = {
      name = var.domain_name
      type = "A"
      alias = {
        name                   = var.cloudfront_domain_name
        zone_id               = var.cloudfront_zone_id
        evaluate_target_health = true
      }
    }
    
    # Weighted routing for A/B testing
    "api-primary" = {
      name = "api.${var.domain_name}"
      type = "A"
      ttl  = 60
      records = [var.api_primary_ip]
      weighted_routing_policy = {
        weight = 80  # 80% of traffic
      }
      set_identifier  = "primary"
      health_check_id = var.api_primary_health_check_id
    }
    
    "api-secondary" = {
      name = "api.${var.domain_name}"
      type = "A"
      ttl  = 60
      records = [var.api_secondary_ip]
      weighted_routing_policy = {
        weight = 20  # 20% of traffic
      }
      set_identifier = "secondary"
      health_check_id = var.api_secondary_health_check_id
    }
    
    # Latency-based routing for global applications
    "app-us-east" = {
      name = "app.${var.domain_name}"
      type = "A"
      ttl  = 300
      records = [var.app_us_east_ip]
      latency_routing_policy = {
        region = "us-east-1"
      }
      set_identifier = "us-east-1"
    }
    
    "app-eu-west" = {
      name = "app.${var.domain_name}"
      type = "A"
      ttl  = 300
      records = [var.app_eu_west_ip]
      latency_routing_policy = {
        region = "eu-west-1"
      }
      set_identifier = "eu-west-1"
    }
    
    # Geolocation routing for compliance/localization
    "content-us" = {
      name = "content.${var.domain_name}"
      type = "CNAME"
      ttl  = 300
      records = ["us-content.example.com"]
      geolocation_routing_policy = {
        country = "US"
      }
      set_identifier = "us-content"
    }
    
    "content-eu" = {
      name = "content.${var.domain_name}"
      type = "CNAME"
      ttl  = 300
      records = ["eu-content.example.com"]
      geolocation_routing_policy = {
        continent = "EU"
      }
      set_identifier = "eu-content"
    }
    
    # Failover routing for high availability
    "service-primary" = {
      name = "service.${var.domain_name}"
      type = "A"
      ttl  = 60
      records = [var.service_primary_ip]
      failover_routing_policy = {
        type = "PRIMARY"
      }
      set_identifier  = "primary-service"
      health_check_id = var.service_primary_health_check_id
    }
    
    "service-secondary" = {
      name = "service.${var.domain_name}"
      type = "A"
      ttl  = 60
      records = [var.service_secondary_ip]
      failover_routing_policy = {
        type = "SECONDARY"
      }
      set_identifier = "secondary-service"
    }
    
    # Multivalue answer routing for load distribution
    "lb-server1" = {
      name = "lb.${var.domain_name}"
      type = "A"
      ttl  = 300
      records = [var.lb_server1_ip]
      multivalue_answer_routing_policy = true
      set_identifier = "server1"
      health_check_id = var.lb_server1_health_check_id
    }
    
    "lb-server2" = {
      name = "lb.${var.domain_name}"
      type = "A"
      ttl  = 300
      records = [var.lb_server2_ip]
      multivalue_answer_routing_policy = true
      set_identifier = "server2"
      health_check_id = var.lb_server2_health_check_id
    }
    
    # MX record for email
    "mail" = {
      name = var.domain_name
      type = "MX"
      ttl  = 3600
      records = [
        "10 mail1.${var.domain_name}",
        "20 mail2.${var.domain_name}"
      ]
    }
    
    # TXT records for verification and security
    "verification" = {
      name = var.domain_name
      type = "TXT"
      ttl  = 300
      records = [
        "v=spf1 include:_spf.google.com ~all",
        "google-site-verification=${var.google_verification_code}"
      ]
    }
  } : {}

  # ==============================================================================
  # PRIVATE DNS RECORDS - INTERNAL SERVICES
  # ==============================================================================
  private_records = var.enable_private_zone ? {
    # Internal API endpoints
    "internal-api" = {
      name = "api.${var.private_domain_name != null ? var.private_domain_name : var.domain_name}"
      type = "A"
      ttl  = 300
      records = var.internal_api_ips
    }
    
    # Database endpoints
    "db-primary" = {
      name = "db.${var.private_domain_name != null ? var.private_domain_name : var.domain_name}"
      type = "CNAME"
      ttl  = 300
      records = [var.database_endpoint]
    }
    
    # Internal load balancer
    "internal-lb" = {
      name = "lb.${var.private_domain_name != null ? var.private_domain_name : var.domain_name}"
      type = "A"
      ttl  = 60
      alias = {
        name                   = var.internal_lb_dns_name
        zone_id               = var.internal_lb_zone_id
        evaluate_target_health = true
      }
    }
  } : {}

  # ==============================================================================
  # ROUTE 53 RESOLVER CONFIGURATION - HYBRID DNS
  # ==============================================================================
  resolver_inbound_enabled = var.enable_resolver_endpoints
  resolver_inbound_name    = "${var.project_name}-inbound-resolver"
  
  resolver_outbound_enabled = var.enable_resolver_endpoints
  resolver_outbound_name    = "${var.project_name}-outbound-resolver"
  
  # Security groups for resolver endpoints
  resolver_security_group_ids = var.enable_resolver_endpoints ? [aws_security_group.dns_resolver[0].id] : []
  
  # IP addresses for resolver endpoints
  resolver_inbound_ip_addresses = var.enable_resolver_endpoints ? [
    {
      subnet_id = data.aws_subnets.private.ids[0]
      ip        = var.resolver_inbound_ip_1
    },
    {
      subnet_id = data.aws_subnets.private.ids[1]
      ip        = var.resolver_inbound_ip_2
    }
  ] : []
  
  resolver_outbound_ip_addresses = var.enable_resolver_endpoints ? [
    {
      subnet_id = data.aws_subnets.private.ids[0]
      ip        = var.resolver_outbound_ip_1
    },
    {
      subnet_id = data.aws_subnets.private.ids[1]
      ip        = var.resolver_outbound_ip_2
    }
  ] : []
  
  # Resolver rules for forwarding to on-premises DNS
  resolver_rules = var.enable_resolver_endpoints ? {
    "corp-domain" = {
      domain_name = "corp.example.com"
      name        = "${var.project_name}-corp-rule"
      rule_type   = "FORWARD"
      target_ips = [
        {
          ip   = var.onprem_dns_ip_1
          port = 53
        },
        {
          ip   = var.onprem_dns_ip_2
          port = 53
        }
      ]
    }
  } : {}
  
  # VPC associations for resolver rules
  resolver_rule_associations = var.enable_resolver_endpoints ? {
    "corp-domain-vpc" = {
      rule_key = "corp-domain"
      vpc_id   = data.aws_vpc.main.id
    }
  } : {}
  
  # Additional tags for resolver resources
  resolver_tags = {
    Component = "dns-resolver"
    Purpose   = "hybrid-dns"
    Network   = "cross-premises"
  }

  # ==============================================================================
  # HEALTH CHECKS - COMPREHENSIVE MONITORING
  # ==============================================================================
  health_checks = var.enable_health_checks ? {
    "api-primary-health" = {
      fqdn                            = "api.${var.domain_name}"
      port                            = 443
      type                            = "HTTPS"
      resource_path                   = "/health"
      failure_threshold               = 3
      request_interval                = 30
      cloudwatch_logs_region          = var.aws_region
      cloudwatch_logs_log_group_name  = "/aws/route53/healthchecks"
      insufficient_data_health_status = "Failure"
      invert_healthcheck              = false
      measure_latency                 = true
      enable_sni                      = true
    }
    
    "service-primary-health" = {
      fqdn                            = "service.${var.domain_name}"
      port                            = 80
      type                            = "HTTP"
      resource_path                   = "/status"
      failure_threshold               = 2
      request_interval                = 10
      insufficient_data_health_status = "Success"
      invert_healthcheck              = false
      measure_latency                 = false
      enable_sni                      = false
    }
  } : {}
  
  # Additional tags for health checks
  health_check_tags = {
    Component = "health-monitoring"
    Purpose   = "service-availability"
    Alerting  = "enabled"
  }
}
