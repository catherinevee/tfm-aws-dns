# Outputs for subdomain delegation

output "main_zone_id" {
  description = "Route 53 hosted zone ID for main domain"
  value       = module.main_domain.public_zone_id
}

output "main_zone_name" {
  description = "Main domain name"
  value       = module.main_domain.public_zone_name
}

output "main_zone_name_servers" {
  description = "Name servers for the main domain"
  value       = module.main_domain.public_zone_name_servers
}

output "api_subdomain_zone_id" {
  description = "Route 53 hosted zone ID for API subdomain (if created)"
  value       = var.create_api_subdomain ? module.api_subdomain[0].public_zone_id : null
}

output "api_subdomain_name_servers" {
  description = "Name servers for API subdomain (if created)"
  value       = var.create_api_subdomain ? module.api_subdomain[0].public_zone_name_servers : null
}

output "staging_subdomain_zone_id" {
  description = "Route 53 hosted zone ID for staging subdomain (if created)"
  value       = var.create_staging_subdomain ? module.staging_subdomain[0].public_zone_id : null
}

output "staging_subdomain_name_servers" {
  description = "Name servers for staging subdomain (if created)"
  value       = var.create_staging_subdomain ? module.staging_subdomain[0].public_zone_name_servers : null
}

output "delegation_records" {
  description = "Summary of subdomain delegation records"
  value = {
    api_delegation = {
      subdomain = "api.${var.domain_name}"
      nameservers = var.api_subdomain_nameservers
    }
    blog_delegation = {
      subdomain = "blog.${var.domain_name}"
      nameservers = var.blog_subdomain_nameservers
    }
    staging_delegation = {
      subdomain = "staging.${var.domain_name}"
      nameservers = var.staging_subdomain_nameservers
    }
    dev_delegation = {
      subdomain = "dev.${var.domain_name}"
      nameservers = var.dev_subdomain_nameservers
    }
  }
}

output "main_domain_records" {
  description = "Summary of main domain records"
  value = {
    root_domain = "${var.domain_name} -> ${var.main_server_ip}"
    www_subdomain = "www.${var.domain_name} -> ${var.main_server_ip}"
    mail_server = "mail.${var.domain_name} -> ${var.mail_server_ip}"
    mx_record = "${var.domain_name} MX -> mail.${var.domain_name}"
  }
}

output "verification_commands" {
  description = "Commands to verify DNS delegation"
  value = {
    check_main_domain = "dig NS ${var.domain_name}"
    check_api_delegation = "dig NS api.${var.domain_name}"
    check_blog_delegation = "dig NS blog.${var.domain_name}"
    check_staging_delegation = "dig NS staging.${var.domain_name}"
    check_dev_delegation = "dig NS dev.${var.domain_name}"
    test_api_resolution = "dig A api.${var.domain_name}"
    test_blog_resolution = "dig A blog.${var.domain_name}"
  }
}

output "delegation_setup_instructions" {
  description = "Instructions for setting up external subdomain zones"
  value = {
    api_subdomain = var.create_api_subdomain ? "API subdomain zone created in this Terraform" : "Create api.${var.domain_name} zone with nameservers: ${join(", ", var.api_subdomain_nameservers)}"
    blog_subdomain = "Create blog.${var.domain_name} zone with nameservers: ${join(", ", var.blog_subdomain_nameservers)}"
    staging_subdomain = var.create_staging_subdomain ? "Staging subdomain zone created in this Terraform" : "Create staging.${var.domain_name} zone with nameservers: ${join(", ", var.staging_subdomain_nameservers)}"
    dev_subdomain = "Create dev.${var.domain_name} zone with nameservers: ${join(", ", var.dev_subdomain_nameservers)}"
  }
}

output "subdomain_examples" {
  description = "Example URLs for delegated subdomains"
  value = {
    api_examples = [
      "https://api.${var.domain_name}/v1/users",
      "https://v1.api.${var.domain_name}/users",
      "https://v2.api.${var.domain_name}/users",
      "https://docs.api.${var.domain_name}"
    ]
    blog_examples = [
      "https://blog.${var.domain_name}",
      "https://blog.${var.domain_name}/latest-post"
    ]
    staging_examples = [
      "https://staging.${var.domain_name}",
      "https://api.staging.${var.domain_name}",
      "https://db.staging.${var.domain_name}"
    ]
    dev_examples = [
      "https://dev.${var.domain_name}",
      "https://feature-branch.dev.${var.domain_name}"
    ]
  }
}
