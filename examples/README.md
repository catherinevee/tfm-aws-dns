# AWS DNS Terraform Module Examples

This directory contains various examples demonstrating different use cases and configurations for the AWS DNS Terraform module. Each example is self-contained and includes detailed documentation.

## Available Examples

### Basic Examples

#### 1. [minimal/](./minimal/)
**Absolute minimal DNS zone configuration**
- Single public hosted zone with no records
- Perfect for testing the module or learning Route 53
- Just creates the zone - you add records later
- Cost: $0.50/month

#### 2. [simple-records/](./simple-records/)
**Basic DNS record types demonstration**
- A, CNAME, MX, and TXT records
- Typical website and email setup
- SPF and DMARC email security records
- Domain verification examples

#### 3. [alias-records/](./alias-records/)
**Route 53 alias records for AWS resources**
- Alias records to ALB, CloudFront, API Gateway
- Cost-effective DNS for AWS services
- Health check integration
- Mixed alias and regular records

#### 4. [simple-private/](./simple-private/)
**Private DNS zone for internal services**
- VPC-based private DNS resolution
- Internal service discovery patterns
- Database, cache, and API endpoints
- Microservices architecture support

#### 5. [subdomain-delegation/](./subdomain-delegation/)
**Subdomain delegation to other zones**
- Team-based DNS management
- Service-specific subdomain zones
- External service integration
- Organizational DNS structure

### Advanced Examples

#### 6. [basic-public/](./basic-public/)
**Standard public DNS configuration**
- Comprehensive public zone setup
- Multiple record types and routing policies
- Production-ready configuration

#### 7. [private-vpc/](./private-vpc/)
**Advanced private DNS with VPC associations**
- Multi-VPC private DNS setup
- Cross-VPC DNS resolution
- Advanced private zone configurations

#### 8. [hybrid-resolver/](./hybrid-resolver/)
**Route 53 Resolver for hybrid DNS**
- On-premises DNS integration
- Inbound and outbound resolver endpoints
- Hybrid cloud DNS architecture

#### 9. [comprehensive/](./comprehensive/)
**Full-featured example with all capabilities**
- All DNS features demonstrated
- Advanced routing policies
- Health checks and monitoring
- Production-ready with best practices

#### 10. [complete/](./complete/)
**Complete DNS solution**
- Public and private zones
- Advanced configurations
- Enterprise-ready setup

## Quick Start Guide

### 1. Choose Your Example
Select the example that best matches your use case:
- **Learning/Testing**: Start with `minimal/`
- **Basic Website**: Use `simple-records/`
- **AWS Resources**: Try `alias-records/`
- **Internal Services**: Use `simple-private/`
- **Team Management**: Try `subdomain-delegation/`
- **Production Setup**: Consider `comprehensive/`

### 2. Deploy an Example
```bash
# Navigate to your chosen example
cd examples/simple-records/

# Initialize Terraform
terraform init

# Review the plan
terraform plan -var="domain_name=yourdomain.com"

# Deploy the DNS configuration
terraform apply -var="domain_name=yourdomain.com"
```

### 3. Update Domain Registrar
Configure the nameservers from the Terraform output with your domain registrar.

### 4. Clean Up
```bash
# Destroy the DNS infrastructure when done
terraform destroy
```

## Example Comparison

| Example | Public Zone | Private Zone | Alias Records | Delegation | Health Checks | Complexity |
|---------|-------------|--------------|---------------|------------|---------------|------------|
| minimal | ✅ | ❌ | ❌ | ❌ | ❌ | ⭐ |
| simple-records | ✅ | ❌ | ❌ | ❌ | ❌ | ⭐⭐ |
| alias-records | ✅ | ❌ | ✅ | ❌ | ✅ | ⭐⭐ |
| simple-private | ❌ | ✅ | ❌ | ❌ | ❌ | ⭐⭐ |
| subdomain-delegation | ✅ | ❌ | ❌ | ✅ | ❌ | ⭐⭐⭐ |
| basic-public | ✅ | ❌ | ✅ | ❌ | ✅ | ⭐⭐⭐ |
| private-vpc | ❌ | ✅ | ❌ | ❌ | ❌ | ⭐⭐⭐ |
| hybrid-resolver | ✅ | ✅ | ❌ | ❌ | ✅ | ⭐⭐⭐⭐ |
| comprehensive | ✅ | ✅ | ✅ | ✅ | ✅ | ⭐⭐⭐⭐⭐ |
| complete | ✅ | ✅ | ✅ | ✅ | ✅ | ⭐⭐⭐⭐⭐ |

## Common Configuration Patterns

### Domain Name
All examples support custom domain names:
```bash
terraform apply -var="domain_name=yourdomain.com"
```

### AWS Region
Deploy to different AWS regions:
```bash
terraform apply -var="aws_region=us-east-1"
```

### IP Addresses
Customize server IP addresses:
```bash
terraform apply -var="web_server_ip=203.0.113.1"
```

## DNS Record Types Covered

### Basic Records
- **A Records**: IPv4 address mapping
- **AAAA Records**: IPv6 address mapping
- **CNAME Records**: Canonical name aliases
- **MX Records**: Mail exchange routing
- **TXT Records**: Text information and verification

### Advanced Records
- **Alias Records**: AWS resource aliases (cost-effective)
- **NS Records**: Subdomain delegation
- **SRV Records**: Service location
- **PTR Records**: Reverse DNS lookup

### Routing Policies
- **Simple**: Basic DNS resolution
- **Weighted**: Traffic distribution by weight
- **Latency**: Route to lowest latency endpoint
- **Failover**: Active-passive failover
- **Geolocation**: Route by user location
- **Multivalue**: Multiple IP addresses with health checks

## Use Case Examples

### Personal Website
```bash
cd examples/simple-records/
terraform apply -var="domain_name=johnsmith.com"
```

### Business with API
```bash
cd examples/alias-records/
terraform apply \
  -var="domain_name=mycompany.com" \
  -var="load_balancer_name=my-alb"
```

### Microservices Architecture
```bash
cd examples/simple-private/
terraform apply -var="domain_name=internal.mycompany.com"
```

### Multi-Team Organization
```bash
cd examples/subdomain-delegation/
terraform apply -var="domain_name=mycompany.com"
```

### Hybrid Cloud Setup
```bash
cd examples/hybrid-resolver/
terraform apply -var="domain_name=mycompany.com"
```

## Prerequisites

Before using any example, ensure you have:

1. **AWS CLI configured** with appropriate credentials
2. **Terraform installed** (version >= 1.0)
3. **Domain registered** (for public zones)
4. **Route 53 permissions** for creating hosted zones and records
5. **VPC access** (for private zone examples)

## Cost Considerations

### Route 53 Pricing
- **Hosted Zone**: $0.50/month per zone
- **DNS Queries**: $0.40 per million queries (first billion/month)
- **Health Checks**: $0.50/month per health check
- **Alias Queries**: Free for AWS resources

### Example Costs (Monthly)
- **minimal**: $0.50 (zone only)
- **simple-records**: $0.50 (zone + free queries)
- **alias-records**: $0.50 (zone + free alias queries)
- **simple-private**: $0.50 (zone + free private queries)
- **comprehensive**: $0.50 + health check costs

## Security Best Practices

### Public Zones
1. **Domain Verification**: Verify domain ownership before creating zones
2. **Access Control**: Use IAM policies to control DNS modifications
3. **Monitoring**: Enable CloudTrail for DNS change auditing
4. **DNSSEC**: Consider enabling DNSSEC for additional security

### Private Zones
1. **VPC Isolation**: Associate zones only with necessary VPCs
2. **Network Security**: Use security groups and NACLs appropriately
3. **Access Logging**: Enable VPC Flow Logs for DNS query monitoring
4. **Least Privilege**: Grant minimal necessary DNS permissions

## Troubleshooting

### Common Issues

#### DNS Not Resolving
```bash
# Check nameserver configuration
dig NS yourdomain.com

# Test specific nameserver
dig @ns-123.awsdns-12.com yourdomain.com

# Check propagation
dig yourdomain.com +trace
```

#### Private DNS Not Working
```bash
# Test from within VPC
nslookup internal.domain.local

# Check VPC DNS settings
aws ec2 describe-vpcs --vpc-ids vpc-12345678
```

#### Delegation Issues
```bash
# Check delegation records
dig NS subdomain.yourdomain.com

# Test delegated resolution
dig A subdomain.yourdomain.com
```

### Getting Help

1. **Check example README**: Each example has detailed troubleshooting
2. **Review AWS documentation**: Route 53 developer guide
3. **Use AWS CLI**: Debug with Route 53 CLI commands
4. **Check CloudWatch**: Monitor DNS query metrics

## Module Features Demonstrated

Each example demonstrates different aspects of the DNS module:

### Zone Management
- **Public Zones**: Internet-accessible DNS resolution
- **Private Zones**: VPC-internal DNS resolution
- **Zone Associations**: Multi-VPC private zone access

### Record Management
- **Basic Records**: A, CNAME, MX, TXT record types
- **Alias Records**: Cost-effective AWS resource aliases
- **Advanced Routing**: Weighted, latency, geolocation policies

### Integration Features
- **Health Checks**: Endpoint monitoring and failover
- **AWS Resources**: ALB, CloudFront, API Gateway integration
- **Hybrid DNS**: On-premises DNS integration

### Operational Features
- **Monitoring**: CloudWatch metrics and alarms
- **Logging**: DNS query logging and analysis
- **Security**: DNSSEC and access control

## Contributing

When adding new DNS examples:

1. **Create a new directory** under `examples/`
2. **Include all required files**:
   - `main.tf` - Terraform configuration
   - `variables.tf` - Input variables
   - `outputs.tf` - Output values
   - `README.md` - Documentation
3. **Follow naming conventions** and coding standards
4. **Test thoroughly** with real domains
5. **Update this README** with the new example

## Next Steps

After deploying an example:

1. **Configure Domain Registrar**: Update nameservers
2. **Verify DNS Resolution**: Test with dig/nslookup
3. **Monitor Performance**: Set up CloudWatch alarms
4. **Plan Scaling**: Consider additional zones or records
5. **Implement Security**: Enable logging and monitoring

Choose the examples that best demonstrate the DNS features you need for your infrastructure.
