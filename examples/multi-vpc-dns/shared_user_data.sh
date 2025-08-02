#!/bin/bash
# User data script for shared services servers in multi-VPC environment

# Update system
yum update -y

# Install required packages
yum install -y httpd bind-utils telnet nc dnsmasq

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Create shared services info page
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>${instance_name} - Shared Services</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .header { background: #f0f0f0; padding: 20px; border-radius: 5px; }
        .section { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
        .service { color: #007acc; font-weight: bold; }
        .success { color: green; }
        .error { color: red; }
        pre { background: #f5f5f5; padding: 10px; border-radius: 3px; overflow-x: auto; }
    </style>
</head>
<body>
    <div class="header">
        <h1>${instance_name}</h1>
        <p class="service">Role: Shared Services</p>
        <p>Multi-VPC DNS and Monitoring Hub</p>
    </div>

    <div class="section">
        <h2>Instance Information</h2>
        <p><strong>Hostname:</strong> <span id="hostname">Loading...</span></p>
        <p><strong>Private IP:</strong> <span id="private-ip">Loading...</span></p>
        <p><strong>VPC ID:</strong> <span id="vpc-id">Loading...</span></p>
        <p><strong>Services:</strong> DNS Resolver, Monitoring, Health Checks</p>
    </div>

    <div class="section">
        <h2>Multi-VPC DNS Status</h2>
        <div id="dns-status">Loading DNS status...</div>
    </div>

    <div class="section">
        <h2>VPC Connectivity Matrix</h2>
        <div id="connectivity-matrix">Loading connectivity matrix...</div>
    </div>

    <div class="section">
        <h2>Service Discovery</h2>
        <div id="service-discovery">Loading service discovery...</div>
    </div>

    <script>
        // Load instance metadata
        fetch('/instance-info')
            .then(response => response.json())
            .then(data => {
                document.getElementById('hostname').textContent = data.hostname;
                document.getElementById('private-ip').textContent = data.private_ip;
                document.getElementById('vpc-id').textContent = data.vpc_id;
            });

        // Load DNS status
        fetch('/dns-status')
            .then(response => response.json())
            .then(data => {
                const statusDiv = document.getElementById('dns-status');
                statusDiv.innerHTML = '';
                data.zones.forEach(zone => {
                    const zoneDiv = document.createElement('div');
                    zoneDiv.innerHTML = `
                        <p><strong>${zone.name}:</strong> 
                        <span class="${zone.status === 'active' ? 'success' : 'error'}">
                            ${zone.status.toUpperCase()}
                        </span></p>
                        <pre>Records: ${zone.record_count}</pre>
                    `;
                    statusDiv.appendChild(zoneDiv);
                });
            });

        // Load connectivity matrix
        fetch('/connectivity-matrix')
            .then(response => response.json())
            .then(data => {
                const matrixDiv = document.getElementById('connectivity-matrix');
                matrixDiv.innerHTML = '<table border="1" style="border-collapse: collapse; width: 100%;">';
                matrixDiv.innerHTML += '<tr><th>Source VPC</th><th>Target VPC</th><th>Status</th><th>Latency</th></tr>';
                data.connections.forEach(conn => {
                    matrixDiv.innerHTML += `
                        <tr>
                            <td>${conn.source}</td>
                            <td>${conn.target}</td>
                            <td class="${conn.status === 'connected' ? 'success' : 'error'}">${conn.status}</td>
                            <td>${conn.latency}</td>
                        </tr>
                    `;
                });
                matrixDiv.innerHTML += '</table>';
            });

        // Load service discovery
        fetch('/service-discovery')
            .then(response => response.json())
            .then(data => {
                const discoveryDiv = document.getElementById('service-discovery');
                discoveryDiv.innerHTML = '';
                data.services.forEach(service => {
                    const serviceDiv = document.createElement('div');
                    serviceDiv.innerHTML = `
                        <p><strong>${service.name}:</strong> ${service.endpoints.join(', ')}</p>
                        <pre>Environment: ${service.environment} | Health: ${service.health}</pre>
                    `;
                    discoveryDiv.appendChild(serviceDiv);
                });
            });
    </script>
</body>
</html>
EOF

# Create API endpoints for shared services information
cat > /var/www/html/instance-info << 'EOF'
#!/bin/bash
echo "Content-Type: application/json"
echo ""

# Get instance metadata
HOSTNAME=$(hostname)
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
VPC_ID=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/)/vpc-id)
AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)

cat << JSON
{
  "hostname": "$HOSTNAME",
  "private_ip": "$PRIVATE_IP",
  "vpc_id": "$VPC_ID",
  "availability_zone": "$AZ",
  "role": "shared-services",
  "instance_name": "${instance_name}",
  "services": ["dns", "monitoring", "health-checks"]
}
JSON
EOF

# Create DNS status endpoint
cat > /var/www/html/dns-status << 'EOF'
#!/bin/bash
echo "Content-Type: application/json"
echo ""

DOMAIN="${domain_name}"

echo "{"
echo '  "zones": ['

# Check private zone status
echo -n '    {"name": "'$DOMAIN'", '
if nslookup production.$DOMAIN > /dev/null 2>&1; then
  RECORD_COUNT=$(dig @169.254.169.253 $DOMAIN ANY +short | wc -l)
  echo -n '"status": "active", "record_count": '$RECORD_COUNT'}'
else
  echo -n '"status": "inactive", "record_count": 0}'
fi

echo ''
echo '  ]'
echo '}'
EOF

# Create connectivity matrix endpoint
cat > /var/www/html/connectivity-matrix << 'EOF'
#!/bin/bash
echo "Content-Type: application/json"
echo ""

DOMAIN="${domain_name}"

echo "{"
echo '  "connections": ['

# Test production to development
echo -n '    {"source": "Production VPC", "target": "Development VPC", '
if timeout 3 curl -s http://development.$DOMAIN/health > /dev/null 2>&1; then
  LATENCY=$(timeout 3 curl -w "%{time_total}" -s -o /dev/null http://development.$DOMAIN/health 2>/dev/null || echo "timeout")
  echo -n '"status": "connected", "latency": "'$LATENCY's"}'
else
  echo -n '"status": "disconnected", "latency": "N/A"}'
fi

echo ','

# Test development to production
echo -n '    {"source": "Development VPC", "target": "Production VPC", '
if timeout 3 curl -s http://production.$DOMAIN/health > /dev/null 2>&1; then
  LATENCY=$(timeout 3 curl -w "%{time_total}" -s -o /dev/null http://production.$DOMAIN/health 2>/dev/null || echo "timeout")
  echo -n '"status": "connected", "latency": "'$LATENCY's"}'
else
  echo -n '"status": "disconnected", "latency": "N/A"}'
fi

echo ','

# Test shared to production
echo -n '    {"source": "Shared VPC", "target": "Production VPC", '
if timeout 3 curl -s http://production.$DOMAIN/health > /dev/null 2>&1; then
  LATENCY=$(timeout 3 curl -w "%{time_total}" -s -o /dev/null http://production.$DOMAIN/health 2>/dev/null || echo "timeout")
  echo -n '"status": "connected", "latency": "'$LATENCY's"}'
else
  echo -n '"status": "disconnected", "latency": "N/A"}'
fi

echo ','

# Test shared to development
echo -n '    {"source": "Shared VPC", "target": "Development VPC", '
if timeout 3 curl -s http://development.$DOMAIN/health > /dev/null 2>&1; then
  LATENCY=$(timeout 3 curl -w "%{time_total}" -s -o /dev/null http://development.$DOMAIN/health 2>/dev/null || echo "timeout")
  echo -n '"status": "connected", "latency": "'$LATENCY's"}'
else
  echo -n '"status": "disconnected", "latency": "N/A"}'
fi

echo ''
echo '  ]'
echo '}'
EOF

# Create service discovery endpoint
cat > /var/www/html/service-discovery << 'EOF'
#!/bin/bash
echo "Content-Type: application/json"
echo ""

DOMAIN="${domain_name}"

echo "{"
echo '  "services": ['

# Production services
echo -n '    {"name": "Production Cluster", "environment": "production", '
PROD_IPS=$(dig +short production.$DOMAIN | tr '\n' ',' | sed 's/,$//')
if [ -n "$PROD_IPS" ]; then
  echo -n '"endpoints": ["'$(echo $PROD_IPS | sed 's/,/", "/g')'"], "health": "healthy"}'
else
  echo -n '"endpoints": [], "health": "unknown"}'
fi

echo ','

# Development services
echo -n '    {"name": "Development Cluster", "environment": "development", '
DEV_IPS=$(dig +short development.$DOMAIN | tr '\n' ',' | sed 's/,$//')
if [ -n "$DEV_IPS" ]; then
  echo -n '"endpoints": ["'$(echo $DEV_IPS | sed 's/,/", "/g')'"], "health": "healthy"}'
else
  echo -n '"endpoints": [], "health": "unknown"}'
fi

echo ','

# DNS service
echo -n '    {"name": "DNS Service", "environment": "shared", '
DNS_IP=$(dig +short dns.$DOMAIN | head -1)
if [ -n "$DNS_IP" ]; then
  echo -n '"endpoints": ["'$DNS_IP'"], "health": "healthy"}'
else
  echo -n '"endpoints": [], "health": "unknown"}'
fi

echo ','

# Monitoring service
echo -n '    {"name": "Monitoring Service", "environment": "shared", '
MON_IP=$(dig +short monitoring.$DOMAIN | head -1)
if [ -n "$MON_IP" ]; then
  echo -n '"endpoints": ["'$MON_IP'"], "health": "healthy"}'
else
  echo -n '"endpoints": [], "health": "unknown"}'
fi

echo ''
echo '  ]'
echo '}'
EOF

# Make scripts executable
chmod +x /var/www/html/instance-info
chmod +x /var/www/html/dns-status
chmod +x /var/www/html/connectivity-matrix
chmod +x /var/www/html/service-discovery

# Configure Apache for CGI
echo "ScriptAlias /instance-info /var/www/html/instance-info" >> /etc/httpd/conf/httpd.conf
echo "ScriptAlias /dns-status /var/www/html/dns-status" >> /etc/httpd/conf/httpd.conf
echo "ScriptAlias /connectivity-matrix /var/www/html/connectivity-matrix" >> /etc/httpd/conf/httpd.conf
echo "ScriptAlias /service-discovery /var/www/html/service-discovery" >> /etc/httpd/conf/httpd.conf

# Create health check endpoint
cat > /var/www/html/health << 'EOF'
#!/bin/bash
echo "Content-Type: application/json"
echo ""
echo '{"status": "healthy", "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'", "role": "shared-services", "instance": "${instance_name}"}'
EOF

chmod +x /var/www/html/health
echo "ScriptAlias /health /var/www/html/health" >> /etc/httpd/conf/httpd.conf

# Restart Apache to apply configuration
systemctl restart httpd

# Configure DNS forwarding (optional)
cat > /etc/dnsmasq.conf << 'EOF'
# Multi-VPC DNS forwarding configuration
port=5353
bind-interfaces
listen-address=127.0.0.1

# Forward queries for internal domain to Route 53
server=/${domain_name}/169.254.169.253

# Cache settings
cache-size=1000
neg-ttl=60

# Logging
log-queries
log-facility=/var/log/dnsmasq.log
EOF

# Start and enable dnsmasq (optional DNS caching)
systemctl start dnsmasq
systemctl enable dnsmasq

# Create multi-VPC DNS monitoring script
cat > /home/ec2-user/monitor-dns.sh << 'EOF'
#!/bin/bash
echo "=== Multi-VPC DNS Monitoring ==="
echo "Instance: ${instance_name}"
echo "Domain: ${domain_name}"
echo "Timestamp: $(date)"
echo ""

echo "=== DNS Zone Health ==="
# Check if private zone is responding
if nslookup production.${domain_name} > /dev/null 2>&1; then
  echo "✓ Private zone ${domain_name} is responding"
  echo "  Records found: $(dig @169.254.169.253 ${domain_name} ANY +short | wc -l)"
else
  echo "✗ Private zone ${domain_name} is not responding"
fi
echo ""

echo "=== Service Discovery Status ==="
# Check each service
for service in production development dns monitoring all-apps; do
  echo -n "Checking $service.${domain_name}: "
  if nslookup $service.${domain_name} > /dev/null 2>&1; then
    IPS=$(dig +short $service.${domain_name} | tr '\n' ' ')
    echo "✓ Resolved to: $IPS"
  else
    echo "✗ Failed to resolve"
  fi
done
echo ""

echo "=== Cross-VPC Connectivity ==="
# Test HTTP connectivity to each environment
for env in production development; do
  echo -n "Testing HTTP to $env cluster: "
  if timeout 5 curl -s http://$env.${domain_name}/health > /dev/null 2>&1; then
    echo "✓ Connected"
  else
    echo "✗ Failed"
  fi
done
echo ""

echo "=== DNS Query Performance ==="
# Measure DNS query times
for service in production development dns; do
  echo -n "$service.${domain_name}: "
  TIME=$(time (nslookup $service.${domain_name} > /dev/null 2>&1) 2>&1 | grep real | awk '{print $2}')
  echo "$TIME"
done
echo ""

echo "=== VPC Peering Status ==="
# Check route table entries (requires AWS CLI)
if command -v aws > /dev/null 2>&1; then
  echo "Route tables configured for cross-VPC communication"
  # aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/)/vpc-id)" --query 'RouteTables[].Routes[?VpcPeeringConnectionId]'
else
  echo "AWS CLI not available for detailed route analysis"
fi
echo ""

echo "=== Summary ==="
echo "Multi-VPC DNS monitoring completed at $(date)"
EOF

chmod +x /home/ec2-user/monitor-dns.sh
chown ec2-user:ec2-user /home/ec2-user/monitor-dns.sh

# Set up periodic DNS monitoring (every 5 minutes)
cat > /etc/cron.d/dns-monitoring << 'EOF'
*/5 * * * * ec2-user /home/ec2-user/monitor-dns.sh >> /var/log/dns-monitoring.log 2>&1
EOF

# Log completion
echo "$(date): ${instance_name} shared services setup completed" >> /var/log/user-data.log
