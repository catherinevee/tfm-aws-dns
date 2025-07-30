# Outputs for Complete DNS Example

# Public Zone Outputs
output "public_zone_id" {
  description = "The hosted zone ID of the public zone"
  value       = module.complete_dns.public_zone_id
}

output "public_zone_name_servers" {
  description = "Name servers for the public hosted zone"
  value       = module.complete_dns.public_zone_name_servers
}

output "public_zone_arn" {
  description = "The ARN of the public hosted zone"
  value       = module.complete_dns.public_zone_arn
}

# Private Zone Outputs
output "private_zone_id" {
  description = "The hosted zone ID of the private zone"
  value       = module.complete_dns.private_zone_id
}

output "private_zone_name" {
  description = "The name of the private hosted zone"
  value       = module.complete_dns.private_zone_name
}

output "private_zone_arn" {
  description = "The ARN of the private hosted zone"
  value       = module.complete_dns.private_zone_arn
}

# Resolver Endpoints Outputs
output "resolver_inbound_endpoint_id" {
  description = "The ID of the inbound resolver endpoint"
  value       = module.complete_dns.resolver_inbound_endpoint_id
}

output "resolver_outbound_endpoint_id" {
  description = "The ID of the outbound resolver endpoint"
  value       = module.complete_dns.resolver_outbound_endpoint_id
}

output "resolver_security_group_id" {
  description = "The security group ID for resolver endpoints"
  value       = aws_security_group.resolver.id
}

# Health Checks Outputs
output "health_checks" {
  description = "Map of health checks created"
  value       = module.complete_dns.health_checks
}

output "health_check_log_group" {
  description = "CloudWatch log group for health checks"
  value       = aws_cloudwatch_log_group.health_checks.name
}

# DNS Records Outputs
output "public_records" {
  description = "Public DNS records created"
  value       = module.complete_dns.public_records
}

output "private_records" {
  description = "Private DNS records created"
  value       = module.complete_dns.private_records
}

# Resolver Rules Outputs
output "resolver_rules" {
  description = "Map of resolver rules created"
  value       = module.complete_dns.resolver_rules
}

output "resolver_rule_associations" {
  description = "Map of resolver rule associations created"
  value       = module.complete_dns.resolver_rule_associations
}

# Complete DNS Configuration Summary
output "complete_dns_configuration" {
  description = "Complete DNS infrastructure configuration summary"
  value = {
    public_zone = {
      zone_id       = module.complete_dns.public_zone_id
      zone_arn      = module.complete_dns.public_zone_arn
      domain_name   = var.domain_name
      name_servers  = module.complete_dns.public_zone_name_servers
      records_count = length(module.complete_dns.public_records)
    }

    private_zone = {
      zone_id       = module.complete_dns.private_zone_id
      zone_arn      = module.complete_dns.private_zone_arn
      domain_name   = var.private_domain_name
      vpc_id        = var.vpc_id
      records_count = length(module.complete_dns.private_records)
    }

    resolver_endpoints = var.enable_hybrid_dns ? {
      inbound_id        = module.complete_dns.resolver_inbound_endpoint_id
      outbound_id       = module.complete_dns.resolver_outbound_endpoint_id
      security_group_id = aws_security_group.resolver.id
      rules_count       = length(module.complete_dns.resolver_rules)
    } : null

    health_monitoring = {
      health_checks_count = length(module.complete_dns.health_checks)
      log_group           = aws_cloudwatch_log_group.health_checks.name
      monitoring_enabled  = true
    }

    routing_policies = {
      failover_enabled      = true
      weighted_enabled      = true
      geolocation_enabled   = true
      health_checks_enabled = true
    }

    environment = var.environment
    owner       = var.owner
    cost_center = var.cost_center
  }
}

# Network and Security Information
output "network_configuration" {
  description = "Network and security configuration details"
  value = {
    vpc_id             = var.vpc_id
    resolver_enabled   = var.enable_hybrid_dns
    security_group_id  = aws_security_group.resolver.id
    log_group_arn      = aws_cloudwatch_log_group.health_checks.arn
    on_premises_domain = var.on_premises_domain
    hybrid_dns_enabled = var.enable_hybrid_dns
  }
}

# Monitoring and Alerting Information
output "monitoring_configuration" {
  description = "Monitoring and alerting configuration"
  value = {
    cloudwatch_log_group = {
      name           = aws_cloudwatch_log_group.health_checks.name
      arn            = aws_cloudwatch_log_group.health_checks.arn
      retention_days = aws_cloudwatch_log_group.health_checks.retention_in_days
    }

    health_checks = {
      primary_website = {
        id   = module.complete_dns.health_checks["primary"].id
        fqdn = "www.${var.domain_name}"
        type = "HTTPS"
      }
      api_us_east = {
        id   = module.complete_dns.health_checks["api_us_east"].id
        fqdn = var.api_us_east_ip
        type = "HTTPS"
      }
      api_us_west = {
        id   = module.complete_dns.health_checks["api_us_west"].id
        fqdn = var.api_us_west_ip
        type = "HTTPS"
      }
    }

    total_health_checks = length(module.complete_dns.health_checks)
  }
}
