# Outputs for simple DNS records

output "zone_id" {
  description = "Route 53 hosted zone ID"
  value       = module.simple_dns_records.public_zone_id
}

output "zone_name" {
  description = "Domain name of the hosted zone"
  value       = module.simple_dns_records.public_zone_name
}

output "name_servers" {
  description = "Name servers for the hosted zone"
  value       = module.simple_dns_records.public_zone_name_servers
}

output "dns_records_created" {
  description = "Summary of DNS records created"
  value = {
    root_domain = "${var.domain_name} -> ${var.web_server_ip}"
    www_subdomain = "www.${var.domain_name} -> ${var.web_server_ip}"
    api_subdomain = "api.${var.domain_name} -> ${var.api_server_ip}"
    blog_cname = "blog.${var.domain_name} -> myblog.wordpress.com"
    mail_servers = [
      "mail.${var.domain_name} -> ${var.mail_server_ip}",
      "mail2.${var.domain_name} -> ${var.mail_server_backup_ip}"
    ]
    mx_records = [
      "10 mail.${var.domain_name}",
      "20 mail2.${var.domain_name}"
    ]
  }
}

output "verification_commands" {
  description = "Commands to verify DNS records"
  value = {
    check_root = "dig A ${var.domain_name}"
    check_www = "dig A www.${var.domain_name}"
    check_api = "dig A api.${var.domain_name}"
    check_blog = "dig CNAME blog.${var.domain_name}"
    check_mx = "dig MX ${var.domain_name}"
    check_txt = "dig TXT ${var.domain_name}"
  }
}

output "zone_arn" {
  description = "ARN of the hosted zone"
  value       = module.simple_dns_records.public_zone_arn
}
