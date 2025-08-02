# Simple Private DNS Zone Example

This example demonstrates how to create a private DNS zone for internal VPC service discovery and resolution.

## What This Creates

- Private Route 53 hosted zone for internal domain resolution
- DNS records for common internal services (databases, cache, APIs)
- VPC association for private DNS resolution
- Service discovery patterns for microservices architecture

## Private DNS Benefits

### Internal Service Discovery
- **Human-readable names** instead of IP addresses
- **Service abstraction** - change IPs without updating applications
- **Environment consistency** - same names across dev/staging/prod
- **Load balancing** - point to load balancers with friendly names

### Security
- **Internal-only resolution** - not visible from internet
- **VPC isolation** - only accessible within associated VPCs
- **No external DNS queries** - keeps internal architecture private

## Services Configured

### Database Layer
```
db-primary.internal.local  → 10.0.1.10 (Primary database)
db-replica.internal.local  → 10.0.1.11 (Read replica)
database.internal.local    → db-primary.internal.local (Alias)
```

### Application Layer
```
app-01.internal.local      → 10.0.2.10 (App server 1)
app-02.internal.local      → 10.0.2.11 (App server 2)
```

### Cache Layer
```
redis-primary.internal.local → 10.0.3.10 (Primary cache)
redis-replica.internal.local → 10.0.3.11 (Cache replica)
cache.internal.local         → redis-primary.internal.local (Alias)
```

### Infrastructure
```
internal-lb.internal.local   → 10.0.4.10 (Internal load balancer)
api-internal.internal.local  → internal-lb.internal.local (API endpoint)
monitoring.internal.local    → 10.0.5.10 (Monitoring server)
logs.internal.local          → 10.0.5.11 (Log aggregation)
```

## Usage

### Basic Deployment
```bash
# Initialize Terraform
terraform init

# Deploy with default settings
terraform apply -var="domain_name=mycompany.internal"
```

### Custom VPC and Environment
```bash
# Deploy to specific VPC and environment
terraform apply \
  -var="domain_name=mycompany.internal" \
  -var="vpc_id=vpc-12345678" \
  -var="environment=prod"
```

### Configuration File
Create `terraform.tfvars`:
```hcl
domain_name = "mycompany.internal"
vpc_id      = "vpc-12345678"
environment = "prod"

# Database servers
db_primary_ip = "10.0.1.10"
db_replica_ip = "10.0.1.11"

# Application servers
app_server_1_ip = "10.0.2.10"
app_server_2_ip = "10.0.2.11"

# Cache servers
redis_primary_ip = "10.0.3.10"
redis_replica_ip = "10.0.3.11"

# Infrastructure
internal_lb_ip       = "10.0.4.10"
monitoring_server_ip = "10.0.5.10"
log_server_ip        = "10.0.5.11"
```

## Application Integration

### Database Connections
```python
# Instead of hardcoded IPs
DATABASE_URL = "postgresql://user:pass@10.0.1.10:5432/mydb"

# Use friendly DNS names
DATABASE_URL = "postgresql://user:pass@database.internal.local:5432/mydb"
```

### Cache Connections
```python
# Redis connection
REDIS_URL = "redis://cache.internal.local:6379"
```

### API Calls
```javascript
// Internal API calls
const apiUrl = 'http://api-internal.internal.local/v1/';
```

### Monitoring Integration
```yaml
# Prometheus configuration
scrape_configs:
  - job_name: 'app-servers'
    static_configs:
      - targets: 
        - 'app-01.internal.local:9090'
        - 'app-02.internal.local:9090'
```

## DNS Resolution

### From EC2 Instances
Private DNS works automatically for EC2 instances in the associated VPC:
```bash
# Test DNS resolution
nslookup database.internal.local
dig cache.internal.local
ping api-internal.internal.local
```

### DNS Resolver IP
Private zones use the VPC DNS resolver at `169.254.169.253`:
```bash
# Query specific resolver
dig @169.254.169.253 database.internal.local
```

## Multi-Environment Setup

### Development Environment
```hcl
domain_name = "dev.internal"
environment = "dev"
# Use smaller instance IPs
```

### Staging Environment
```hcl
domain_name = "staging.internal"
environment = "staging"
# Use staging instance IPs
```

### Production Environment
```hcl
domain_name = "prod.internal"
environment = "prod"
# Use production instance IPs
```

## Service Discovery Patterns

### Database Failover
```python
# Primary connection
try:
    db = connect("database.internal.local")
except:
    # Fallback to replica
    db = connect("db-replica.internal.local")
```

### Load Balancing
```python
# Round-robin between app servers
app_servers = [
    "app-01.internal.local",
    "app-02.internal.local"
]
```

### Health Checks
```bash
# Check service health
curl http://monitoring.internal.local/health
curl http://api-internal.internal.local/health
```

## Verification

### Test DNS Resolution (from within VPC)
```bash
# Test all services
nslookup database.internal.local
nslookup cache.internal.local
nslookup api-internal.internal.local
nslookup monitoring.internal.local

# Test CNAME records
dig database.internal.local CNAME
dig cache.internal.local CNAME
```

### Test Service Connectivity
```bash
# Test database connection
telnet database.internal.local 5432

# Test cache connection
telnet cache.internal.local 6379

# Test HTTP services
curl http://api-internal.internal.local/health
curl http://monitoring.internal.local
```

## Outputs

- `private_zone_id`: Route 53 private zone ID
- `dns_records_created`: Summary of all DNS records
- `service_endpoints`: Ready-to-use service endpoints
- `verification_commands`: Commands to test DNS resolution
- `connection_examples`: Example connection strings

## Cost

- **Private Hosted Zone**: $0.50/month
- **DNS Queries**: Free for private zones
- **Total**: $0.50/month per zone

## Best Practices

### Naming Conventions
- Use consistent domain suffixes (`.internal`, `.local`, `.corp`)
- Include environment in domain or subdomain
- Use service-based naming (`database`, `cache`, `api`)

### IP Address Management
- Use consistent IP ranges per service type
- Document IP allocations
- Consider using DHCP reservations

### Security
- Keep private zones truly private
- Use VPC associations carefully
- Monitor DNS query logs

## Troubleshooting

### DNS Not Resolving
1. **Check VPC Association**: Verify zone is associated with correct VPC
2. **Check DNS Settings**: Ensure VPC has DNS resolution enabled
3. **Check Security Groups**: Verify port 53 is allowed

### Wrong IP Resolution
1. **Check TTL**: Wait for TTL expiry (300 seconds default)
2. **Clear DNS Cache**: Restart applications or clear system DNS cache
3. **Verify Records**: Check Route 53 console for correct records

### Cross-VPC Resolution
1. **VPC Peering**: Set up VPC peering for cross-VPC DNS
2. **Multiple Associations**: Associate zone with multiple VPCs
3. **Transit Gateway**: Use for complex multi-VPC scenarios

## Cleanup

```bash
terraform destroy
```

**Note**: Private DNS records are removed immediately within the VPC.
