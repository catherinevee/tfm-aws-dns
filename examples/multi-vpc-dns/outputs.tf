# Multi-VPC DNS Integration Outputs

# VPC Information
output "vpc_information" {
  description = "Information about all created VPCs"
  value = {
    production = {
      id         = aws_vpc.production.id
      cidr_block = aws_vpc.production.cidr_block
      dns_support = aws_vpc.production.enable_dns_support
      dns_hostnames = aws_vpc.production.enable_dns_hostnames
    }
    development = {
      id         = aws_vpc.development.id
      cidr_block = aws_vpc.development.cidr_block
      dns_support = aws_vpc.development.enable_dns_support
      dns_hostnames = aws_vpc.development.enable_dns_hostnames
    }
    shared_services = {
      id         = aws_vpc.shared_services.id
      cidr_block = aws_vpc.shared_services.cidr_block
      dns_support = aws_vpc.shared_services.enable_dns_support
      dns_hostnames = aws_vpc.shared_services.enable_dns_hostnames
    }
  }
}

# VPC Peering Information
output "vpc_peering_connections" {
  description = "VPC peering connection details"
  value = {
    prod_to_shared = {
      id     = aws_vpc_peering_connection.prod_to_shared.id
      status = aws_vpc_peering_connection.prod_to_shared.accept_status
    }
    dev_to_shared = {
      id     = aws_vpc_peering_connection.dev_to_shared.id
      status = aws_vpc_peering_connection.dev_to_shared.accept_status
    }
    prod_to_dev = var.enable_cross_environment_peering ? {
      id     = aws_vpc_peering_connection.prod_to_dev[0].id
      status = aws_vpc_peering_connection.prod_to_dev[0].accept_status
    } : null
  }
}

# DNS Zone Information
output "dns_zone_information" {
  description = "Private DNS zone details"
  value = {
    zone_id      = module.multi_vpc_dns.private_zone_id
    domain_name  = var.shared_domain_name
    name_servers = module.multi_vpc_dns.private_zone_name_servers
    vpc_associations = [
      {
        vpc_id = aws_vpc.production.id
        name   = "production"
      },
      {
        vpc_id = aws_vpc.development.id
        name   = "development"
      },
      {
        vpc_id = aws_vpc.shared_services.id
        name   = "shared-services"
      }
    ]
  }
}

# Instance Information
output "production_instances" {
  description = "Production environment instance details"
  value = {
    for i, instance in aws_instance.production_app : "prod-app-${i + 1}" => {
      id         = instance.id
      private_ip = instance.private_ip
      subnet_id  = instance.subnet_id
      dns_name   = "prod-app-${i + 1}.${var.shared_domain_name}"
      health_url = "http://${instance.private_ip}/health"
    }
  }
}

output "development_instances" {
  description = "Development environment instance details"
  value = {
    for i, instance in aws_instance.development_app : "dev-app-${i + 1}" => {
      id         = instance.id
      private_ip = instance.private_ip
      subnet_id  = instance.subnet_id
      dns_name   = "dev-app-${i + 1}.${var.shared_domain_name}"
      health_url = "http://${instance.private_ip}/health"
    }
  }
}

output "shared_services_instances" {
  description = "Shared services instance details"
  value = {
    for i, instance in aws_instance.shared_services : "shared-${i + 1}" => {
      id         = instance.id
      private_ip = instance.private_ip
      subnet_id  = instance.subnet_id
      dns_name   = i == 0 ? "dns.${var.shared_domain_name}" : "monitoring.${var.shared_domain_name}"
      health_url = "http://${instance.private_ip}/health"
    }
  }
}

# DNS Records Summary
output "dns_records_summary" {
  description = "Summary of created DNS records"
  value = {
    domain = var.shared_domain_name
    records = {
      # Individual instance records
      production_apps = [
        for i in range(var.production_instance_count) : "prod-app-${i + 1}.${var.shared_domain_name}"
      ]
      development_apps = [
        for i in range(var.development_instance_count) : "dev-app-${i + 1}.${var.shared_domain_name}"
      ]
      shared_services = [
        "dns.${var.shared_domain_name}",
        length(aws_instance.shared_services) > 1 ? "monitoring.${var.shared_domain_name}" : null
      ]
      # Cluster records
      clusters = [
        "production.${var.shared_domain_name}",
        "development.${var.shared_domain_name}",
        "all-apps.${var.shared_domain_name}"
      ]
      # Configuration records
      config_records = [
        "_config.production.${var.shared_domain_name}",
        "_config.development.${var.shared_domain_name}",
        "_config.shared.${var.shared_domain_name}"
      ]
    }
  }
}

# Service Discovery Endpoints
output "service_discovery_endpoints" {
  description = "Service discovery endpoints for applications"
  value = {
    production_cluster  = "production.${var.shared_domain_name}"
    development_cluster = "development.${var.shared_domain_name}"
    dns_service        = "dns.${var.shared_domain_name}"
    monitoring_service = length(aws_instance.shared_services) > 1 ? "monitoring.${var.shared_domain_name}" : null
    all_applications   = "all-apps.${var.shared_domain_name}"
  }
}

# Access Information
output "access_information" {
  description = "Information for accessing and testing the multi-VPC setup"
  value = {
    ssh_commands = merge(
      var.key_name != null ? {
        for i, instance in aws_instance.production_app : "production_app_${i + 1}" => 
        "ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${instance.private_ip}"
      } : {},
      var.key_name != null ? {
        for i, instance in aws_instance.development_app : "development_app_${i + 1}" => 
        "ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${instance.private_ip}"
      } : {},
      var.key_name != null ? {
        for i, instance in aws_instance.shared_services : "shared_services_${i + 1}" => 
        "ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${instance.private_ip}"
      } : {}
    )
    
    web_interfaces = merge(
      {
        for i, instance in aws_instance.production_app : "production_app_${i + 1}" => 
        "http://${instance.private_ip}/"
      },
      {
        for i, instance in aws_instance.development_app : "development_app_${i + 1}" => 
        "http://${instance.private_ip}/"
      },
      {
        for i, instance in aws_instance.shared_services : "shared_services_${i + 1}" => 
        "http://${instance.private_ip}/"
      }
    )
    
    health_check_urls = merge(
      {
        for i, instance in aws_instance.production_app : "production_app_${i + 1}" => 
        "http://${instance.private_ip}/health"
      },
      {
        for i, instance in aws_instance.development_app : "development_app_${i + 1}" => 
        "http://${instance.private_ip}/health"
      },
      {
        for i, instance in aws_instance.shared_services : "shared_services_${i + 1}" => 
        "http://${instance.private_ip}/health"
      }
    )
  }
}

# DNS Testing Commands
output "dns_testing_commands" {
  description = "Commands for testing DNS resolution across VPCs"
  value = {
    basic_resolution_tests = [
      "nslookup production.${var.shared_domain_name}",
      "nslookup development.${var.shared_domain_name}",
      "nslookup dns.${var.shared_domain_name}",
      "nslookup all-apps.${var.shared_domain_name}"
    ]
    
    detailed_dns_queries = [
      "dig A production.${var.shared_domain_name} +short",
      "dig A development.${var.shared_domain_name} +short",
      "dig TXT _config.production.${var.shared_domain_name} +short",
      "dig TXT _config.development.${var.shared_domain_name} +short",
      "dig TXT _config.shared.${var.shared_domain_name} +short"
    ]
    
    connectivity_tests = [
      "curl -s http://production.${var.shared_domain_name}/health",
      "curl -s http://development.${var.shared_domain_name}/health",
      "curl -s http://dns.${var.shared_domain_name}/health"
    ]
    
    cross_vpc_tests = [
      "# From production instance:",
      "curl -s http://development.${var.shared_domain_name}/health",
      "curl -s http://dns.${var.shared_domain_name}/dns-status",
      "# From development instance:",
      "curl -s http://production.${var.shared_domain_name}/health",
      "curl -s http://dns.${var.shared_domain_name}/connectivity-matrix"
    ]
  }
}

# Monitoring and Troubleshooting
output "monitoring_information" {
  description = "Monitoring and troubleshooting information"
  value = {
    shared_services_dashboard = length(aws_instance.shared_services) > 0 ? 
      "http://${aws_instance.shared_services[0].private_ip}/" : null
    
    dns_monitoring_script = "/home/ec2-user/monitor-dns.sh"
    
    log_locations = {
      user_data_logs    = "/var/log/user-data.log"
      dns_monitoring    = "/var/log/dns-monitoring.log"
      apache_access     = "/var/log/httpd/access_log"
      apache_error      = "/var/log/httpd/error_log"
      dnsmasq_logs      = "/var/log/dnsmasq.log"
    }
    
    troubleshooting_commands = [
      "# Check VPC DNS settings:",
      "aws ec2 describe-vpcs --vpc-ids ${aws_vpc.production.id} --query 'Vpcs[0].{DnsSupport:DnsSupport,DnsHostnames:DnsHostnames}'",
      "# Check Route 53 private zone:",
      "aws route53 get-hosted-zone --id ${module.multi_vpc_dns.private_zone_id}",
      "# List DNS records:",
      "aws route53 list-resource-record-sets --hosted-zone-id ${module.multi_vpc_dns.private_zone_id}",
      "# Test DNS from instance:",
      "nslookup production.${var.shared_domain_name} 169.254.169.253"
    ]
  }
}

# Cost Information
output "cost_estimation" {
  description = "Estimated monthly costs for the multi-VPC setup"
  value = {
    vpc_costs = {
      vpcs                    = "Free (3 VPCs)"
      subnets                = "Free (${length(var.production_private_cidrs) + length(var.development_private_cidrs) + length(var.shared_services_private_cidrs)} subnets)"
      internet_gateways      = "Free (0 IGWs)"
      nat_gateways          = "Free (0 NAT Gateways)"
      vpc_peering           = "Free (${var.enable_cross_environment_peering ? 3 : 2} peering connections)"
    }
    
    compute_costs = {
      ec2_instances = "${var.production_instance_count + var.development_instance_count + var.shared_services_instance_count} × ${var.instance_type} instances"
      estimated_monthly = var.instance_type == "t3.micro" ? 
        "$${(var.production_instance_count + var.development_instance_count + var.shared_services_instance_count) * 8.5}" :
        "Varies by instance type"
    }
    
    dns_costs = {
      private_hosted_zone = "$0.50/month"
      dns_queries        = "Minimal for internal queries"
      estimated_monthly  = "$0.50 - $1.00"
    }
    
    total_estimated_monthly = var.instance_type == "t3.micro" ? 
      "$${(var.production_instance_count + var.development_instance_count + var.shared_services_instance_count) * 8.5 + 1}" :
      "Varies by instance type + $1 for DNS"
  }
}

# Next Steps
output "next_steps" {
  description = "Recommended next steps after deployment"
  value = [
    "1. Test DNS resolution from each VPC using the provided testing commands",
    "2. Verify cross-VPC connectivity using the health check endpoints",
    "3. Review the shared services dashboard for multi-VPC status",
    "4. Set up monitoring and alerting for DNS resolution failures",
    "5. Configure application-specific DNS records as needed",
    "6. Implement SSL/TLS certificates for HTTPS communication",
    "7. Set up centralized logging for DNS queries and application logs",
    "8. Consider implementing DNS-based load balancing for high availability",
    "9. Document service discovery patterns for development teams",
    "10. Plan for disaster recovery and backup strategies"
  ]
}
