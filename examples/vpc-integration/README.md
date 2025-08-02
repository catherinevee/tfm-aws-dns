# VPC Integration Example

This example demonstrates comprehensive DNS integration with VPC resources, including EC2 instances, load balancers, and both public and private DNS zones.

## What This Creates

### Infrastructure
- **VPC** with public and private subnets across multiple AZs
- **EC2 instances** for web servers (public subnets) and database servers (private subnets)
- **Application Load Balancer** for web traffic distribution
- **Security groups** with appropriate access controls

### DNS Configuration
- **Public DNS zone** for external access with alias records to ALB
- **Private DNS zone** for internal service discovery within VPC
- **Integrated DNS resolution** between public and private resources

## Architecture

```
Internet
    |
    v
[ALB] ← Public DNS (example.com)
    |
    v
[Web Servers] ← Private DNS (web-1.internal.local, web-2.internal.local)
    |
    v
[Database Servers] ← Private DNS (db-primary.internal.local, database.internal.local)
```

### Public DNS Records
- `example.com` → ALB (alias record)
- `www.example.com` → ALB (alias record)

### Private DNS Records
- `web-1.internal.local` → Web server 1 private IP
- `web-2.internal.local` → Web server 2 private IP
- `db-primary.internal.local` → Primary database server
- `db-replica.internal.local` → Replica database server
- `database.internal.local` → Alias to primary database

## Usage

### Basic Deployment
```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan \
  -var="public_domain_name=yourdomain.com" \
  -var="private_domain_name=internal.yourdomain.com"

# Deploy the infrastructure
terraform apply
```

### With SSH Access
```bash
# Deploy with SSH key for instance access
terraform apply \
  -var="public_domain_name=yourdomain.com" \
  -var="private_domain_name=internal.yourdomain.com" \
  -var="key_name=my-ec2-key"
```

### Custom Configuration
Create `terraform.tfvars`:
```hcl
# Environment
environment = "dev"

# Domain names
public_domain_name  = "mycompany.com"
private_domain_name = "internal.mycompany.com"

# VPC configuration
vpc_cidr             = "10.0.0.0/16"
private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24"]

# Instance configuration
web_instance_count = 2
db_instance_count  = 2
web_instance_type  = "t3.small"
db_instance_type   = "t3.small"

# SSH access
key_name = "my-ec2-key"
```

## DNS Integration Features

### Public DNS (External Access)
- **Cost-effective alias records** to ALB (no DNS query charges)
- **Health check integration** with load balancer
- **Automatic failover** if ALB becomes unhealthy
- **Root domain support** (example.com works without www)

### Private DNS (Internal Communication)
- **Service discovery** within VPC using friendly names
- **Database abstraction** - applications use `database.internal.local`
- **Load balancer integration** for internal services
- **Cross-subnet resolution** for distributed applications

### VPC DNS Settings
- **DNS hostnames enabled** - instances get DNS names
- **DNS support enabled** - Route 53 resolver works
- **Private zone association** - VPC can resolve private records
- **Automatic resolution** - no manual DNS configuration needed

## Testing DNS Integration

### 1. Public DNS Resolution
```bash
# Test from anywhere on the internet
dig A yourdomain.com
dig A www.yourdomain.com

# Should return ALB IP addresses
curl http://yourdomain.com
```

### 2. Private DNS Resolution (from within VPC)
```bash
# SSH to a web server instance
ssh -i ~/.ssh/key.pem ec2-user@<web-server-public-ip>

# Test internal DNS resolution
nslookup database.internal.yourdomain.com
nslookup web-1.internal.yourdomain.com
nslookup db-primary.internal.yourdomain.com

# Test connectivity using DNS names
ping database.internal.yourdomain.com
curl http://web-1.internal.yourdomain.com/health
```

### 3. DNS Integration Demo
Each web server includes a DNS test page:
```bash
# View DNS integration demo
curl http://yourdomain.com

# View detailed DNS test results
curl http://yourdomain.com/dns-test
```

## Application Integration Patterns

### Database Connections
```python
# Application code uses DNS names instead of IPs
DATABASE_URL = "mysql://user:pass@database.internal.yourdomain.com:3306/mydb"

# Automatic failover to replica if needed
REPLICA_URL = "mysql://user:pass@db-replica.internal.yourdomain.com:3306/mydb"
```

### Service Discovery
```yaml
# Microservices configuration
services:
  web:
    image: myapp:latest
    environment:
      - DATABASE_HOST=database.internal.yourdomain.com
      - CACHE_HOST=cache.internal.yourdomain.com
      - API_HOST=api.internal.yourdomain.com
```

### Load Balancer Configuration
```nginx
# Nginx upstream configuration
upstream backend {
    server web-1.internal.yourdomain.com:8080;
    server web-2.internal.yourdomain.com:8080;
}
```

## Monitoring and Health Checks

### Load Balancer Health Checks
- **Path**: `/health`
- **Interval**: 30 seconds
- **Timeout**: 5 seconds
- **Healthy threshold**: 2 consecutive successes
- **Unhealthy threshold**: 2 consecutive failures

### DNS Health Monitoring
```bash
# Monitor DNS resolution
watch -n 5 'dig A yourdomain.com +short'

# Monitor internal DNS
watch -n 5 'nslookup database.internal.yourdomain.com'
```

### Application Health Endpoints
- **Web servers**: `http://<server>/health`
- **Database servers**: `http://<server>/health`
- **Load balancer**: `http://<alb>/health`

## Security Considerations

### Network Security
- **Public subnets**: Web servers with internet access
- **Private subnets**: Database servers isolated from internet
- **Security groups**: Restrictive access rules
- **NACLs**: Additional network-level protection

### DNS Security
- **Private zones**: Internal DNS not exposed to internet
- **VPC association**: DNS resolution limited to associated VPCs
- **Access control**: IAM policies for DNS modifications
- **Query logging**: Optional DNS query logging for monitoring

## Scaling Patterns

### Horizontal Scaling
```hcl
# Increase instance counts
web_instance_count = 4
db_instance_count  = 3

# DNS records automatically created for new instances
# web-3.internal.local, web-4.internal.local, etc.
```

### Multi-AZ Deployment
```hcl
# Spread across more availability zones
private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
```

### Database Clustering
```python
# Application handles multiple database endpoints
PRIMARY_DB = "db-primary.internal.yourdomain.com"
REPLICA_DBS = [
    "db-replica.internal.yourdomain.com",
    "db-replica-2.internal.yourdomain.com"
]
```

## Troubleshooting

### Public DNS Issues
```bash
# Check nameserver delegation
dig NS yourdomain.com

# Test ALB health
curl -I http://<alb-dns-name>/health

# Check Route 53 records
aws route53 list-resource-record-sets --hosted-zone-id <zone-id>
```

### Private DNS Issues
```bash
# Check VPC DNS settings
aws ec2 describe-vpcs --vpc-ids <vpc-id>

# Test from within VPC
nslookup database.internal.yourdomain.com 169.254.169.253

# Check private zone association
aws route53 list-vpc-association-authorizations --hosted-zone-id <zone-id>
```

### Connectivity Issues
```bash
# Test security group rules
aws ec2 describe-security-groups --group-ids <sg-id>

# Test network connectivity
telnet database.internal.yourdomain.com 3306
nc -zv web-1.internal.yourdomain.com 80
```

## Outputs

The example provides comprehensive outputs including:
- **VPC and subnet information**
- **DNS zone IDs and nameservers**
- **Instance details with DNS names**
- **Access URLs and SSH commands**
- **Health check endpoints**
- **DNS testing commands**

## Cost Estimation

### AWS Resources (Monthly)
- **VPC**: Free
- **Subnets**: Free
- **Internet Gateway**: Free
- **Route Tables**: Free
- **Security Groups**: Free
- **EC2 instances**: ~$8-16 (t3.micro) per instance
- **Application Load Balancer**: ~$16-22
- **Route 53 hosted zones**: $1.00 (2 zones × $0.50)
- **DNS queries**: Minimal cost for typical usage

### Total Estimated Cost
- **Development**: ~$35-50/month
- **Production**: Scale based on instance types and count

## Cleanup

```bash
# Destroy all resources
terraform destroy

# Confirm destruction
# Note: DNS zones may take a few minutes to fully delete
```

## Next Steps

After deploying this example:

1. **Configure domain registrar** with Route 53 nameservers
2. **Test DNS resolution** from multiple locations
3. **Set up monitoring** for DNS and application health
4. **Implement SSL/TLS** certificates for HTTPS
5. **Add additional services** (cache, message queues, etc.)
6. **Configure backup and disaster recovery**

This example provides a solid foundation for production-ready applications with integrated DNS and VPC resources.
