# AWS DNS Terraform Module

A comprehensive Terraform module for managing AWS DNS solutions that meet public, private, and hybrid requirements using Amazon Route 53.

## Features

- **Public DNS**: Route 53 public hosted zones with advanced routing policies
- **Private DNS**: Route 53 private hosted zones with VPC associations
- **Hybrid DNS**: Route 53 Resolver endpoints and rules for on-premises integration
- **Health Checks**: Configurable health monitoring for DNS records
- **Security**: Best practices with encryption and proper access controls
- **Flexibility**: Comprehensive variable validation and multiple configuration options

## Architecture

This module supports three primary DNS scenarios:

### 1. Public DNS
- Public hosted zones for internet-facing domains
- Support for multiple record types (A, AAAA, CNAME, MX, TXT, etc.)
- Advanced routing policies (weighted, latency-based, geolocation, failover)
- Health checks for high availability

### 2. Private DNS
- Private hosted zones for internal domain resolution
- VPC associations for secure internal DNS
- Support for multiple VPC associations across regions
- Private DNS records for internal services

### 3. Hybrid DNS
- Route 53 Resolver endpoints (inbound/outbound)
- Conditional forwarding rules for on-premises integration
- Secure DNS resolution between AWS and on-premises networks

## Usage

### Basic Public DNS

```hcl
module "public_dns" {
  source = "./tfm-aws-dns"

  domain_name         = "example.com"
  public_zone_enabled = true

  public_records = {
    www = {
      name    = "www"
      type    = "A"
      ttl     = 300
      records = ["192.0.2.1"]
    }
    mail = {
      name    = "mail"
      type    = "MX"
      ttl     = 300
      records = ["10 mail.example.com"]
    }
  }

  tags = {
    Environment = "production"
    Project     = "web-infrastructure"
  }
}
```

### Private DNS with VPC Association

```hcl
module "private_dns" {
  source = "./tfm-aws-dns"

  domain_name          = "internal.example.com"
  private_zone_enabled = true
  vpc_id               = "vpc-12345678"
  vpc_region           = "us-east-1"

  private_records = {
    api = {
      name    = "api"
      type    = "A"
      ttl     = 300
      records = ["10.0.1.100"]
    }
    database = {
      name    = "db"
      type    = "CNAME"
      ttl     = 300
      records = ["rds-instance.us-east-1.rds.amazonaws.com"]
    }
  }

  tags = {
    Environment = "production"
    Type        = "private-dns"
  }
}
```

### Hybrid DNS with Resolver

```hcl
module "hybrid_dns" {
  source = "./tfm-aws-dns"

  domain_name              = "example.com"
  public_zone_enabled      = true
  resolver_outbound_enabled = true

  resolver_outbound_name = "corporate-resolver"
  resolver_security_group_ids = ["sg-12345678"]

  resolver_outbound_ip_addresses = [
    {
      subnet_id = "subnet-12345678"
      ip        = "10.0.1.10"
    },
    {
      subnet_id = "subnet-87654321"
      ip        = "10.0.2.10"
    }
  ]

  resolver_rules = {
    corporate = {
      domain_name = "corp.example.com"
      name        = "corporate-forward-rule"
      rule_type   = "FORWARD"
      target_ips = [
        {
          ip   = "192.168.1.10"
          port = 53
        },
        {
          ip   = "192.168.1.11"
          port = 53
        }
      ]
    }
  }

  resolver_rule_associations = {
    main_vpc = {
      rule_key = "corporate"
      vpc_id   = "vpc-12345678"
    }
  }

  tags = {
    Environment = "production"
    Type        = "hybrid-dns"
  }
}
```

### Complete Example with Health Checks

```hcl
module "complete_dns" {
  source = "./tfm-aws-dns"

  domain_name         = "example.com"
  public_zone_enabled = true

  public_records = {
    primary = {
      name               = "www"
      type               = "A"
      ttl                = 60
      records            = ["192.0.2.1"]
      set_identifier     = "primary"
      health_check_id    = module.complete_dns.health_checks["primary"].id
      failover_routing_policy = {
        type = "PRIMARY"
      }
    }
    secondary = {
      name               = "www"
      type               = "A"
      ttl                = 60
      records            = ["192.0.2.2"]
      set_identifier     = "secondary"
      failover_routing_policy = {
        type = "SECONDARY"
      }
    }
  }

  health_checks = {
    primary = {
      fqdn                     = "www.example.com"
      port                     = 443
      type                     = "HTTPS"
      resource_path            = "/health"
      failure_threshold        = 3
      request_interval         = 30
      measure_latency          = true
      enable_sni               = true
    }
  }

  tags = {
    Environment = "production"
    Project     = "web-infrastructure"
    Backup      = "enabled"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| domain_name | The domain name for the hosted zone | `string` | n/a | yes |
| public_zone_enabled | Whether to create a public hosted zone | `bool` | `true` | no |
| private_zone_enabled | Whether to create a private hosted zone | `bool` | `false` | no |
| vpc_id | The VPC ID to associate with the private hosted zone | `string` | `null` | no |
| vpc_region | The VPC region for VPC associations | `string` | `null` | no |
| public_records | DNS records for the public hosted zone | `map(object)` | `{}` | no |
| private_records | DNS records for the private hosted zone | `map(object)` | `{}` | no |
| resolver_inbound_enabled | Whether to create an inbound Route 53 resolver endpoint | `bool` | `false` | no |
| resolver_outbound_enabled | Whether to create an outbound Route 53 resolver endpoint | `bool` | `false` | no |
| resolver_rules | Route 53 resolver rules for forwarding DNS queries | `map(object)` | `{}` | no |
| health_checks | Route 53 health checks | `map(object)` | `{}` | no |
| tags | A map of tags to assign to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| public_zone_id | The hosted zone ID of the public zone |
| public_zone_name_servers | A list of name servers in associated delegation set |
| private_zone_id | The hosted zone ID of the private zone |
| resolver_inbound_endpoint_id | The ID of the inbound resolver endpoint |
| resolver_outbound_endpoint_id | The ID of the outbound resolver endpoint |
| resolver_rules | Map of resolver rules created |
| health_checks | Map of health checks created |
| dns_configuration | Complete DNS configuration summary |

## Examples

- [Basic Public DNS](./examples/basic-public/)
- [Private DNS with VPC](./examples/private-vpc/)
- [Hybrid DNS with Resolver](./examples/hybrid-resolver/)
- [Complete Multi-Zone Setup](./examples/complete/)

## Security Considerations

1. **VPC Associations**: Private zones are automatically associated with specified VPCs
2. **Resolver Security Groups**: Configure appropriate security groups for resolver endpoints
3. **Health Check Encryption**: Enable SNI for HTTPS health checks
4. **State Management**: Use encrypted S3 backend with DynamoDB locking
5. **Access Control**: Implement least-privilege IAM policies

## Best Practices

1. **Tagging Strategy**: Use consistent tagging across all DNS resources
2. **Health Checks**: Implement health checks for critical public records
3. **TTL Values**: Use appropriate TTL values based on change frequency
4. **Monitoring**: Set up CloudWatch alarms for health check failures
5. **Backup**: Document name server configurations for disaster recovery

## Troubleshooting

### Common Issues

1. **VPC Association Failures**
   - Ensure VPC exists in the specified region
   - Check VPC permissions and enableDnsHostnames/enableDnsSupport

2. **Resolver Endpoint Creation**
   - Verify security group allows DNS traffic (port 53)
   - Ensure subnets are in different AZs for high availability

3. **Health Check Failures**
   - Verify target endpoint is accessible
   - Check security groups allow health check traffic

### Validation Commands

```bash
# Validate Terraform configuration
terraform validate

# Format code
terraform fmt -recursive

# Plan deployment
terraform plan

# Check DNS resolution
nslookup example.com
dig @8.8.8.8 example.com
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Run `terraform fmt` and `terraform validate`
4. Submit a pull request with tests

## License

This module is licensed under the MIT License. See LICENSE file for details.

## Support

For issues and questions:
- Create an issue in the repository
- Review the troubleshooting section
- Check AWS Route 53 documentation
