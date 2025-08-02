# Outputs for simple private DNS zone

output "private_zone_id" {
  description = "Route 53 private hosted zone ID"
  value       = module.private_dns.private_zone_id
}

output "private_zone_name" {
  description = "Domain name of the private hosted zone"
  value       = module.private_dns.private_zone_name
}

output "vpc_id" {
  description = "VPC ID associated with the private zone"
  value       = local.vpc_id
}

output "dns_records_created" {
  description = "Summary of private DNS records created"
  value = {
    database_servers = {
      primary = "db-primary.${var.domain_name} -> ${var.db_primary_ip}"
      replica = "db-replica.${var.domain_name} -> ${var.db_replica_ip}"
      cluster_alias = "database.${var.domain_name} -> db-primary.${var.domain_name}"
    }
    application_servers = {
      app_01 = "app-01.${var.domain_name} -> ${var.app_server_1_ip}"
      app_02 = "app-02.${var.domain_name} -> ${var.app_server_2_ip}"
    }
    cache_servers = {
      primary = "redis-primary.${var.domain_name} -> ${var.redis_primary_ip}"
      replica = "redis-replica.${var.domain_name} -> ${var.redis_replica_ip}"
      cluster_alias = "cache.${var.domain_name} -> redis-primary.${var.domain_name}"
    }
    infrastructure = {
      load_balancer = "internal-lb.${var.domain_name} -> ${var.internal_lb_ip}"
      api_internal = "api-internal.${var.domain_name} -> internal-lb.${var.domain_name}"
      monitoring = "monitoring.${var.domain_name} -> ${var.monitoring_server_ip}"
      logs = "logs.${var.domain_name} -> ${var.log_server_ip}"
    }
  }
}

output "service_endpoints" {
  description = "Internal service endpoints for applications"
  value = {
    database = "database.${var.domain_name}"
    cache = "cache.${var.domain_name}"
    api_internal = "api-internal.${var.domain_name}"
    monitoring = "monitoring.${var.domain_name}"
    logs = "logs.${var.domain_name}"
  }
}

output "verification_commands" {
  description = "Commands to verify private DNS records (run from within VPC)"
  value = {
    test_database = "nslookup database.${var.domain_name}"
    test_cache = "nslookup cache.${var.domain_name}"
    test_api = "nslookup api-internal.${var.domain_name}"
    test_monitoring = "nslookup monitoring.${var.domain_name}"
    test_all_records = "dig @169.254.169.253 ${var.domain_name} ANY"
  }
}

output "connection_examples" {
  description = "Example connection strings using private DNS"
  value = {
    database_connection = "postgresql://user:pass@database.${var.domain_name}:5432/mydb"
    redis_connection = "redis://cache.${var.domain_name}:6379"
    api_endpoint = "http://api-internal.${var.domain_name}/v1/"
    monitoring_dashboard = "http://monitoring.${var.domain_name}:3000"
    log_endpoint = "http://logs.${var.domain_name}:5601"
  }
}

output "private_zone_arn" {
  description = "ARN of the private hosted zone"
  value       = module.private_dns.private_zone_arn
}
