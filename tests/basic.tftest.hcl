# Basic Terraform Tests for AWS DNS Module
# Tests core functionality without requiring actual AWS resources

run "validate_public_zone_configuration" {
  command = plan
  
  variables {
    domain_name = "example.com"
    public_zone_enabled = true
    private_zone_enabled = false
    tags = {
      Environment = "test"
      Owner       = "terraform-tests"
    }
  }
  
  assert {
    condition = aws_route53_zone.public[0].name == "example.com"
    error_message = "Public zone should be created with correct domain name"
  }
  
  assert {
    condition = length(aws_route53_zone.public[0].name_servers) == 4
    error_message = "Public zone should have 4 name servers"
  }
  
  assert {
    condition = aws_route53_zone.public[0].tags["Environment"] == "test"
    error_message = "Public zone should have correct environment tag"
  }
}

run "validate_private_zone_configuration" {
  command = plan
  
  variables {
    domain_name = "internal.example.com"
    public_zone_enabled = false
    private_zone_enabled = true
    vpc_id = "vpc-test123"
    vpc_region = "us-east-1"
    tags = {
      Environment = "test"
      Owner       = "terraform-tests"
    }
  }
  
  assert {
    condition = aws_route53_zone.private[0].name == "internal.example.com"
    error_message = "Private zone should be created with correct domain name"
  }
  
  assert {
    condition = aws_route53_zone.private[0].tags["Type"] == "private"
    error_message = "Private zone should have correct type tag"
  }
}

run "validate_dns_records_creation" {
  command = plan
  
  variables {
    domain_name = "records.example.com"
    public_zone_enabled = true
    private_zone_enabled = false
    public_records = {
      www = {
        name = "www"
        type = "A"
        ttl  = 300
        records = ["192.168.1.1"]
      }
      mail = {
        name = "mail"
        type = "MX"
        ttl  = 300
        records = ["10 mail.example.com."]
      }
    }
    tags = {
      Environment = "test"
    }
  }
  
  assert {
    condition = aws_route53_record.public["www"].name == "www.records.example.com"
    error_message = "WWW record should be created with correct name"
  }
  
  assert {
    condition = aws_route53_record.public["mail"].type == "MX"
    error_message = "Mail record should be created with correct type"
  }
  
  assert {
    condition = length(aws_route53_record.public) == 2
    error_message = "Should create exactly 2 public DNS records"
  }
}

run "validate_health_check_configuration" {
  command = plan
  
  variables {
    domain_name = "health.example.com"
    public_zone_enabled = true
    private_zone_enabled = false
    health_checks = {
      web_health = {
        fqdn              = "www.health.example.com"
        port              = 80
        type              = "HTTP"
        resource_path     = "/health"
        failure_threshold = 3
        request_interval  = 30
      }
    }
    tags = {
      Environment = "test"
    }
  }
  
  assert {
    condition = aws_route53_health_check.main["web_health"].fqdn == "www.health.example.com"
    error_message = "Health check should be created with correct FQDN"
  }
  
  assert {
    condition = aws_route53_health_check.main["web_health"].type == "HTTP"
    error_message = "Health check should be created with correct type"
  }
}

run "validate_resolver_endpoint_configuration" {
  command = plan
  
  variables {
    domain_name = "resolver.example.com"
    public_zone_enabled = true
    private_zone_enabled = false
    resolver_inbound_enabled = true
    resolver_inbound_name = "inbound-resolver"
    resolver_inbound_ip_addresses = [
      {
        subnet_id = "subnet-test123"
        ip        = "10.0.1.10"
      }
    ]
    resolver_security_group_ids = ["sg-test123"]
    tags = {
      Environment = "test"
    }
  }
  
  assert {
    condition = aws_route53_resolver_endpoint.inbound[0].name == "inbound-resolver"
    error_message = "Inbound resolver endpoint should be created with correct name"
  }
  
  assert {
    condition = aws_route53_resolver_endpoint.inbound[0].direction == "INBOUND"
    error_message = "Inbound resolver endpoint should have correct direction"
  }
}

run "validate_variable_validation" {
  command = plan
  
  variables {
    domain_name = "invalid-domain"  # This should trigger validation error
    public_zone_enabled = true
    private_zone_enabled = false
  }
  
  # This test should fail due to invalid domain name
  expect_failures = [
    aws_route53_zone.public
  ]
}

run "validate_outputs" {
  command = plan
  
  variables {
    domain_name = "outputs.example.com"
    public_zone_enabled = true
    private_zone_enabled = false
    public_records = {
      www = {
        name = "www"
        type = "A"
        ttl  = 300
        records = ["192.168.1.1"]
      }
    }
    tags = {
      Environment = "test"
    }
  }
  
  assert {
    condition = output.public_zone_id != null
    error_message = "Public zone ID output should be available"
  }
  
  assert {
    condition = output.public_zone_name == "outputs.example.com"
    error_message = "Public zone name output should be correct"
  }
  
  assert {
    condition = length(output.public_zone_name_servers) == 4
    error_message = "Public zone name servers output should have 4 servers"
  }
  
  assert {
    condition = length(output.public_records) == 1
    error_message = "Public records output should contain 1 record"
  }
} 