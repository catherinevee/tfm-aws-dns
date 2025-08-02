# Multi-VPC DNS Integration Example

This example demonstrates comprehensive DNS integration across multiple VPCs using Route 53 private zones, VPC peering, and cross-VPC service discovery. It creates a realistic enterprise scenario with production, development, and shared services environments.

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Production VPC │    │ Development VPC │    │Shared Services  │
│   10.0.0.0/16   │    │   10.1.0.0/16   │    │VPC 10.2.0.0/16 │
│                 │    │                 │    │                 │
│ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │   App-1     │ │    │ │   App-1     │ │    │ │ DNS Service │ │
│ │   App-2     │ │    │ │   App-2     │ │    │ │ Monitoring  │ │
│ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────┘ │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────────────┐
                    │   Route 53 Private Zone │
                    │  internal.company.local │
                    │                         │
                    │ • production.domain     │
                    │ • development.domain    │
                    │ • dns.domain           │
                    │ • monitoring.domain    │
                    │ • all-apps.domain      │
                    └─────────────────────────┘
```

## What This Creates

### Infrastructure Components
- **3 VPCs**: Production, Development, and Shared Services
- **VPC Peering**: Hub-and-spoke model with shared services as hub
- **Private Subnets**: Multi-AZ deployment across all VPCs
- **EC2 Instances**: Application servers and shared services
- **Security Groups**: Environment-specific access controls

### DNS Integration
- **Private Route 53 Zone**: Shared across all VPCs for service discovery
- **Cross-VPC Resolution**: Applications can discover services in other VPCs
- **Service Clustering**: Load balancing through DNS with multiple A records
- **Configuration Records**: TXT records for environment metadata

### Service Discovery Patterns
- **Individual Services**: `prod-app-1.internal.company.local`
- **Environment Clusters**: `production.internal.company.local`
- **Shared Services**: `dns.internal.company.local`, `monitoring.internal.company.local`
- **Global Discovery**: `all-apps.internal.company.local`

## Use Cases

### Enterprise Multi-Environment Setup
- **Production**: Critical workloads with strict access controls
- **Development**: Testing and development with relaxed policies
- **Shared Services**: DNS, monitoring, logging, and security services

### Microservices Architecture
- **Service Discovery**: Applications find dependencies using DNS names
- **Environment Isolation**: Production and development are network-isolated
- **Shared Infrastructure**: Common services accessible from all environments

### Hybrid Cloud Integration
- **On-Premises Extension**: Shared services VPC can connect to on-premises
- **Centralized DNS**: Single source of truth for service discovery
- **Scalable Architecture**: Easy to add new VPCs and services

## Quick Start

### Prerequisites
```bash
# AWS CLI configured with appropriate permissions
aws configure list

# Terraform installed (>= 1.0)
terraform version

# Optional: SSH key pair for instance access
aws ec2 create-key-pair --key-name my-multi-vpc-key --query 'KeyMaterial' --output text > ~/.ssh/my-multi-vpc-key.pem
chmod 400 ~/.ssh/my-multi-vpc-key.pem
```

### Basic Deployment
```bash
# Clone and navigate to example
cd examples/multi-vpc-dns

# Initialize Terraform
terraform init

# Plan deployment
terraform plan \
  -var="shared_domain_name=internal.mycompany.local" \
  -var="key_name=my-multi-vpc-key"

# Deploy infrastructure
terraform apply
```

### Custom Configuration
Create `terraform.tfvars`:
```hcl
# Environment Configuration
environment    = "enterprise-demo"
project_name   = "multi-vpc-dns"
owner         = "platform-team"
cost_center   = "engineering"

# DNS Configuration
shared_domain_name = "internal.mycompany.local"
dns_ttl_default   = 300
dns_ttl_short     = 60

# VPC Configuration
production_vpc_cidr      = "10.10.0.0/16"
development_vpc_cidr     = "10.20.0.0/16"
shared_services_vpc_cidr = "10.30.0.0/16"

production_private_cidrs      = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
development_private_cidrs     = ["10.20.1.0/24", "10.20.2.0/24"]
shared_services_private_cidrs = ["10.30.1.0/24", "10.30.2.0/24"]

# Instance Configuration
instance_type                    = "t3.small"
production_instance_count        = 3
development_instance_count       = 2
shared_services_instance_count   = 2

# Peering Configuration
enable_cross_environment_peering = true

# SSH Access
key_name = "my-multi-vpc-key"

# Advanced Options
enable_dns_logging    = true
enable_vpc_flow_logs  = true
```

## DNS Resolution Examples

### Service Discovery Patterns
```bash
# Resolve production cluster (returns multiple IPs)
nslookup production.internal.mycompany.local
# Output: 10.10.1.100, 10.10.2.100, 10.10.3.100

# Resolve development cluster
nslookup development.internal.mycompany.local
# Output: 10.20.1.100, 10.20.2.100

# Resolve shared services
nslookup dns.internal.mycompany.local
# Output: 10.30.1.100

nslookup monitoring.internal.mycompany.local
# Output: 10.30.2.100

# Resolve all applications (cross-environment)
nslookup all-apps.internal.mycompany.local
# Output: All production and development IPs
```

### Configuration Discovery
```bash
# Get environment metadata
dig TXT _config.production.internal.mycompany.local +short
# Output: "env=production" "vpc=vpc-12345" "region=us-west-2"

dig TXT _config.development.internal.mycompany.local +short
# Output: "env=development" "vpc=vpc-67890" "region=us-west-2"

dig TXT _config.shared.internal.mycompany.local +short
# Output: "env=shared" "vpc=vpc-abcde" "region=us-west-2"
```

## Application Integration

### Database Connection Example
```python
# Python application using DNS-based service discovery
import socket
import random

def get_database_host():
    """Get database host using DNS service discovery"""
    try:
        # Resolve database cluster
        _, _, ips = socket.gethostbyname_ex('production.internal.mycompany.local')
        # Return random IP for load balancing
        return random.choice(ips)
    except socket.gaierror:
        # Fallback to specific instance
        return 'prod-app-1.internal.mycompany.local'

# Usage in application
DATABASE_HOST = get_database_host()
DATABASE_URL = f"postgresql://user:pass@{DATABASE_HOST}:5432/mydb"
```

### Microservices Configuration
```yaml
# Docker Compose / Kubernetes configuration
version: '3.8'
services:
  web-service:
    image: myapp/web:latest
    environment:
      - DATABASE_HOST=production.internal.mycompany.local
      - CACHE_HOST=cache.internal.mycompany.local
      - MONITORING_HOST=monitoring.internal.mycompany.local
      - DNS_RESOLVER=dns.internal.mycompany.local
    
  api-service:
    image: myapp/api:latest
    environment:
      - AUTH_SERVICE=auth.internal.mycompany.local
      - USER_SERVICE=users.internal.mycompany.local
      - NOTIFICATION_SERVICE=notifications.internal.mycompany.local
```

### Load Balancer Configuration
```nginx
# Nginx upstream configuration using DNS
upstream production_backend {
    # DNS resolution will return multiple IPs
    server production.internal.mycompany.local:8080;
    
    # Fallback to specific instances
    server prod-app-1.internal.mycompany.local:8080 backup;
    server prod-app-2.internal.mycompany.local:8080 backup;
}

upstream development_backend {
    server development.internal.mycompany.local:8080;
    server dev-app-1.internal.mycompany.local:8080 backup;
}

server {
    listen 80;
    server_name api.mycompany.com;
    
    location /prod/ {
        proxy_pass http://production_backend/;
        proxy_set_header Host $host;
    }
    
    location /dev/ {
        proxy_pass http://development_backend/;
        proxy_set_header Host $host;
    }
}
```

## Testing and Validation

### DNS Resolution Tests
```bash
# Test from any instance in the multi-VPC setup
ssh -i ~/.ssh/my-multi-vpc-key.pem ec2-user@<instance-ip>

# Run comprehensive DNS tests
./test-dns.sh

# Manual DNS testing
nslookup production.internal.mycompany.local
nslookup development.internal.mycompany.local
nslookup dns.internal.mycompany.local
nslookup all-apps.internal.mycompany.local

# Test DNS performance
time nslookup production.internal.mycompany.local
```

### Cross-VPC Connectivity Tests
```bash
# Test HTTP connectivity between environments
curl -s http://production.internal.mycompany.local/health
curl -s http://development.internal.mycompany.local/health
curl -s http://dns.internal.mycompany.local/health

# Test specific services
curl -s http://dns.internal.mycompany.local/dns-status
curl -s http://dns.internal.mycompany.local/connectivity-matrix
curl -s http://dns.internal.mycompany.local/service-discovery
```

### Monitoring Dashboard
```bash
# Access shared services monitoring dashboard
# (Replace with actual shared services IP from terraform output)
curl -s http://<shared-services-ip>/

# View DNS monitoring logs
ssh -i ~/.ssh/my-multi-vpc-key.pem ec2-user@<shared-services-ip>
tail -f /var/log/dns-monitoring.log
```

## Monitoring and Troubleshooting

### DNS Health Monitoring
```bash
# Automated DNS monitoring (runs every 5 minutes)
# Check monitoring logs on shared services instance
tail -f /var/log/dns-monitoring.log

# Manual DNS health check
./monitor-dns.sh
```

### Common Issues and Solutions

#### DNS Resolution Failures
```bash
# Check VPC DNS settings
aws ec2 describe-vpcs --vpc-ids <vpc-id> \
  --query 'Vpcs[0].{DnsSupport:DnsSupport,DnsHostnames:DnsHostnames}'

# Verify private zone associations
aws route53 list-vpc-association-authorizations \
  --hosted-zone-id <zone-id>

# Test DNS from instance using Route 53 resolver
nslookup production.internal.mycompany.local 169.254.169.253
```

#### Cross-VPC Connectivity Issues
```bash
# Check VPC peering status
aws ec2 describe-vpc-peering-connections \
  --filters "Name=status-code,Values=active"

# Verify route tables
aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=<vpc-id>"

# Test network connectivity
telnet <target-ip> 80
nc -zv <target-ip> 80
```

#### Security Group Issues
```bash
# Check security group rules
aws ec2 describe-security-groups --group-ids <sg-id>

# Test port connectivity
nmap -p 80,443,22 <target-ip>
```

### Performance Optimization

#### DNS Caching
```bash
# Configure local DNS caching on instances
sudo systemctl enable dnsmasq
sudo systemctl start dnsmasq

# Monitor DNS query performance
dig @169.254.169.253 production.internal.mycompany.local +stats
```

#### Connection Pooling
```python
# Application-level connection pooling
import dns.resolver
from functools import lru_cache

@lru_cache(maxsize=100)
def resolve_service(service_name, ttl=300):
    """Cached DNS resolution with TTL"""
    try:
        result = dns.resolver.resolve(service_name, 'A')
        return [str(ip) for ip in result]
    except dns.resolver.NXDOMAIN:
        return []
```

## Security Considerations

### Network Security
- **VPC Isolation**: Production and development are network-isolated
- **Security Groups**: Restrictive ingress rules per environment
- **Private Subnets**: No direct internet access for application instances
- **VPC Flow Logs**: Network traffic monitoring (optional)

### DNS Security
- **Private Zones**: Internal DNS not exposed to internet
- **VPC Association**: DNS resolution limited to associated VPCs
- **Query Logging**: Optional DNS query logging for audit
- **Access Control**: IAM policies for DNS zone modifications

### Access Control
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::ACCOUNT:role/DNSAdminRole"
      },
      "Action": [
        "route53:ChangeResourceRecordSets",
        "route53:GetHostedZone",
        "route53:ListResourceRecordSets"
      ],
      "Resource": "arn:aws:route53:::hostedzone/ZONEID"
    }
  ]
}
```

## Scaling and Extension

### Adding New VPCs
```hcl
# Add new VPC to the configuration
resource "aws_vpc" "staging" {
  cidr_block           = "10.3.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "staging-vpc"
  }
}

# Add VPC peering
resource "aws_vpc_peering_connection" "staging_to_shared" {
  vpc_id      = aws_vpc.staging.id
  peer_vpc_id = aws_vpc.shared_services.id
  auto_accept = true
}

# Associate with private zone
private_zone_vpc_associations = [
  # ... existing associations ...
  {
    vpc_id  = aws_vpc.staging.id
    comment = "Staging VPC association"
  }
]
```

### Adding New Services
```hcl
# Add new DNS records for additional services
cache_service = {
  name    = "cache"
  type    = "A"
  ttl     = 300
  records = [aws_instance.cache_server.private_ip]
}

api_gateway = {
  name    = "api"
  type    = "CNAME"
  ttl     = 300
  records = ["internal-api-gateway.amazonaws.com"]
}
```

### Multi-Region Extension
```hcl
# Cross-region private zone association
resource "aws_route53_zone_association" "cross_region" {
  provider = aws.us_east_1
  zone_id  = module.multi_vpc_dns.private_zone_id
  vpc_id   = aws_vpc.east_coast.id
}
```

## Cost Optimization

### Current Costs (Monthly)
- **VPCs**: Free (3 VPCs)
- **Subnets**: Free (6 subnets)
- **VPC Peering**: Free (2-3 connections)
- **Route 53 Private Zone**: $0.50
- **EC2 Instances**: ~$8.50 per t3.micro instance
- **DNS Queries**: Minimal for internal queries

### Total Estimated Cost
- **Development Setup**: ~$35-50/month (6 t3.micro instances)
- **Production Setup**: Scale based on instance types and count

### Cost Optimization Tips
```hcl
# Use smaller instances for development
development_instance_type = "t3.nano"  # $4.25/month

# Reduce instance counts for testing
development_instance_count = 1
shared_services_instance_count = 1

# Use spot instances for development (not shown in example)
# Implement auto-scaling for production workloads
```

## Disaster Recovery

### Backup Strategy
```bash
# Export DNS records for backup
aws route53 list-resource-record-sets \
  --hosted-zone-id <zone-id> \
  --output json > dns-backup.json

# Backup VPC configuration
aws ec2 describe-vpcs --output json > vpc-backup.json
aws ec2 describe-subnets --output json > subnet-backup.json
```

### Recovery Procedures
```bash
# Restore DNS records from backup
aws route53 change-resource-record-sets \
  --hosted-zone-id <zone-id> \
  --change-batch file://dns-restore.json

# Recreate infrastructure using Terraform
terraform plan -target=module.multi_vpc_dns
terraform apply -target=module.multi_vpc_dns
```

## Best Practices

### DNS Naming Conventions
- **Services**: `service-name.domain.local`
- **Environments**: `environment.domain.local`
- **Instances**: `service-instance-number.domain.local`
- **Configuration**: `_config.environment.domain.local`

### Application Design
- **DNS Caching**: Implement application-level DNS caching
- **Fallback Logic**: Handle DNS resolution failures gracefully
- **Health Checks**: Implement comprehensive health check endpoints
- **Service Discovery**: Use DNS for dynamic service discovery

### Operational Excellence
- **Monitoring**: Set up DNS resolution monitoring
- **Alerting**: Alert on DNS resolution failures
- **Documentation**: Maintain service discovery documentation
- **Testing**: Regular testing of cross-VPC connectivity

## Cleanup

```bash
# Destroy all resources
terraform destroy

# Confirm all resources are removed
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=*-vpc"
aws route53 list-hosted-zones --query 'HostedZones[?Name==`internal.mycompany.local.`]'
```

## Next Steps

1. **Production Readiness**
   - Implement SSL/TLS certificates
   - Set up centralized logging
   - Configure monitoring and alerting
   - Implement backup and disaster recovery

2. **Security Hardening**
   - Enable VPC Flow Logs
   - Implement network ACLs
   - Set up DNS query logging
   - Configure IAM roles and policies

3. **Scaling Preparation**
   - Design auto-scaling policies
   - Plan for additional VPCs
   - Implement load balancing
   - Consider multi-region deployment

4. **Integration**
   - Connect to on-premises networks
   - Integrate with CI/CD pipelines
   - Set up service mesh (optional)
   - Implement API gateways

This multi-VPC DNS integration example provides a comprehensive foundation for enterprise-grade service discovery and cross-VPC communication patterns.
