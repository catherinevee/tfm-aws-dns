# AWS DNS Terraform Module Outputs

# Public Zone Outputs
output "public_zone_id" {
  description = "The hosted zone ID of the public zone"
  value       = var.public_zone_enabled ? aws_route53_zone.public[0].zone_id : null
}

output "public_zone_arn" {
  description = "The Amazon Resource Name (ARN) of the public hosted zone"
  value       = var.public_zone_enabled ? aws_route53_zone.public[0].arn : null
}

output "public_zone_name_servers" {
  description = "A list of name servers in associated (or default) delegation set"
  value       = var.public_zone_enabled ? aws_route53_zone.public[0].name_servers : []
}

output "public_zone_name" {
  description = "The name of the public hosted zone"
  value       = var.public_zone_enabled ? aws_route53_zone.public[0].name : null
}

# Private Zone Outputs
output "private_zone_id" {
  description = "The hosted zone ID of the private zone"
  value       = var.private_zone_enabled ? aws_route53_zone.private[0].zone_id : null
}

output "private_zone_arn" {
  description = "The Amazon Resource Name (ARN) of the private hosted zone"
  value       = var.private_zone_enabled ? aws_route53_zone.private[0].arn : null
}

output "private_zone_name_servers" {
  description = "A list of name servers in associated (or default) delegation set for private zone"
  value       = var.private_zone_enabled ? aws_route53_zone.private[0].name_servers : []
}

output "private_zone_name" {
  description = "The name of the private hosted zone"
  value       = var.private_zone_enabled ? aws_route53_zone.private[0].name : null
}

# DNS Records Outputs
output "public_records" {
  description = "Map of public DNS records created"
  value = var.public_zone_enabled ? {
    for k, v in aws_route53_record.public : k => {
      name    = v.name
      type    = v.type
      fqdn    = v.fqdn
      zone_id = v.zone_id
    }
  } : {}
}

output "private_records" {
  description = "Map of private DNS records created"
  value = var.private_zone_enabled ? {
    for k, v in aws_route53_record.private : k => {
      name    = v.name
      type    = v.type
      fqdn    = v.fqdn
      zone_id = v.zone_id
    }
  } : {}
}

# Resolver Endpoints Outputs
output "resolver_inbound_endpoint_id" {
  description = "The ID of the inbound resolver endpoint"
  value       = var.resolver_inbound_enabled ? aws_route53_resolver_endpoint.inbound[0].id : null
}

output "resolver_inbound_endpoint_arn" {
  description = "The ARN of the inbound resolver endpoint"
  value       = var.resolver_inbound_enabled ? aws_route53_resolver_endpoint.inbound[0].arn : null
}

output "resolver_inbound_endpoint_host_vpc_id" {
  description = "The ID of the VPC that you want to create the resolver endpoint in"
  value       = var.resolver_inbound_enabled ? aws_route53_resolver_endpoint.inbound[0].host_vpc_id : null
}

output "resolver_outbound_endpoint_id" {
  description = "The ID of the outbound resolver endpoint"
  value       = var.resolver_outbound_enabled ? aws_route53_resolver_endpoint.outbound[0].id : null
}

output "resolver_outbound_endpoint_arn" {
  description = "The ARN of the outbound resolver endpoint"
  value       = var.resolver_outbound_enabled ? aws_route53_resolver_endpoint.outbound[0].arn : null
}

output "resolver_outbound_endpoint_host_vpc_id" {
  description = "The ID of the VPC that you want to create the resolver endpoint in"
  value       = var.resolver_outbound_enabled ? aws_route53_resolver_endpoint.outbound[0].host_vpc_id : null
}

# Resolver Rules Outputs
output "resolver_rules" {
  description = "Map of resolver rules created"
  value = var.resolver_outbound_enabled ? {
    for k, v in aws_route53_resolver_rule.forward : k => {
      id           = v.id
      arn          = v.arn
      domain_name  = v.domain_name
      name         = v.name
      rule_type    = v.rule_type
      owner_id     = v.owner_id
      share_status = v.share_status
    }
  } : {}
}

output "resolver_rule_associations" {
  description = "Map of resolver rule associations created"
  value = var.resolver_outbound_enabled ? {
    for k, v in aws_route53_resolver_rule_association.main : k => {
      id               = v.id
      resolver_rule_id = v.resolver_rule_id
      vpc_id           = v.vpc_id
    }
  } : {}
}

# Health Checks Outputs
output "health_checks" {
  description = "Map of health checks created"
  value = {
    for k, v in aws_route53_health_check.main : k => {
      id                     = v.id
      arn                    = v.arn
      fqdn                   = v.fqdn
      type                   = v.type
      cloudwatch_logs_region = v.cloudwatch_logs_region
    }
  }
}

# Zone Association Outputs
output "additional_vpc_associations" {
  description = "Map of additional VPC associations created"
  value = var.private_zone_enabled ? {
    for k, v in aws_route53_zone_association.additional : k => {
      id         = v.id
      zone_id    = v.zone_id
      vpc_id     = v.vpc_id
      vpc_region = v.vpc_region
    }
  } : {}
}

# Comprehensive Output for Integration
output "dns_configuration" {
  description = "Complete DNS configuration summary"
  value = {
    public_zone = var.public_zone_enabled ? {
      zone_id      = aws_route53_zone.public[0].zone_id
      zone_arn     = aws_route53_zone.public[0].arn
      name_servers = aws_route53_zone.public[0].name_servers
      domain_name  = aws_route53_zone.public[0].name
    } : null

    private_zone = var.private_zone_enabled ? {
      zone_id      = aws_route53_zone.private[0].zone_id
      zone_arn     = aws_route53_zone.private[0].arn
      name_servers = aws_route53_zone.private[0].name_servers
      domain_name  = aws_route53_zone.private[0].name
    } : null

    resolver_endpoints = {
      inbound = var.resolver_inbound_enabled ? {
        id          = aws_route53_resolver_endpoint.inbound[0].id
        arn         = aws_route53_resolver_endpoint.inbound[0].arn
        host_vpc_id = aws_route53_resolver_endpoint.inbound[0].host_vpc_id
      } : null

      outbound = var.resolver_outbound_enabled ? {
        id          = aws_route53_resolver_endpoint.outbound[0].id
        arn         = aws_route53_resolver_endpoint.outbound[0].arn
        host_vpc_id = aws_route53_resolver_endpoint.outbound[0].host_vpc_id
      } : null
    }

    records_count = {
      public  = length(var.public_records)
      private = length(var.private_records)
    }

    health_checks_count  = length(var.health_checks)
    resolver_rules_count = length(var.resolver_rules)
  }
}
