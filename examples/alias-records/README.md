# Alias Records Example

This example demonstrates how to create Route 53 alias records that point to AWS resources like Application Load Balancers, CloudFront distributions, and API Gateway.

## What This Creates

- Public Route 53 hosted zone
- Alias records pointing to AWS resources (no charge for queries)
- Regular DNS records for non-AWS resources
- Health check evaluation for load balancer aliases

## Alias Records vs Regular Records

### Alias Records (AWS Resources)
- **No charge** for DNS queries
- **Automatic IP resolution** - AWS manages IP changes
- **Health check integration** - Route 53 can check target health
- **Root domain support** - Can create alias at root (example.com)

### Regular Records (Non-AWS Resources)
- **Standard DNS charges** apply
- **Static IP/CNAME** - Manual updates needed
- **No automatic health checks**
- **CNAME limitations** - Cannot use CNAME at root domain

## AWS Resources Supported

### Application Load Balancer (ALB)
```
example.com     → ALB DNS name (alias)
www.example.com → ALB DNS name (alias)
```

### CloudFront Distribution
```
cdn.example.com    → CloudFront domain (alias)
static.example.com → CloudFront domain (alias)
```

### API Gateway
```
api.example.com → API Gateway custom domain (alias)
```

## Usage

### With Existing AWS Resources
```bash
# Initialize Terraform
terraform init

# Deploy with your existing resources
terraform apply \
  -var="domain_name=yourdomain.com" \
  -var="load_balancer_name=my-alb" \
  -var="cloudfront_distribution_id=E1234567890123"
```

### Configuration File
Create `terraform.tfvars`:
```hcl
domain_name = "mycompany.com"

# AWS resources (optional - only include what you have)
load_balancer_name        = "my-web-alb"
cloudfront_distribution_id = "E1234567890123"
api_gateway_domain        = "api-gateway-domain.execute-api.us-west-2.amazonaws.com"
api_gateway_zone_id       = "Z2OJLYMUO9EFXC"

# Non-AWS resources
legacy_server_ip = "203.0.113.100"
```

### Minimal Configuration (No AWS Resources)
```bash
# Just create the zone with regular records
terraform apply -var="domain_name=yourdomain.com"
```

## Benefits of Alias Records

### 1. Cost Savings
- **Free DNS queries** for alias records to AWS resources
- Regular A records charge $0.40 per million queries

### 2. Automatic Updates
- AWS automatically updates IP addresses
- No manual DNS updates when AWS resources change IPs

### 3. Health Checks
- Route 53 automatically checks target health
- Stops routing to unhealthy targets

### 4. Root Domain Support
- Can create alias records at root domain
- CNAME records cannot be used at root domain

## Common Scenarios

### Web Application with CDN
```hcl
# Root and www point to load balancer
example.com     → ALB (dynamic content)
www.example.com → ALB (dynamic content)

# Static assets point to CloudFront
cdn.example.com    → CloudFront (static content)
static.example.com → CloudFront (images, CSS, JS)
```

### API-First Architecture
```hcl
# Main site
example.com → ALB or CloudFront

# API endpoints
api.example.com → API Gateway
v1.api.example.com → API Gateway (versioned)
```

### Hybrid Architecture
```hcl
# Modern AWS services
example.com → ALB
api.example.com → API Gateway

# Legacy systems
legacy.example.com → Traditional server IP
old-app.example.com → Traditional server IP
```

## Health Check Behavior

### Load Balancer Aliases
- `evaluate_target_health = true`
- Route 53 checks ALB health
- Stops routing if ALB is unhealthy

### CloudFront Aliases
- `evaluate_target_health = false`
- CloudFront handles its own health checks
- Route 53 always routes to CloudFront

## Prerequisites

To use this example with real AWS resources:

1. **Application Load Balancer**: Create ALB first
2. **CloudFront Distribution**: Create distribution first
3. **API Gateway**: Set up custom domain first
4. **Permissions**: Ensure Terraform can read existing resources

## Finding Resource Information

### Load Balancer
```bash
# List load balancers
aws elbv2 describe-load-balancers --query 'LoadBalancers[*].[LoadBalancerName,DNSName,CanonicalHostedZoneId]'
```

### CloudFront Distribution
```bash
# List distributions
aws cloudfront list-distributions --query 'DistributionList.Items[*].[Id,DomainName,HostedZoneId]'
```

### API Gateway
```bash
# List custom domains
aws apigateway get-domain-names --query 'Items[*].[DomainName,DistributionDomainName,DistributionHostedZoneId]'
```

## Verification

### Test Alias Resolution
```bash
# Check if alias records resolve
dig A example.com
dig A www.example.com
dig A cdn.example.com

# Verify they point to AWS resources
dig A example.com +short
# Should show ALB IP addresses

dig A cdn.example.com +short
# Should show CloudFront IP addresses
```

### Test Health Checks
```bash
# Check if health evaluation is working
aws route53 get-health-check --health-check-id <health-check-id>
```

## Outputs

- `zone_id`: Route 53 hosted zone ID
- `alias_records_created`: Summary of alias records
- `regular_records_created`: Summary of regular records
- `verification_commands`: Commands to test DNS
- `aws_resources_referenced`: AWS resources used

## Cost Comparison

### Alias Records (Recommended)
- **DNS Queries**: Free for AWS resources
- **Health Checks**: Included with ALB aliases
- **Total**: ~$0.50/month (just hosted zone)

### Regular A Records
- **DNS Queries**: $0.40 per million queries
- **Health Checks**: $0.50/month each (optional)
- **Total**: $0.50/month + query charges + health check costs

## Troubleshooting

### Alias Record Not Resolving
1. Verify target resource exists and is healthy
2. Check resource is in same AWS account
3. Confirm correct zone ID for target resource

### Health Check Failing
1. Verify target resource health
2. Check security groups allow Route 53 health checkers
3. Review CloudWatch metrics for health check status

### CNAME vs Alias Confusion
- **Use Alias**: For AWS resources, root domain, cost savings
- **Use CNAME**: For external services, subdomains only

## Cleanup

```bash
terraform destroy
```

**Note**: Alias records are removed immediately, but DNS propagation may take time.
