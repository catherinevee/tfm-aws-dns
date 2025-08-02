# Outputs for minimal DNS zone

output "zone_id" {
  description = "Route 53 hosted zone ID"
  value       = module.minimal_dns.public_zone_id
}

output "zone_name" {
  description = "Domain name of the hosted zone"
  value       = module.minimal_dns.public_zone_name
}

output "name_servers" {
  description = "Name servers for the hosted zone"
  value       = module.minimal_dns.public_zone_name_servers
}

output "zone_arn" {
  description = "ARN of the hosted zone"
  value       = module.minimal_dns.public_zone_arn
}
