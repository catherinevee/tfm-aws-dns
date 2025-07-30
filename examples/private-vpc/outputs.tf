# Outputs for Private DNS with VPC Example

output "private_zone_id" {
  description = "The hosted zone ID of the private zone"
  value       = module.private_dns.private_zone_id
}

output "private_zone_name" {
  description = "The name of the private hosted zone"
  value       = module.private_dns.private_zone_name
}

output "private_zone_name_servers" {
  description = "Name servers for the private hosted zone"
  value       = module.private_dns.private_zone_name_servers
}

output "private_records" {
  description = "DNS records created in the private zone"
  value       = module.private_dns.private_records
}

output "vpc_associations" {
  description = "VPC associations for the private zone"
  value       = module.private_dns.additional_vpc_associations
}

output "zone_configuration" {
  description = "Complete private zone configuration"
  value = {
    domain_name   = var.private_domain_name
    zone_id       = module.private_dns.private_zone_id
    vpc_id        = var.vpc_id
    records_count = length(module.private_dns.private_records)
    environment   = var.environment
  }
}
