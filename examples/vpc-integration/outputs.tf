# Outputs for VPC DNS integration

# VPC Information
output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

# DNS Zone Information
output "public_zone_id" {
  description = "Route 53 public hosted zone ID"
  value       = module.vpc_dns.public_zone_id
}

output "public_zone_name_servers" {
  description = "Name servers for the public domain"
  value       = module.vpc_dns.public_zone_name_servers
}

output "private_zone_id" {
  description = "Route 53 private hosted zone ID"
  value       = module.vpc_dns.private_zone_id
}

output "private_zone_name" {
  description = "Private domain name"
  value       = var.private_domain_name
}

# Load Balancer Information
output "load_balancer_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.web.dns_name
}

output "load_balancer_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.web.zone_id
}

# Instance Information
output "web_instances" {
  description = "Information about web server instances"
  value = {
    for i, instance in aws_instance.web : "web-${i + 1}" => {
      instance_id = instance.id
      private_ip  = instance.private_ip
      public_ip   = instance.public_ip
      dns_name    = "web-${i + 1}.${var.private_domain_name}"
    }
  }
}

output "database_instances" {
  description = "Information about database server instances"
  value = {
    for i, instance in aws_instance.database : "db-${i + 1}" => {
      instance_id = instance.id
      private_ip  = instance.private_ip
      dns_name    = i == 0 ? "db-primary.${var.private_domain_name}" : "db-replica.${var.private_domain_name}"
    }
  }
}

# DNS Records Summary
output "public_dns_records" {
  description = "Summary of public DNS records"
  value = {
    root_domain = "${var.public_domain_name} -> ${aws_lb.web.dns_name} (ALB alias)"
    www_domain  = "www.${var.public_domain_name} -> ${aws_lb.web.dns_name} (ALB alias)"
  }
}

output "private_dns_records" {
  description = "Summary of private DNS records"
  value = {
    web_servers = {
      for i, instance in aws_instance.web : "web-${i + 1}.${var.private_domain_name}" => instance.private_ip
    }
    database_servers = {
      for i, instance in aws_instance.database : (i == 0 ? "db-primary" : "db-replica") => "${i == 0 ? "db-primary" : "db-replica"}.${var.private_domain_name} -> ${instance.private_ip}"
    }
    service_aliases = {
      database = "database.${var.private_domain_name} -> db-primary.${var.private_domain_name}"
    }
  }
}

# Access Information
output "public_access_urls" {
  description = "URLs for public access"
  value = {
    website     = "http://${var.public_domain_name}"
    www_website = "http://www.${var.public_domain_name}"
    alb_direct  = "http://${aws_lb.web.dns_name}"
  }
}

output "private_access_info" {
  description = "Information for accessing private resources"
  value = {
    note = "Private resources can only be accessed from within the VPC"
    database_endpoint = "database.${var.private_domain_name}"
    web_servers = [
      for i in range(length(aws_instance.web)) : "web-${i + 1}.${var.private_domain_name}"
    ]
    database_servers = [
      for i in range(length(aws_instance.database)) : i == 0 ? "db-primary.${var.private_domain_name}" : "db-replica.${var.private_domain_name}"
    ]
  }
}

# Testing Information
output "dns_testing_commands" {
  description = "Commands to test DNS resolution"
  value = {
    public_dns = {
      test_root = "dig A ${var.public_domain_name}"
      test_www  = "dig A www.${var.public_domain_name}"
      test_ns   = "dig NS ${var.public_domain_name}"
    }
    private_dns = {
      note = "Run these commands from within the VPC (SSH to an instance)"
      test_database = "nslookup database.${var.private_domain_name}"
      test_web      = "nslookup web-1.${var.private_domain_name}"
      test_all      = "dig @169.254.169.253 ${var.private_domain_name} ANY"
    }
  }
}

# SSH Access Information
output "ssh_access_info" {
  description = "SSH access information for instances"
  value = var.key_name != null ? {
    web_servers = {
      for i, instance in aws_instance.web : "web-${i + 1}" => "ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${instance.public_ip}"
    }
    database_servers = {
      note = "Database servers are in private subnets - access via bastion or VPN"
      for i, instance in aws_instance.database : "db-${i + 1}" => "ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${instance.private_ip}"
    }
  } : {
    note = "No SSH key specified - instances are not accessible via SSH"
  }
}

# Health Check URLs
output "health_check_urls" {
  description = "Health check endpoints for monitoring"
  value = {
    load_balancer = "http://${aws_lb.web.dns_name}/health"
    web_servers = {
      for i, instance in aws_instance.web : "web-${i + 1}" => "http://${instance.public_ip}/health"
    }
    database_servers = {
      note = "Database servers are in private subnets"
      for i, instance in aws_instance.database : "db-${i + 1}" => "http://${instance.private_ip}/health"
    }
  }
}

# DNS Integration Demo URLs
output "dns_demo_urls" {
  description = "URLs to view DNS integration demonstrations"
  value = {
    public_demo = "http://${var.public_domain_name}"
    web_servers = {
      for i, instance in aws_instance.web : "web-${i + 1}" => "http://${instance.public_ip}"
    }
    dns_test_endpoints = {
      for i, instance in aws_instance.web : "web-${i + 1}" => "http://${instance.public_ip}/dns-test"
    }
  }
}
