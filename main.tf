# ==============================================================================
# AWS DNS TERRAFORM MODULE - ENHANCED FOR MAXIMUM CUSTOMIZABILITY
# ==============================================================================
# This module provides comprehensive DNS management capabilities including:
# - Public hosted zones with advanced routing policies
# - Private hosted zones with VPC associations
# - Route 53 Resolver endpoints for hybrid DNS
# - Health checks with detailed monitoring
# - DNS records with all routing policy types
# Default values are optimized for production use and security best practices

# ==============================================================================
# DATA SOURCES - DYNAMIC RESOURCE DISCOVERY
# ==============================================================================

# VPC data source for private zone associations
# Used when a single VPC ID is specified for private zone
data "aws_vpc" "selected" {
  count = var.private_zone_enabled && var.vpc_id != null ? 1 : 0
  id    = var.vpc_id
}

# All VPCs data source for automatic association
# Used when no specific VPC is provided but private zone is enabled
data "aws_vpcs" "all" {
  count = var.private_zone_enabled && var.vpc_id == null && length(var.vpc_ids) == 0 ? 1 : 0
}

# Availability zones for resolver endpoint placement
# Used to ensure resolver endpoints are placed in appropriate AZs
data "aws_availability_zones" "available" {
  count = var.resolver_inbound_enabled || var.resolver_outbound_enabled ? 1 : 0
  state = "available"
}

# Current AWS region for regional configurations
data "aws_region" "current" {}

# Current AWS caller identity for account-specific configurations
data "aws_caller_identity" "current" {}

# ==============================================================================
# PUBLIC HOSTED ZONE - INTERNET-FACING DNS
# ==============================================================================
# Creates a public hosted zone for internet-accessible domain resolution
# Supports advanced routing policies and health checks

resource "aws_route53_zone" "public" {
  count = var.public_zone_enabled ? 1 : 0

  # Domain name - Required, must be a valid DNS domain
  name = var.domain_name
  
  # Zone comment - Default: "Managed by Terraform"
  # Helps identify the purpose and management of the zone
  comment = var.public_zone_comment
  
  # Delegation set ID - Default: null (AWS assigns random name servers)
  # Use reusable delegation sets for consistent name servers across zones
  delegation_set_id = var.delegation_set_id
  
  # Force destroy - Default: false (safety measure)
  # When true, allows deletion of zone even with existing records
  # WARNING: Setting to true can cause data loss
  force_destroy = var.force_destroy

  # VPC associations for public zones - Default: empty list
  # Allows private queries to public zone from specified VPCs
  # Useful for split-horizon DNS scenarios
  dynamic "vpc" {
    for_each = var.public_zone_vpc_associations
    content {
      # VPC ID where private queries should resolve to this public zone
      vpc_id = vpc.value.vpc_id
      
      # VPC region - Default: current region
      # Required for cross-region VPC associations
      vpc_region = lookup(vpc.value, "vpc_region", data.aws_region.current.name)
    }
  }

  # Comprehensive tagging strategy
  # Combines module tags, zone-specific tags, and automatic tags
  tags = merge(
    var.tags,                    # Global module tags
    var.public_zone_tags,        # Public zone specific tags
    {
      Name        = "${var.domain_name}-public"
      Type        = "public"
      Zone        = "public-hosted-zone"
      ManagedBy   = "Terraform"
      Module      = "tfm-aws-dns"
      Environment = lookup(var.tags, "Environment", "unspecified")
      Domain      = var.domain_name
    }
  )
}

# ==============================================================================
# PRIVATE HOSTED ZONE - VPC-INTERNAL DNS
# ==============================================================================
# Creates a private hosted zone for internal VPC domain resolution
# Supports multiple VPC associations and cross-region configurations

resource "aws_route53_zone" "private" {
  count = var.private_zone_enabled ? 1 : 0

  # Domain name - Default: uses main domain_name if private_domain_name not specified
  # Allows different domain for private zone (e.g., internal.example.com)
  name = var.private_domain_name != null ? var.private_domain_name : var.domain_name
  
  # Zone comment - Default: "Private zone managed by Terraform"
  # Helps identify the purpose and management of the private zone
  comment = var.private_zone_comment
  
  # Force destroy - Default: false (safety measure)
  # When true, allows deletion of zone even with existing records
  # WARNING: Setting to true can cause data loss
  force_destroy = var.force_destroy

  # VPC associations - Automatically configured based on input variables
  # Supports single VPC, multiple VPCs, and explicit VPC associations
  # Private zones require at least one VPC association
  dynamic "vpc" {
    for_each = local.vpc_associations
    content {
      # VPC ID where this private zone should be accessible
      vpc_id = vpc.value.vpc_id
      
      # VPC region - Default: current region
      # Required for cross-region VPC associations
      vpc_region = lookup(vpc.value, "vpc_region", data.aws_region.current.name)
    }
  }

  # Comprehensive tagging strategy
  # Combines module tags, zone-specific tags, and automatic tags
  tags = merge(
    var.tags,                    # Global module tags
    var.private_zone_tags,       # Private zone specific tags
    {
      Name        = "${var.private_domain_name != null ? var.private_domain_name : var.domain_name}-private"
      Type        = "private"
      Zone        = "private-hosted-zone"
      ManagedBy   = "Terraform"
      Module      = "tfm-aws-dns"
      Environment = lookup(var.tags, "Environment", "unspecified")
      Domain      = var.private_domain_name != null ? var.private_domain_name : var.domain_name
      Visibility  = "vpc-internal"
    }
  )
}

# ==============================================================================
# ADDITIONAL VPC ASSOCIATIONS - CROSS-REGION AND MULTI-VPC SUPPORT
# ==============================================================================
# Allows association of additional VPCs to private zones after creation
# Useful for cross-region scenarios and gradual VPC onboarding

resource "aws_route53_zone_association" "additional" {
  count = var.private_zone_enabled ? length(var.additional_vpc_associations) : 0

  # Private zone ID to associate with
  zone_id = aws_route53_zone.private[0].zone_id
  
  # VPC ID to associate - Can be in different region
  vpc_id = var.additional_vpc_associations[count.index].vpc_id
  
  # VPC region - Required for cross-region associations
  # Default: current region if not specified
  vpc_region = lookup(
    var.additional_vpc_associations[count.index],
    "vpc_region",
    data.aws_region.current.name
  )
}

# ==============================================================================
# PUBLIC DNS RECORDS - INTERNET-ACCESSIBLE DOMAIN RESOLUTION
# ==============================================================================
# Creates DNS records in the public hosted zone with advanced routing policies
# Supports all Route 53 routing types and health check integration

resource "aws_route53_record" "public" {
  for_each = var.public_zone_enabled ? var.public_records : {}

  # Zone ID where the record will be created
  zone_id = aws_route53_zone.public[0].zone_id
  
  # Record name - Can be FQDN or relative to zone
  name = each.value.name
  
  # Record type - A, AAAA, CNAME, MX, TXT, SRV, etc.
  type = each.value.type
  
  # TTL (Time To Live) - Default: 300 seconds (5 minutes)
  # Lower values provide faster updates, higher values reduce DNS queries
  ttl = lookup(each.value, "ttl", 300)

  # Record values - IP addresses, hostnames, or other data
  # Not used with alias records
  records = lookup(each.value, "records", null)

  # ALIAS RECORD CONFIGURATION
  # AWS-specific feature for pointing to AWS resources without TTL
  # More efficient than CNAME and works at the zone apex
  dynamic "alias" {
    for_each = lookup(each.value, "alias", null) != null ? [each.value.alias] : []
    content {
      # Target resource DNS name (e.g., ELB, CloudFront)
      name = alias.value.name
      
      # Target resource hosted zone ID
      zone_id = alias.value.zone_id
      
      # Health check evaluation - Default: false
      # When true, Route 53 checks target health before routing
      evaluate_target_health = lookup(alias.value, "evaluate_target_health", false)
    }
  }

  # WEIGHTED ROUTING POLICY
  # Distributes traffic based on assigned weights (0-255)
  # Useful for A/B testing, gradual deployments, load distribution
  dynamic "weighted_routing_policy" {
    for_each = lookup(each.value, "weighted_routing_policy", null) != null ? [each.value.weighted_routing_policy] : []
    content {
      # Weight value (0-255) - Higher weights receive more traffic
      # Weight 0 stops traffic to this record
      weight = weighted_routing_policy.value.weight
    }
  }

  # LATENCY-BASED ROUTING POLICY
  # Routes traffic to the region with lowest latency for the user
  # Requires records in multiple regions with same name and type
  dynamic "latency_routing_policy" {
    for_each = lookup(each.value, "latency_routing_policy", null) != null ? [each.value.latency_routing_policy] : []
    content {
      # AWS region where the resource is located
      # Route 53 measures latency to this region
      region = latency_routing_policy.value.region
    }
  }

  # GEOLOCATION ROUTING POLICY
  # Routes traffic based on user's geographic location
  # Supports continent, country, and subdivision (state/province) targeting
  dynamic "geolocation_routing_policy" {
    for_each = lookup(each.value, "geolocation_routing_policy", null) != null ? [each.value.geolocation_routing_policy] : []
    content {
      # Continent code (e.g., "NA" for North America)
      continent = lookup(geolocation_routing_policy.value, "continent", null)
      
      # Country code (ISO 3166-1 alpha-2, e.g., "US")
      country = lookup(geolocation_routing_policy.value, "country", null)
      
      # Subdivision code (state/province, e.g., "CA" for California)
      subdivision = lookup(geolocation_routing_policy.value, "subdivision", null)
    }
  }

  # FAILOVER ROUTING POLICY
  # Provides active-passive failover configuration
  # Requires health checks to determine resource availability
  dynamic "failover_routing_policy" {
    for_each = lookup(each.value, "failover_routing_policy", null) != null ? [each.value.failover_routing_policy] : []
    content {
      # Failover type - "PRIMARY" or "SECONDARY"
      # PRIMARY: Active resource, SECONDARY: Standby resource
      type = failover_routing_policy.value.type
    }
  }

  # MULTIVALUE ANSWER ROUTING POLICY
  # Returns multiple healthy records in response to DNS queries
  # Each record can have its own health check
  dynamic "multivalue_answer_routing_policy" {
    for_each = lookup(each.value, "multivalue_answer_routing_policy", false) ? [true] : []
    content {}
  }

  # GEOPROXIMITY ROUTING POLICY
  # Routes traffic based on geographic location with bias adjustment
  # Requires Route 53 Traffic Flow (additional cost)
  dynamic "geoproximity_routing_policy" {
    for_each = lookup(each.value, "geoproximity_routing_policy", null) != null ? [each.value.geoproximity_routing_policy] : []
    content {
      # AWS region for the resource
      aws_region = lookup(geoproximity_routing_policy.value, "aws_region", null)
      
      # Local zone group for Local Zones
      local_zone_group = lookup(geoproximity_routing_policy.value, "local_zone_group", null)
      
      # Bias value (-99 to 99) to expand or shrink geographic region
      bias = lookup(geoproximity_routing_policy.value, "bias", 0)
      
      # Coordinates for non-AWS resources
      dynamic "coordinates" {
        for_each = lookup(geoproximity_routing_policy.value, "coordinates", null) != null ? [geoproximity_routing_policy.value.coordinates] : []
        content {
          latitude  = coordinates.value.latitude
          longitude = coordinates.value.longitude
        }
      }
    }
  }

  # ROUTING POLICY IDENTIFIERS
  # Set identifier - Required for weighted, latency, geolocation, failover routing
  # Must be unique within the same name and type combination
  set_identifier = lookup(each.value, "set_identifier", null)
  
  # Health check ID - Associates record with Route 53 health check
  # Required for failover routing, optional for other routing policies
  health_check_id = lookup(each.value, "health_check_id", null)
  
  # Allow overwrite - Default: true
  # When false, prevents overwriting existing records
  allow_overwrite = lookup(each.value, "allow_overwrite", true)
}

# DNS Records for Private Zone
resource "aws_route53_record" "private" {
  for_each = var.private_zone_enabled ? var.private_records : {}

  zone_id = aws_route53_zone.private[0].zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = each.value.ttl

  records = each.value.records

  dynamic "alias" {
    for_each = each.value.alias != null ? [each.value.alias] : []
    content {
      name                   = alias.value.name
      zone_id                = alias.value.zone_id
      evaluate_target_health = alias.value.evaluate_target_health
    }
  }
}

# Route 53 Resolver Endpoint (for hybrid DNS)
resource "aws_route53_resolver_endpoint" "inbound" {
  count = var.resolver_inbound_enabled ? 1 : 0

  name      = var.resolver_inbound_name
  direction = "INBOUND"

  security_group_ids = var.resolver_security_group_ids

  dynamic "ip_address" {
    for_each = var.resolver_inbound_ip_addresses
    content {
      subnet_id = ip_address.value.subnet_id
      ip        = ip_address.value.ip
    }
  }

  tags = merge(
    var.tags,
    var.resolver_tags,
    {
      Name = var.resolver_inbound_name
      Type = "inbound"
    }
  )
}

resource "aws_route53_resolver_endpoint" "outbound" {
  count = var.resolver_outbound_enabled ? 1 : 0

  name      = var.resolver_outbound_name
  direction = "OUTBOUND"

  security_group_ids = var.resolver_security_group_ids

  dynamic "ip_address" {
    for_each = var.resolver_outbound_ip_addresses
    content {
      subnet_id = ip_address.value.subnet_id
      ip        = ip_address.value.ip
    }
  }

  tags = merge(
    var.tags,
    var.resolver_tags,
    {
      Name = var.resolver_outbound_name
      Type = "outbound"
    }
  )
}

# Route 53 Resolver Rules (for hybrid DNS)
resource "aws_route53_resolver_rule" "forward" {
  for_each = var.resolver_outbound_enabled ? var.resolver_rules : {}

  domain_name          = each.value.domain_name
  name                 = each.value.name
  rule_type            = each.value.rule_type
  resolver_endpoint_id = each.value.rule_type == "FORWARD" ? aws_route53_resolver_endpoint.outbound[0].id : null

  dynamic "target_ip" {
    for_each = each.value.target_ips != null ? each.value.target_ips : []
    content {
      ip   = target_ip.value.ip
      port = target_ip.value.port
    }
  }

  tags = merge(
    var.tags,
    var.resolver_tags,
    {
      Name = each.value.name
      Type = "resolver-rule"
    }
  )
}

# Route 53 Resolver Rule Associations
resource "aws_route53_resolver_rule_association" "main" {
  for_each = var.resolver_outbound_enabled ? var.resolver_rule_associations : {}

  resolver_rule_id = aws_route53_resolver_rule.forward[each.value.rule_key].id
  vpc_id           = each.value.vpc_id
}

# Health Checks
resource "aws_route53_health_check" "main" {
  for_each = var.health_checks

  fqdn                            = each.value.fqdn
  port                            = each.value.port
  type                            = each.value.type
  resource_path                   = each.value.resource_path
  failure_threshold               = each.value.failure_threshold
  request_interval                = each.value.request_interval
  cloudwatch_logs_region          = each.value.cloudwatch_logs_region
  cloudwatch_logs_log_group_name  = each.value.cloudwatch_logs_log_group_name
  insufficient_data_health_status = each.value.insufficient_data_health_status
  invert_healthcheck              = each.value.invert_healthcheck
  measure_latency                 = each.value.measure_latency
  enable_sni                      = each.value.enable_sni

  tags = merge(
    var.tags,
    var.health_check_tags,
    {
      Name = each.key
      Type = "health-check"
    }
  )
}

# Local values for VPC associations
locals {
  vpc_associations = var.private_zone_enabled ? concat(
    var.vpc_id != null ? [{
      vpc_id     = var.vpc_id
      vpc_region = var.vpc_region
    }] : [],
    var.vpc_ids != null ? [for vpc_id in var.vpc_ids : {
      vpc_id     = vpc_id
      vpc_region = var.vpc_region
    }] : [],
    var.vpc_associations
  ) : []
}
