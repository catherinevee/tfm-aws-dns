#!/bin/bash
# User data script for application servers in multi-VPC environment

# Update system
yum update -y

# Install required packages
yum install -y httpd bind-utils telnet nc

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Create application info page
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>${instance_name} - ${environment}</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .header { background: #f0f0f0; padding: 20px; border-radius: 5px; }
        .section { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
        .environment { color: #007acc; font-weight: bold; }
        .success { color: green; }
        .error { color: red; }
        pre { background: #f5f5f5; padding: 10px; border-radius: 3px; overflow-x: auto; }
    </style>
</head>
<body>
    <div class="header">
        <h1>${instance_name}</h1>
        <p class="environment">Environment: ${environment}</p>
        <p>Multi-VPC DNS Integration Demo</p>
    </div>

    <div class="section">
        <h2>Instance Information</h2>
        <p><strong>Hostname:</strong> <span id="hostname">Loading...</span></p>
        <p><strong>Private IP:</strong> <span id="private-ip">Loading...</span></p>
        <p><strong>VPC ID:</strong> <span id="vpc-id">Loading...</span></p>
        <p><strong>Availability Zone:</strong> <span id="az">Loading...</span></p>
    </div>

    <div class="section">
        <h2>DNS Resolution Tests</h2>
        <div id="dns-tests">Loading DNS tests...</div>
    </div>

    <div class="section">
        <h2>Cross-VPC Connectivity</h2>
        <div id="connectivity-tests">Loading connectivity tests...</div>
    </div>

    <script>
        // Load instance metadata
        fetch('/instance-info')
            .then(response => response.json())
            .then(data => {
                document.getElementById('hostname').textContent = data.hostname;
                document.getElementById('private-ip').textContent = data.private_ip;
                document.getElementById('vpc-id').textContent = data.vpc_id;
                document.getElementById('az').textContent = data.availability_zone;
            });

        // Load DNS tests
        fetch('/dns-tests')
            .then(response => response.json())
            .then(data => {
                const testsDiv = document.getElementById('dns-tests');
                testsDiv.innerHTML = '';
                data.tests.forEach(test => {
                    const testDiv = document.createElement('div');
                    testDiv.innerHTML = `
                        <p><strong>${test.name}:</strong> 
                        <span class="${test.success ? 'success' : 'error'}">
                            ${test.success ? 'SUCCESS' : 'FAILED'}
                        </span></p>
                        <pre>${test.result}</pre>
                    `;
                    testsDiv.appendChild(testDiv);
                });
            });

        // Load connectivity tests
        fetch('/connectivity-tests')
            .then(response => response.json())
            .then(data => {
                const testsDiv = document.getElementById('connectivity-tests');
                testsDiv.innerHTML = '';
                data.tests.forEach(test => {
                    const testDiv = document.createElement('div');
                    testDiv.innerHTML = `
                        <p><strong>${test.name}:</strong> 
                        <span class="${test.success ? 'success' : 'error'}">
                            ${test.success ? 'SUCCESS' : 'FAILED'}
                        </span></p>
                        <pre>${test.result}</pre>
                    `;
                    testsDiv.appendChild(testDiv);
                });
            });
    </script>
</body>
</html>
EOF

# Create API endpoints for instance information
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
  "environment": "${environment}",
  "instance_name": "${instance_name}"
}
JSON
EOF

# Create DNS tests endpoint
cat > /var/www/html/dns-tests << 'EOF'
#!/bin/bash
echo "Content-Type: application/json"
echo ""

# DNS test targets for multi-VPC environment
DOMAIN="${domain_name}"

echo "{"
echo '  "tests": ['

# Test 1: Resolve production cluster
echo -n '    {"name": "Production Cluster", '
if nslookup production.$DOMAIN > /dev/null 2>&1; then
  RESULT=$(nslookup production.$DOMAIN 2>&1 | grep -A 10 "Non-authoritative answer:")
  echo -n '"success": true, "result": "'$(echo "$RESULT" | sed 's/"/\\"/g' | tr '\n' ' ')'"}'
else
  echo -n '"success": false, "result": "Failed to resolve production.'$DOMAIN'"}'
fi

echo ','

# Test 2: Resolve development cluster
echo -n '    {"name": "Development Cluster", '
if nslookup development.$DOMAIN > /dev/null 2>&1; then
  RESULT=$(nslookup development.$DOMAIN 2>&1 | grep -A 10 "Non-authoritative answer:")
  echo -n '"success": true, "result": "'$(echo "$RESULT" | sed 's/"/\\"/g' | tr '\n' ' ')'"}'
else
  echo -n '"success": false, "result": "Failed to resolve development.'$DOMAIN'"}'
fi

echo ','

# Test 3: Resolve shared services
echo -n '    {"name": "Shared DNS Service", '
if nslookup dns.$DOMAIN > /dev/null 2>&1; then
  RESULT=$(nslookup dns.$DOMAIN 2>&1 | grep -A 10 "Non-authoritative answer:")
  echo -n '"success": true, "result": "'$(echo "$RESULT" | sed 's/"/\\"/g' | tr '\n' ' ')'"}'
else
  echo -n '"success": false, "result": "Failed to resolve dns.'$DOMAIN'"}'
fi

echo ','

# Test 4: Resolve all apps
echo -n '    {"name": "All Applications", '
if nslookup all-apps.$DOMAIN > /dev/null 2>&1; then
  RESULT=$(nslookup all-apps.$DOMAIN 2>&1 | grep -A 20 "Non-authoritative answer:")
  echo -n '"success": true, "result": "'$(echo "$RESULT" | sed 's/"/\\"/g' | tr '\n' ' ')'"}'
else
  echo -n '"success": false, "result": "Failed to resolve all-apps.'$DOMAIN'"}'
fi

echo ''
echo '  ]'
echo '}'
EOF

# Create connectivity tests endpoint
cat > /var/www/html/connectivity-tests << 'EOF'
#!/bin/bash
echo "Content-Type: application/json"
echo ""

DOMAIN="${domain_name}"

echo "{"
echo '  "tests": ['

# Test 1: HTTP connectivity to production cluster
echo -n '    {"name": "HTTP to Production", '
if timeout 5 curl -s http://production.$DOMAIN > /dev/null 2>&1; then
  echo -n '"success": true, "result": "Successfully connected to production cluster"}'
else
  echo -n '"success": false, "result": "Failed to connect to production cluster via HTTP"}'
fi

echo ','

# Test 2: HTTP connectivity to development cluster
echo -n '    {"name": "HTTP to Development", '
if timeout 5 curl -s http://development.$DOMAIN > /dev/null 2>&1; then
  echo -n '"success": true, "result": "Successfully connected to development cluster"}'
else
  echo -n '"success": false, "result": "Failed to connect to development cluster via HTTP"}'
fi

echo ','

# Test 3: DNS service connectivity
echo -n '    {"name": "DNS Service Port", '
if timeout 5 nc -z dns.$DOMAIN 53 > /dev/null 2>&1; then
  echo -n '"success": true, "result": "DNS service port 53 is accessible"}'
else
  echo -n '"success": false, "result": "DNS service port 53 is not accessible"}'
fi

echo ''
echo '  ]'
echo '}'
EOF

# Make scripts executable
chmod +x /var/www/html/instance-info
chmod +x /var/www/html/dns-tests
chmod +x /var/www/html/connectivity-tests

# Configure Apache for CGI
echo "ScriptAlias /instance-info /var/www/html/instance-info" >> /etc/httpd/conf/httpd.conf
echo "ScriptAlias /dns-tests /var/www/html/dns-tests" >> /etc/httpd/conf/httpd.conf
echo "ScriptAlias /connectivity-tests /var/www/html/connectivity-tests" >> /etc/httpd/conf/httpd.conf

# Create health check endpoint
cat > /var/www/html/health << 'EOF'
#!/bin/bash
echo "Content-Type: application/json"
echo ""
echo '{"status": "healthy", "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'", "environment": "${environment}", "instance": "${instance_name}"}'
EOF

chmod +x /var/www/html/health
echo "ScriptAlias /health /var/www/html/health" >> /etc/httpd/conf/httpd.conf

# Restart Apache to apply configuration
systemctl restart httpd

# Create DNS resolution test script
cat > /home/ec2-user/test-dns.sh << 'EOF'
#!/bin/bash
echo "=== Multi-VPC DNS Resolution Tests ==="
echo "Environment: ${environment}"
echo "Instance: ${instance_name}"
echo "Domain: ${domain_name}"
echo ""

# Test internal DNS resolution
echo "Testing internal DNS resolution:"
echo "1. Production cluster:"
nslookup production.${domain_name}
echo ""

echo "2. Development cluster:"
nslookup development.${domain_name}
echo ""

echo "3. Shared DNS service:"
nslookup dns.${domain_name}
echo ""

echo "4. All applications:"
nslookup all-apps.${domain_name}
echo ""

echo "5. Configuration records:"
dig TXT _config.production.${domain_name} +short
dig TXT _config.development.${domain_name} +short
dig TXT _config.shared.${domain_name} +short
echo ""

echo "=== Connectivity Tests ==="
echo "Testing HTTP connectivity:"

# Test HTTP connectivity
for service in production development; do
  echo "Testing $service cluster:"
  if timeout 5 curl -s http://$service.${domain_name}/health; then
    echo " - HTTP connectivity: SUCCESS"
  else
    echo " - HTTP connectivity: FAILED"
  fi
  echo ""
done

echo "=== Network Information ==="
echo "Local IP: $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"
echo "VPC ID: $(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/)/vpc-id)"
echo "Subnet ID: $(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/)/subnet-id)"
EOF

chmod +x /home/ec2-user/test-dns.sh
chown ec2-user:ec2-user /home/ec2-user/test-dns.sh

# Log completion
echo "$(date): ${instance_name} application server setup completed" >> /var/log/user-data.log
