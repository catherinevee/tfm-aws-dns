# Outputs for alias DNS records

output "zone_id" {
  description = "Route 53 hosted zone ID"
  value       = module.alias_dns_records.public_zone_id
}

output "zone_name" {
  description = "Domain name of the hosted zone"
  value       = module.alias_dns_records.public_zone_name
}

output "name_servers" {
  description = "Name servers for the hosted zone"
  value       = module.alias_dns_records.public_zone_name_servers
}

output "alias_records_created" {
  description = "Summary of alias records created"
  value = {
    load_balancer_aliases = var.load_balancer_name != null ? [
      "${var.domain_name} -> ${var.load_balancer_name} (ALB)",
      "www.${var.domain_name} -> ${var.load_balancer_name} (ALB)"
    ] : []
    cloudfront_aliases = var.cloudfront_distribution_id != null ? [
      "cdn.${var.domain_name} -> CloudFront Distribution",
      "static.${var.domain_name} -> CloudFront Distribution"
    ] : []
    api_gateway_alias = var.api_gateway_domain != null ? [
      "api.${var.domain_name} -> ${var.api_gateway_domain}"
    ] : []
  }
}

output "regular_records_created" {
  description = "Summary of regular DNS records created"
  value = {
    blog_cname = "blog.${var.domain_name} -> myblog.medium.com"
    legacy_server = "legacy.${var.domain_name} -> ${var.legacy_server_ip}"
    verification = "${var.domain_name} TXT record for verification"
  }
}

output "verification_commands" {
  description = "Commands to verify DNS records"
  value = {
    check_root = "dig A ${var.domain_name}"
    check_www = "dig A www.${var.domain_name}"
    check_cdn = "dig A cdn.${var.domain_name}"
    check_static = "dig A static.${var.domain_name}"
    check_api = "dig A api.${var.domain_name}"
    check_blog = "dig CNAME blog.${var.domain_name}"
    check_legacy = "dig A legacy.${var.domain_name}"
  }
}

output "aws_resources_referenced" {
  description = "AWS resources referenced by alias records"
  value = {
    load_balancer = var.load_balancer_name
    cloudfront_distribution = var.cloudfront_distribution_id
    api_gateway_domain = var.api_gateway_domain
  }
}

output "zone_arn" {
  description = "ARN of the hosted zone"
  value       = module.alias_dns_records.public_zone_arn
}
