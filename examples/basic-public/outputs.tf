# Outputs for Basic Public DNS Example

output "public_zone_id" {
  description = "The hosted zone ID of the public zone"
  value       = module.public_dns.public_zone_id
}

output "public_zone_name_servers" {
  description = "Name servers for the public hosted zone"
  value       = module.public_dns.public_zone_name_servers
}

output "public_zone_name" {
  description = "The name of the public hosted zone"
  value       = module.public_dns.public_zone_name
}

output "dns_records" {
  description = "DNS records created in the public zone"
  value       = module.public_dns.public_records
}

output "zone_configuration" {
  description = "Complete zone configuration"
  value = {
    domain_name   = var.domain_name
    zone_id       = module.public_dns.public_zone_id
    name_servers  = module.public_dns.public_zone_name_servers
    records_count = length(module.public_dns.public_records)
  }
}
