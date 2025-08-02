# Subdomain Delegation Example

This example demonstrates how to delegate subdomains to other DNS zones, allowing different teams or services to manage their own DNS records independently.

## What This Creates

- Main domain zone with delegation records
- NS records pointing subdomains to external nameservers
- Optional subdomain zones managed within the same Terraform
- Complete subdomain delegation setup for organizational DNS management

## Subdomain Delegation Benefits

### Organizational Benefits
- **Team Independence**: Different teams can manage their own subdomains
- **Service Isolation**: Separate DNS management for different services
- **Scalability**: Distribute DNS management across multiple zones
- **Security**: Limit access to specific subdomain zones

### Technical Benefits
- **Performance**: Distribute DNS queries across multiple nameservers
- **Reliability**: Independent failure domains for different services
- **Flexibility**: Use different DNS providers for different subdomains

## Delegation Structure

### Main Domain (`example.com`)
Managed by the main domain zone:
```
example.com      → 192.0.2.1 (main website)
www.example.com  → 192.0.2.1 (www website)
mail.example.com → 192.0.2.10 (mail server)
```

### Delegated Subdomains
Managed by separate zones:
```
api.example.com     → Delegated to API team
blog.example.com    → Delegated to WordPress.com
staging.example.com → Delegated to staging environment
dev.example.com     → Delegated to development environment
```

## Delegation Records

### NS Records in Main Zone
```
api.example.com     NS  ns1.api-provider.com
api.example.com     NS  ns2.api-provider.com

blog.example.com    NS  ns1.wordpress.com
blog.example.com    NS  ns2.wordpress.com

staging.example.com NS  ns-1234.awsdns-12.org
staging.example.com NS  ns-5678.awsdns-34.net
```

## Usage

### Basic Delegation Only
```bash
# Initialize Terraform
terraform init

# Deploy with delegation records only
terraform apply -var="domain_name=yourdomain.com"
```

### With Managed Subdomains
```bash
# Create both main zone and some subdomain zones
terraform apply \
  -var="domain_name=yourdomain.com" \
  -var="create_api_subdomain=true" \
  -var="create_staging_subdomain=true"
```

### Configuration File
Create `terraform.tfvars`:
```hcl
domain_name = "mycompany.com"

# Main domain servers
main_server_ip = "203.0.113.1"
mail_server_ip = "203.0.113.10"

# Create managed subdomains
create_api_subdomain     = true
create_staging_subdomain = true

# API subdomain servers (if creating API subdomain)
api_server_ip    = "203.0.113.20"
api_v1_server_ip = "203.0.113.21"
api_v2_server_ip = "203.0.113.22"

# Staging subdomain servers (if creating staging subdomain)
staging_server_ip     = "203.0.113.30"
staging_api_server_ip = "203.0.113.31"
staging_db_server_ip  = "203.0.113.32"

# External delegation nameservers
api_subdomain_nameservers = [
  "ns1.api-service.com",
  "ns2.api-service.com"
]

blog_subdomain_nameservers = [
  "ns1.wordpress.com",
  "ns2.wordpress.com"
]
```

## Common Delegation Scenarios

### 1. Service-Based Delegation
```
api.company.com     → API team manages
docs.company.com    → Documentation team manages
blog.company.com    → Marketing team manages
shop.company.com    → E-commerce team manages
```

### 2. Environment-Based Delegation
```
prod.company.com    → Production team manages
staging.company.com → Staging environment
dev.company.com     → Development team manages
test.company.com    → QA team manages
```

### 3. Geographic Delegation
```
us.company.com      → US operations team
eu.company.com      → European operations team
asia.company.com    → Asian operations team
```

### 4. External Service Delegation
```
blog.company.com    → WordPress.com hosting
shop.company.com    → Shopify hosting
support.company.com → Zendesk hosting
```

## Setting Up External Zones

### For API Subdomain
1. Create Route 53 zone for `api.yourdomain.com`
2. Note the nameservers (e.g., ns-1234.awsdns-12.org)
3. Update `api_subdomain_nameservers` variable
4. Apply Terraform to create delegation

### For External Services
1. Configure subdomain in external service (WordPress, Shopify, etc.)
2. Get nameservers from external service
3. Update corresponding nameserver variable
4. Apply Terraform to create delegation

## DNS Resolution Flow

### Delegated Subdomain Query
1. Client queries `api.example.com`
2. Root nameservers refer to `example.com` nameservers
3. `example.com` nameservers return NS records for `api.example.com`
4. Client queries API subdomain nameservers directly
5. API nameservers return the final answer

### Non-Delegated Subdomain Query
1. Client queries `www.example.com`
2. Root nameservers refer to `example.com` nameservers
3. `example.com` nameservers return the final answer directly

## Verification

### Test Delegation Setup
```bash
# Check main domain nameservers
dig NS example.com

# Check subdomain delegation
dig NS api.example.com
dig NS blog.example.com
dig NS staging.example.com

# Test actual resolution through delegation
dig A api.example.com
dig A blog.example.com
```

### Verify Delegation Chain
```bash
# Trace the full delegation chain
dig +trace api.example.com

# Check specific nameserver responses
dig @ns1.api-provider.com api.example.com
```

## Management Workflows

### Adding New Delegation
1. Create new subdomain zone (or use external service)
2. Get nameservers for the new zone
3. Add NS records to main zone
4. Test delegation with `dig NS subdomain.domain.com`

### Updating Delegation
1. Update nameservers in subdomain zone
2. Update NS records in main zone
3. Wait for TTL expiry (300 seconds default)
4. Verify new delegation works

### Removing Delegation
1. Remove NS records from main zone
2. Optionally add A/CNAME records if taking over management
3. Delete subdomain zone if no longer needed

## Team Collaboration

### API Team Responsibilities
- Manage `api.example.com` zone
- Create records like `v1.api.example.com`, `docs.api.example.com`
- Handle API-specific DNS requirements

### DevOps Team Responsibilities
- Manage main `example.com` zone
- Handle delegation NS records
- Coordinate with other teams for changes

### External Service Integration
- Configure custom domains in external services
- Update delegation when services change
- Monitor external service DNS health

## Outputs

- `main_zone_id`: Main domain zone ID
- `delegation_records`: Summary of all delegations
- `verification_commands`: Commands to test delegation
- `delegation_setup_instructions`: Setup instructions for external zones
- `subdomain_examples`: Example URLs for each delegated subdomain

## Security Considerations

### Access Control
- Limit who can modify delegation NS records
- Use separate IAM roles for different subdomain zones
- Monitor changes to delegation records

### DNS Security
- Enable DNSSEC for main zone and subdomain zones
- Monitor for unauthorized delegation changes
- Use Route 53 resolver query logging

## Troubleshooting

### Delegation Not Working
1. **Check NS Records**: Verify NS records exist in main zone
2. **Check Nameservers**: Ensure delegated nameservers are responding
3. **Check TTL**: Wait for TTL expiry after changes
4. **Test Resolution**: Use `dig +trace` to see full resolution path

### Subdomain Not Resolving
1. **Check Delegation**: Verify NS records point to correct nameservers
2. **Check Target Zone**: Ensure target zone has required records
3. **Check Nameserver Health**: Verify all delegated nameservers respond

### Mixed Resolution Issues
1. **DNS Cache**: Clear local DNS cache
2. **Propagation**: Wait for global DNS propagation
3. **Consistency**: Ensure all nameservers have same records

## Cost Considerations

### Route 53 Costs
- **Main Zone**: $0.50/month
- **Each Subdomain Zone**: $0.50/month (if managed in Route 53)
- **DNS Queries**: $0.40 per million queries

### External Service Costs
- **WordPress.com**: Included with hosting
- **Shopify**: Included with plan
- **Other Services**: Varies by provider

## Cleanup

```bash
# Remove delegation and zones
terraform destroy
```

**Note**: External zones must be cleaned up separately if not managed by this Terraform.
