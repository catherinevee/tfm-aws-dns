# Minimal DNS Zone Example

This example demonstrates the absolute minimal configuration required to create a public DNS hosted zone using the module.

## What This Creates

- A single Route 53 public hosted zone
- No DNS records (just the zone itself)
- Uses all module defaults
- Domain: example.com (you should change this to your domain)

## Usage

```bash
# Initialize Terraform
terraform init

# Plan the deployment (change domain name)
terraform plan -var="domain_name=yourdomain.com"

# Apply the configuration
terraform apply -var="domain_name=yourdomain.com"
```

## Configuration

This example uses only the required parameter:
- `domain_name`: The domain name for the hosted zone

All other parameters use the module's default values:
- Public zone enabled
- No DNS records created
- Default TTL values
- No health checks

## Outputs

- `zone_id`: The Route 53 hosted zone ID
- `zone_name`: The domain name of the hosted zone
- `name_servers`: Name servers that need to be configured with your domain registrar
- `zone_arn`: ARN of the hosted zone

## Next Steps

After creating the zone:

1. **Update your domain registrar**: Configure the name servers from the output with your domain registrar
2. **Add DNS records**: Use other examples to add A, CNAME, MX, and other records
3. **Verify DNS propagation**: Use tools like `dig` or `nslookup` to verify DNS resolution

## Cost

Route 53 hosted zones cost $0.50 per month per zone. There are no additional charges for this minimal configuration.

## Security Note

This creates a public DNS zone that will be visible on the internet. Make sure you own the domain name before creating the zone.

## Example Commands

```bash
# Check DNS propagation
dig NS yourdomain.com

# Verify zone creation
aws route53 list-hosted-zones --query "HostedZones[?Name=='yourdomain.com.']"
```
