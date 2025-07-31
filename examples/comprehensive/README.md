# Comprehensive DNS Example - Maximum Customizability

This example demonstrates the extensive customization capabilities of the enhanced AWS DNS Terraform module, showcasing all available parameters, advanced routing policies, and hybrid DNS features.

## Features Demonstrated

### 🌐 **Public Hosted Zone Features**
- **Advanced Routing Policies**: Weighted, latency-based, geolocation, failover, and multivalue routing
- **Alias Records**: CloudFront integration with health check evaluation
- **Custom TTL Values**: Optimized for different record types and use cases
- **Split-Horizon DNS**: VPC associations for internal queries to public zones
- **Comprehensive Record Types**: A, AAAA, CNAME, MX, TXT, SRV support

### 🔒 **Private Hosted Zone Features**
- **VPC Integration**: Single and multi-VPC associations
- **Cross-Region Support**: VPC associations across AWS regions
- **Internal Service Discovery**: Database, API, and load balancer endpoints
- **Separate Domain Support**: Different domains for public and private zones

### 🔄 **Route 53 Resolver (Hybrid DNS)**
- **Inbound Endpoints**: Allow on-premises queries to AWS DNS
- **Outbound Endpoints**: Forward AWS queries to on-premises DNS
- **Conditional Forwarding**: Domain-specific routing rules
- **Security Group Integration**: Network-level access control

### 📊 **Health Checks and Monitoring**
- **Multi-Protocol Support**: HTTP, HTTPS, TCP health checks
- **Custom Health Paths**: Application-specific health endpoints
- **CloudWatch Integration**: Logging and metrics collection
- **Latency Measurement**: Performance monitoring capabilities

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Internet                                  │
└─────────────────────┬───────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────┐
│                Public Hosted Zone                               │
│  • Weighted Routing (A/B Testing)                              │
│  • Latency Routing (Global Apps)                               │
│  • Geolocation Routing (Compliance)                            │
│  • Failover Routing (High Availability)                        │
│  • Health Checks Integration                                    │
└─────────────────────┬───────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────┐
│                     VPC                                         │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              Private Hosted Zone                        │   │
│  │  • Internal Service Discovery                           │   │
│  │  • Database Endpoints                                   │   │
│  │  • Load Balancer Integration                            │   │
│  └─────────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │            Resolver Endpoints                           │   │
│  │  • Inbound: On-prem → AWS                              │   │
│  │  • Outbound: AWS → On-prem                             │   │
│  │  • Security Group Protected                             │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────┬───────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────┐
│                On-Premises Network                              │
│  • Corporate DNS Servers                                        │
│  • Internal Domain Resolution                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Usage Examples

### Basic Public Zone

```hcl
module "dns_basic" {
  source = "../../"
  
  domain_name         = "example.com"
  public_zone_enabled = true
  
  public_records = {
    "www" = {
      name    = "www.example.com"
      type    = "A"
      ttl     = 300
      records = ["203.0.113.1"]
    }
  }
}
```

### Advanced Routing Policies

```hcl
module "dns_advanced" {
  source = "../../"
  
  domain_name = "example.com"
  
  public_records = {
    # Weighted routing for A/B testing
    "api-v1" = {
      name = "api.example.com"
      type = "A"
      ttl  = 60
      records = ["203.0.113.10"]
      weighted_routing_policy = {
        weight = 80  # 80% traffic
      }
      set_identifier = "v1"
    }
    
    "api-v2" = {
      name = "api.example.com"
      type = "A"
      ttl  = 60
      records = ["203.0.113.11"]
      weighted_routing_policy = {
        weight = 20  # 20% traffic
      }
      set_identifier = "v2"
    }
    
    # Failover routing for high availability
    "service-primary" = {
      name = "service.example.com"
      type = "A"
      ttl  = 60
      records = ["203.0.113.20"]
      failover_routing_policy = {
        type = "PRIMARY"
      }
      set_identifier  = "primary"
      health_check_id = aws_route53_health_check.primary.id
    }
    
    "service-secondary" = {
      name = "service.example.com"
      type = "A"
      ttl  = 60
      records = ["203.0.113.21"]
      failover_routing_policy = {
        type = "SECONDARY"
      }
      set_identifier = "secondary"
    }
  }
}
```

### Private Zone with VPC Integration

```hcl
module "dns_private" {
  source = "../../"
  
  domain_name          = "example.com"
  private_zone_enabled = true
  private_domain_name  = "internal.example.com"
  
  vpc_id     = "vpc-12345678"
  vpc_region = "us-west-2"
  
  private_records = {
    "api" = {
      name = "api.internal.example.com"
      type = "A"
      ttl  = 300
      records = ["10.0.1.10"]
    }
    
    "db" = {
      name = "db.internal.example.com"
      type = "CNAME"
      ttl  = 300
      records = ["rds-cluster.cluster-xyz.us-west-2.rds.amazonaws.com"]
    }
  }
}
```

### Hybrid DNS with Resolver Endpoints

```hcl
module "dns_hybrid" {
  source = "../../"
  
  domain_name = "example.com"
  
  # Resolver endpoints
  resolver_inbound_enabled  = true
  resolver_outbound_enabled = true
  
  resolver_security_group_ids = [aws_security_group.dns.id]
  
  resolver_inbound_ip_addresses = [
    {
      subnet_id = "subnet-12345678"
      ip        = "10.0.1.100"
    }
  ]
  
  resolver_outbound_ip_addresses = [
    {
      subnet_id = "subnet-12345678"
      ip        = "10.0.1.101"
    }
  ]
  
  # Forward corporate domain to on-premises DNS
  resolver_rules = {
    "corp-domain" = {
      domain_name = "corp.example.com"
      name        = "corp-forwarding-rule"
      rule_type   = "FORWARD"
      target_ips = [
        {
          ip   = "192.168.1.10"
          port = 53
        }
      ]
    }
  }
}
```

## Variables

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `domain_name` | Primary domain name | `string` | `"example.com"` | yes |
| `enable_public_zone` | Enable public hosted zone | `bool` | `true` | no |
| `enable_private_zone` | Enable private hosted zone | `bool` | `true` | no |
| `enable_resolver_endpoints` | Enable resolver endpoints | `bool` | `false` | no |
| `enable_health_checks` | Enable health checks | `bool` | `false` | no |
| `vpc_name` | VPC name for private zone | `string` | `"main-vpc"` | no |

See [variables.tf](./variables.tf) for the complete list of configurable parameters.

## Routing Policies Explained

### 1. **Simple Routing**
- Basic DNS resolution with single or multiple values
- No health checks or traffic distribution
- Best for: Basic websites, simple applications

### 2. **Weighted Routing**
- Distributes traffic based on assigned weights (0-255)
- Useful for A/B testing and gradual deployments
- Best for: Canary deployments, load distribution

### 3. **Latency-Based Routing**
- Routes to the region with lowest latency
- Requires resources in multiple regions
- Best for: Global applications, performance optimization

### 4. **Geolocation Routing**
- Routes based on user's geographic location
- Supports continent, country, and subdivision targeting
- Best for: Compliance requirements, localization

### 5. **Failover Routing**
- Active-passive failover configuration
- Requires health checks for primary resource
- Best for: High availability, disaster recovery

### 6. **Multivalue Answer Routing**
- Returns multiple healthy records
- Each record can have its own health check
- Best for: Load distribution, simple load balancing

## Security Best Practices

### 🔐 **Network Security**
- Resolver endpoints protected by security groups
- VPC-level isolation for private zones
- Least privilege access for DNS queries

### 🛡️ **Access Control**
- IAM policies for Route 53 management
- Resource-based policies for cross-account access
- CloudTrail logging for DNS API calls

### 🔒 **Monitoring and Alerting**
- Health check monitoring with CloudWatch
- DNS query logging for security analysis
- Automated failover with health checks

## Cost Optimization

### 💰 **DNS Query Costs**
- Public zones: $0.40 per million queries
- Private zones: $0.40 per million queries
- Health checks: $0.50 per month per check

### ⚡ **Resolver Endpoint Costs**
- Inbound endpoints: $0.125 per hour per endpoint
- Outbound endpoints: $0.125 per hour per endpoint
- Data processing: $0.40 per million queries

### 📊 **Optimization Tips**
- Use appropriate TTL values to reduce query volume
- Implement health checks only where necessary
- Consider reusable delegation sets for multiple zones

## Deployment

1. **Prerequisites**:
   ```bash
   # Ensure AWS CLI is configured
   aws configure
   
   # Verify Terraform installation
   terraform version
   ```

2. **Initialize and Plan**:
   ```bash
   terraform init
   terraform plan -var="domain_name=yourdomain.com"
   ```

3. **Deploy**:
   ```bash
   terraform apply -var="domain_name=yourdomain.com"
   ```

4. **Test DNS Resolution**:
   ```bash
   # Test public zone
   dig @8.8.8.8 yourdomain.com NS
   
   # Test private zone (from within VPC)
   dig @10.0.1.100 internal.yourdomain.com A
   ```

## Troubleshooting

### Common Issues

1. **Private Zone Not Resolving**:
   - Verify VPC association is correct
   - Check VPC DNS resolution and DNS hostnames are enabled
   - Ensure queries are coming from associated VPC

2. **Health Check Failures**:
   - Verify target resource is accessible
   - Check security groups allow health check traffic
   - Review health check configuration (path, port, protocol)

3. **Resolver Endpoint Issues**:
   - Verify security groups allow DNS traffic (port 53)
   - Check subnet routing and network ACLs
   - Ensure IP addresses are available in specified subnets

### Support Resources

- [AWS Route 53 Documentation](https://docs.aws.amazon.com/route53/)
- [Route 53 Resolver Documentation](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resolver.html)
- [DNS Best Practices](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/best-practices-dns.html)

## License

This example is provided under the same license as the main DNS module.
