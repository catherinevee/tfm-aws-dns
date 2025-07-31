# ==============================================================================
# COMPREHENSIVE DNS EXAMPLE OUTPUTS
# ==============================================================================
# Outputs demonstrating the extensive information available from the enhanced DNS module

# ==============================================================================
# PUBLIC HOSTED ZONE OUTPUTS
# ==============================================================================

output "public_zone_id" {
  description = "ID of the public hosted zone"
  value       = module.dns_comprehensive.public_zone_id
}

output "public_zone_arn" {
  description = "ARN of the public hosted zone"
  value       = module.dns_comprehensive.public_zone_arn
}

output "public_zone_name_servers" {
  description = "Name servers for the public hosted zone"
  value       = module.dns_comprehensive.public_zone_name_servers
}

output "public_zone_zone_id" {
  description = "Zone ID for the public hosted zone"
  value       = module.dns_comprehensive.public_zone_zone_id
}

# ==============================================================================
# PRIVATE HOSTED ZONE OUTPUTS
# ==============================================================================

output "private_zone_id" {
  description = "ID of the private hosted zone"
  value       = module.dns_comprehensive.private_zone_id
}

output "private_zone_arn" {
  description = "ARN of the private hosted zone"
  value       = module.dns_comprehensive.private_zone_arn
}

output "private_zone_name_servers" {
  description = "Name servers for the private hosted zone"
  value       = module.dns_comprehensive.private_zone_name_servers
}

output "private_zone_vpc_associations" {
  description = "VPC associations for the private hosted zone"
  value       = module.dns_comprehensive.private_zone_vpc_associations
}

# ==============================================================================
# DNS RECORDS OUTPUTS
# ==============================================================================

output "public_records" {
  description = "Public DNS records created"
  value       = module.dns_comprehensive.public_records
  sensitive   = false
}

output "private_records" {
  description = "Private DNS records created"
  value       = module.dns_comprehensive.private_records
  sensitive   = false
}

# ==============================================================================
# RESOLVER ENDPOINTS OUTPUTS
# ==============================================================================

output "resolver_inbound_endpoint_id" {
  description = "ID of the inbound resolver endpoint"
  value       = module.dns_comprehensive.resolver_inbound_endpoint_id
}

output "resolver_inbound_endpoint_arn" {
  description = "ARN of the inbound resolver endpoint"
  value       = module.dns_comprehensive.resolver_inbound_endpoint_arn
}

output "resolver_inbound_endpoint_ip_addresses" {
  description = "IP addresses of the inbound resolver endpoint"
  value       = module.dns_comprehensive.resolver_inbound_endpoint_ip_addresses
}

output "resolver_outbound_endpoint_id" {
  description = "ID of the outbound resolver endpoint"
  value       = module.dns_comprehensive.resolver_outbound_endpoint_id
}

output "resolver_outbound_endpoint_arn" {
  description = "ARN of the outbound resolver endpoint"
  value       = module.dns_comprehensive.resolver_outbound_endpoint_arn
}

output "resolver_outbound_endpoint_ip_addresses" {
  description = "IP addresses of the outbound resolver endpoint"
  value       = module.dns_comprehensive.resolver_outbound_endpoint_ip_addresses
}

# ==============================================================================
# RESOLVER RULES OUTPUTS
# ==============================================================================

output "resolver_rules" {
  description = "Resolver rules created"
  value       = module.dns_comprehensive.resolver_rules
}

output "resolver_rule_associations" {
  description = "Resolver rule associations created"
  value       = module.dns_comprehensive.resolver_rule_associations
}

# ==============================================================================
# HEALTH CHECKS OUTPUTS
# ==============================================================================

output "health_checks" {
  description = "Health checks created"
  value       = module.dns_comprehensive.health_checks
}

output "health_check_ids" {
  description = "IDs of the health checks created"
  value       = module.dns_comprehensive.health_check_ids
}

# ==============================================================================
# SECURITY OUTPUTS
# ==============================================================================

output "dns_resolver_security_group_id" {
  description = "Security group ID for DNS resolver endpoints"
  value       = var.enable_resolver_endpoints ? aws_security_group.dns_resolver[0].id : null
}

output "dns_resolver_security_group_arn" {
  description = "Security group ARN for DNS resolver endpoints"
  value       = var.enable_resolver_endpoints ? aws_security_group.dns_resolver[0].arn : null
}

# ==============================================================================
# CONFIGURATION SUMMARY OUTPUTS
# ==============================================================================

output "dns_configuration_summary" {
  description = "Summary of DNS configuration"
  value = {
    domain_name         = var.domain_name
    private_domain_name = var.private_domain_name
    public_zone_enabled = var.enable_public_zone
    private_zone_enabled = var.enable_private_zone
    resolver_endpoints_enabled = var.enable_resolver_endpoints
    health_checks_enabled = var.enable_health_checks
    vpc_id = var.enable_private_zone ? data.aws_vpc.main.id : null
    region = var.aws_region
  }
}

output "routing_policies_used" {
  description = "Summary of routing policies demonstrated"
  value = {
    simple_routing = "www record with basic A record"
    alias_routing = "apex domain with CloudFront alias"
    weighted_routing = "api records with 80/20 traffic split"
    latency_routing = "app records for global latency optimization"
    geolocation_routing = "content records for geographic targeting"
    failover_routing = "service records with primary/secondary failover"
    multivalue_routing = "lb records for load distribution"
  }
}

output "security_features" {
  description = "Security features implemented"
  value = {
    private_zone_vpc_isolation = var.enable_private_zone ? "✓ Private zone isolated to VPC" : "✗ Private zone not enabled"
    resolver_security_groups = var.enable_resolver_endpoints ? "✓ Resolver endpoints secured with security groups" : "✗ Resolver endpoints not enabled"
    health_check_monitoring = var.enable_health_checks ? "✓ Health checks enabled for availability monitoring" : "✗ Health checks not enabled"
    split_horizon_dns = length(var.public_zone_vpc_associations) > 0 ? "✓ Split-horizon DNS configured" : "✗ Split-horizon DNS not configured"
  }
}

# ==============================================================================
# COST OPTIMIZATION OUTPUTS
# ==============================================================================

output "cost_optimization_recommendations" {
  description = "Cost optimization recommendations"
  value = {
    health_checks = var.enable_health_checks ? "Health checks incur $0.50/month per check" : "Health checks disabled - no additional cost"
    resolver_endpoints = var.enable_resolver_endpoints ? "Resolver endpoints cost $0.125/hour per endpoint" : "Resolver endpoints disabled - no additional cost"
    query_charges = "DNS queries: $0.40 per million queries for public zones, $0.40 per million for private zones"
    delegation_sets = var.delegation_set_id != null ? "Using reusable delegation set - no additional cost" : "Consider reusable delegation sets for multiple zones"
  }
}

# ==============================================================================
# OPERATIONAL OUTPUTS
# ==============================================================================

output "dns_testing_commands" {
  description = "Commands for testing DNS resolution"
  value = {
    public_zone_test = var.enable_public_zone ? "dig @8.8.8.8 ${var.domain_name} NS" : "Public zone not enabled"
    private_zone_test = var.enable_private_zone ? "dig @${var.resolver_inbound_ip_1} ${var.private_domain_name != null ? var.private_domain_name : var.domain_name} NS" : "Private zone not enabled"
    health_check_test = var.enable_health_checks ? "aws route53 get-health-check --health-check-id <health-check-id>" : "Health checks not enabled"
  }
}

output "monitoring_recommendations" {
  description = "Monitoring and alerting recommendations"
  value = {
    cloudwatch_metrics = "Monitor Route53 query count, health check status, and resolver endpoint metrics"
    health_check_alarms = var.enable_health_checks ? "Set up CloudWatch alarms for health check failures" : "Enable health checks for monitoring"
    resolver_logs = var.enable_resolver_endpoints ? "Enable resolver query logging for troubleshooting" : "Resolver endpoints not enabled"
    zone_delegation = "Monitor NS record propagation and delegation chain health"
  }
}
