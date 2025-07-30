# Outputs for Hybrid DNS with Route 53 Resolver Example

# Public Zone Outputs
output "public_zone_id" {
  description = "The hosted zone ID of the public zone"
  value       = module.hybrid_dns.public_zone_id
}

output "public_zone_name_servers" {
  description = "Name servers for the public hosted zone"
  value       = module.hybrid_dns.public_zone_name_servers
}

# Private Zone Outputs
output "private_zone_id" {
  description = "The hosted zone ID of the private zone"
  value       = module.hybrid_dns.private_zone_id
}

output "private_zone_name" {
  description = "The name of the private hosted zone"
  value       = module.hybrid_dns.private_zone_name
}

# Resolver Endpoints Outputs
output "resolver_inbound_endpoint_id" {
  description = "The ID of the inbound resolver endpoint"
  value       = module.hybrid_dns.resolver_inbound_endpoint_id
}

output "resolver_outbound_endpoint_id" {
  description = "The ID of the outbound resolver endpoint"
  value       = module.hybrid_dns.resolver_outbound_endpoint_id
}

output "resolver_security_group_id" {
  description = "The security group ID for resolver endpoints"
  value       = aws_security_group.resolver.id
}

# Resolver Rules Outputs
output "resolver_rules" {
  description = "Map of resolver rules created"
  value       = module.hybrid_dns.resolver_rules
}

output "resolver_rule_associations" {
  description = "Map of resolver rule associations created"
  value       = module.hybrid_dns.resolver_rule_associations
}

# DNS Records Outputs
output "public_records" {
  description = "Public DNS records created"
  value       = module.hybrid_dns.public_records
}

output "private_records" {
  description = "Private DNS records created"
  value       = module.hybrid_dns.private_records
}

# Complete Configuration Summary
output "hybrid_dns_configuration" {
  description = "Complete hybrid DNS configuration summary"
  value = {
    public_zone = {
      zone_id      = module.hybrid_dns.public_zone_id
      domain_name  = var.public_domain_name
      name_servers = module.hybrid_dns.public_zone_name_servers
    }

    private_zone = {
      zone_id     = module.hybrid_dns.private_zone_id
      domain_name = var.private_domain_name
      vpc_id      = var.vpc_id
    }

    resolver_endpoints = {
      inbound_id        = module.hybrid_dns.resolver_inbound_endpoint_id
      outbound_id       = module.hybrid_dns.resolver_outbound_endpoint_id
      security_group_id = aws_security_group.resolver.id
    }

    forwarding = {
      on_premises_domain = var.on_premises_domain
      dns_servers        = var.on_premises_dns_servers
      rules_count        = length(module.hybrid_dns.resolver_rules)
    }

    environment = var.environment
  }
}

# Network Configuration for Reference
output "network_configuration" {
  description = "Network configuration details"
  value = {
    vpc_id                    = var.vpc_id
    on_premises_cidr_blocks   = var.on_premises_cidr_blocks
    resolver_subnets          = data.aws_subnets.resolver.ids
    inbound_resolver_enabled  = var.enable_inbound_resolver
    outbound_resolver_enabled = var.enable_outbound_resolver
  }
}
