# Simple DNS Records Example

This example demonstrates how to create basic DNS record types (A, CNAME, MX, TXT) for a typical website and email setup.

## What This Creates

- Public Route 53 hosted zone
- A records for root domain, www, and API subdomains
- CNAME record for blog subdomain
- MX records for email routing
- TXT records for SPF, DMARC, and domain verification
- Mail server A records

## DNS Records Created

### Web Records
- **Root Domain** (`example.com`) → Points to web server IP
- **WWW** (`www.example.com`) → Points to web server IP
- **API** (`api.example.com`) → Points to API server IP
- **Blog** (`blog.example.com`) → CNAME to external blog service

### Email Records
- **MX Records** → Routes email to mail servers with priority
- **Mail Server** (`mail.example.com`) → Primary mail server IP
- **Backup Mail** (`mail2.example.com`) → Backup mail server IP
- **SPF Record** → Email security policy
- **DMARC Record** → Email authentication policy

### Verification
- **TXT Record** → Domain verification for services

## Usage

### Basic Deployment
```bash
# Initialize Terraform
terraform init

# Plan with your domain and IPs
terraform plan \
  -var="domain_name=yourdomain.com" \
  -var="web_server_ip=203.0.113.1" \
  -var="api_server_ip=203.0.113.2"

# Apply the configuration
terraform apply
```

### Custom Configuration
Create a `terraform.tfvars` file:
```hcl
domain_name = "mycompany.com"

# Server IP addresses
web_server_ip         = "203.0.113.10"
api_server_ip         = "203.0.113.11"
mail_server_ip        = "203.0.113.20"
mail_server_backup_ip = "203.0.113.21"
```

## Configuration Options

- `domain_name`: Your domain name (required)
- `web_server_ip`: IP address for root and www records
- `api_server_ip`: IP address for API subdomain
- `mail_server_ip`: Primary mail server IP
- `mail_server_backup_ip`: Backup mail server IP
- `aws_region`: AWS region (default: us-west-2)

## DNS Record Types Explained

### A Records
Point domain names to IPv4 addresses:
```
example.com        → 203.0.113.1
www.example.com    → 203.0.113.1
api.example.com    → 203.0.113.2
```

### CNAME Records
Point domain names to other domain names:
```
blog.example.com   → myblog.wordpress.com
```

### MX Records
Route email with priority (lower number = higher priority):
```
example.com        → 10 mail.example.com
example.com        → 20 mail2.example.com
```

### TXT Records
Store text information for verification and security:
```
example.com        → "v=spf1 mx include:_spf.google.com ~all"
_dmarc.example.com → "v=DMARC1; p=quarantine; rua=mailto:dmarc@example.com"
```

## After Deployment

### 1. Update Domain Registrar
Configure the name servers from the output with your domain registrar.

### 2. Verify DNS Records
Use the verification commands from the output:
```bash
# Check A records
dig A yourdomain.com
dig A www.yourdomain.com
dig A api.yourdomain.com

# Check CNAME
dig CNAME blog.yourdomain.com

# Check MX records
dig MX yourdomain.com

# Check TXT records
dig TXT yourdomain.com
```

### 3. Test Website Access
```bash
# Test web server
curl http://yourdomain.com
curl http://www.yourdomain.com

# Test API
curl http://api.yourdomain.com
```

## Email Configuration

The MX records created will route email to your mail servers:
- Primary: `mail.yourdomain.com` (priority 10)
- Backup: `mail2.yourdomain.com` (priority 20)

### SPF Record
The SPF record allows:
- Email from MX servers
- Email from Google's servers (if using Gmail)
- Soft fail for other servers

### DMARC Record
The DMARC record:
- Sets policy to quarantine suspicious emails
- Sends reports to `dmarc@yourdomain.com`

## Common Use Cases

### Personal Website
```hcl
domain_name = "johnsmith.com"
web_server_ip = "your-server-ip"
# Points both root and www to your server
```

### Business Website with API
```hcl
domain_name = "mycompany.com"
web_server_ip = "web-server-ip"
api_server_ip = "api-server-ip"
# Separates web and API traffic
```

### Blog with External Hosting
The CNAME record for `blog.yourdomain.com` points to external services like:
- WordPress.com: `myblog.wordpress.com`
- Medium: `medium.com`
- Ghost: `myblog.ghost.io`

## Outputs

- `zone_id`: Route 53 hosted zone ID
- `zone_name`: Domain name
- `name_servers`: Name servers for domain registrar
- `dns_records_created`: Summary of all DNS records
- `verification_commands`: Commands to test DNS resolution

## Cost

- **Hosted Zone**: $0.50/month
- **DNS Queries**: $0.40 per million queries (first billion queries/month)
- **Health Checks**: Not used in this example

## Troubleshooting

### DNS Not Resolving
1. Verify name servers are configured with domain registrar
2. Wait for DNS propagation (up to 48 hours)
3. Check TTL values (300 seconds = 5 minutes)

### Email Issues
1. Verify MX records: `dig MX yourdomain.com`
2. Check mail server configuration
3. Test SPF record: Use online SPF checkers

### Website Not Loading
1. Verify A records: `dig A yourdomain.com`
2. Check web server is running on specified IP
3. Verify firewall allows HTTP/HTTPS traffic

## Cleanup

```bash
terraform destroy
```

**Note**: DNS changes may take time to propagate even after destruction.
