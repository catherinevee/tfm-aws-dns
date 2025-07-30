# AWS DNS Terraform Module
# Supports public, private, and hybrid DNS scenarios

# Data sources for existing resources
data "aws_vpc" "selected" {
  count = var.private_zone_enabled && var.vpc_id != null ? 1 : 0
  id    = var.vpc_id
}

data "aws_vpcs" "all" {
  count = var.private_zone_enabled && var.vpc_id == null && length(var.vpc_ids) == 0 ? 1 : 0
}

# Public Hosted Zone
resource "aws_route53_zone" "public" {
  count = var.public_zone_enabled ? 1 : 0

  name              = var.domain_name
  comment           = var.public_zone_comment
  delegation_set_id = var.delegation_set_id
  force_destroy     = var.force_destroy

  dynamic "vpc" {
    for_each = var.public_zone_vpc_associations
    content {
      vpc_id     = vpc.value.vpc_id
      vpc_region = vpc.value.vpc_region
    }
  }

  tags = merge(
    var.tags,
    var.public_zone_tags,
    {
      Name = "${var.domain_name}-public"
      Type = "public"
    }
  )
}

# Private Hosted Zone
resource "aws_route53_zone" "private" {
  count = var.private_zone_enabled ? 1 : 0

  name          = var.private_domain_name != null ? var.private_domain_name : var.domain_name
  comment       = var.private_zone_comment
  force_destroy = var.force_destroy

  # VPC associations
  dynamic "vpc" {
    for_each = local.vpc_associations
    content {
      vpc_id     = vpc.value.vpc_id
      vpc_region = vpc.value.vpc_region
    }
  }

  tags = merge(
    var.tags,
    var.private_zone_tags,
    {
      Name = "${var.private_domain_name != null ? var.private_domain_name : var.domain_name}-private"
      Type = "private"
    }
  )
}

# Additional VPC associations for private zone
resource "aws_route53_zone_association" "additional" {
  count = var.private_zone_enabled ? length(var.additional_vpc_associations) : 0

  zone_id    = aws_route53_zone.private[0].zone_id
  vpc_id     = var.additional_vpc_associations[count.index].vpc_id
  vpc_region = var.additional_vpc_associations[count.index].vpc_region
}

# DNS Records for Public Zone
resource "aws_route53_record" "public" {
  for_each = var.public_zone_enabled ? var.public_records : {}

  zone_id = aws_route53_zone.public[0].zone_id
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

  dynamic "weighted_routing_policy" {
    for_each = each.value.weighted_routing_policy != null ? [each.value.weighted_routing_policy] : []
    content {
      weight = weighted_routing_policy.value.weight
    }
  }

  dynamic "latency_routing_policy" {
    for_each = each.value.latency_routing_policy != null ? [each.value.latency_routing_policy] : []
    content {
      region = latency_routing_policy.value.region
    }
  }

  dynamic "geolocation_routing_policy" {
    for_each = each.value.geolocation_routing_policy != null ? [each.value.geolocation_routing_policy] : []
    content {
      continent   = geolocation_routing_policy.value.continent
      country     = geolocation_routing_policy.value.country
      subdivision = geolocation_routing_policy.value.subdivision
    }
  }

  dynamic "failover_routing_policy" {
    for_each = each.value.failover_routing_policy != null ? [each.value.failover_routing_policy] : []
    content {
      type = failover_routing_policy.value.type
    }
  }

  set_identifier  = each.value.set_identifier
  health_check_id = each.value.health_check_id
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
