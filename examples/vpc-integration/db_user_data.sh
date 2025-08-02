#!/bin/bash
# User data script for database servers

# Update system
yum update -y

# Install MySQL and tools
yum install -y mysql-server htop curl wget bind-utils

# Start and enable MySQL
systemctl start mysqld
systemctl enable mysqld

# Install and configure a simple web server for health checks
yum install -y httpd
systemctl start httpd
systemctl enable httpd

# Create health check endpoint
cat > /var/www/html/health << 'EOF'
DB-OK
EOF

# Create database status page
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Database Server - VPC DNS Integration</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f5f5f5; }
        .container { background-color: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #333; }
        .info { background-color: #ffe7e7; padding: 15px; border-radius: 4px; margin: 20px 0; }
        .dns-test { background-color: #f0f8f0; padding: 15px; border-radius: 4px; margin: 20px 0; }
        pre { background-color: #f4f4f4; padding: 10px; border-radius: 4px; overflow-x: auto; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🗄️ Database Server - VPC DNS Integration</h1>
        <p>This database server demonstrates private DNS resolution within the VPC.</p>
        
        <div class="info">
            <strong>Database Instance Information:</strong><br>
            Instance Name: ${instance_name}<br>
            Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)<br>
            Private IP: $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)<br>
            Availability Zone: $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)<br>
            Private Domain: ${domain_name}<br>
            MySQL Status: $(systemctl is-active mysqld)
        </div>

        <div class="dns-test">
            <strong>DNS Resolution Tests:</strong><br>
            <pre id="dns-results">Loading DNS test results...</pre>
        </div>

        <script>
            // Test DNS resolution and display results
            fetch('/dns-test')
                .then(response => response.text())
                .then(data => {
                    document.getElementById('dns-results').textContent = data;
                })
                .catch(error => {
                    document.getElementById('dns-results').textContent = 'DNS test failed: ' + error;
                });
        </script>
    </div>
</body>
</html>
EOF

# Create DNS test endpoint for database server
cat > /var/www/html/dns-test << 'EOF'
#!/bin/bash
echo "Content-Type: text/plain"
echo ""

echo "=== Database Server DNS Tests ==="
echo ""

echo "1. Resolving web servers:"
echo "   web-1.${domain_name}:"
nslookup web-1.${domain_name} 2>/dev/null || echo "   Failed to resolve"
echo "   web-2.${domain_name}:"
nslookup web-2.${domain_name} 2>/dev/null || echo "   Failed to resolve"
echo ""

echo "2. Resolving other database servers:"
echo "   db-primary.${domain_name}:"
nslookup db-primary.${domain_name} 2>/dev/null || echo "   Failed to resolve"
echo "   db-replica.${domain_name}:"
nslookup db-replica.${domain_name} 2>/dev/null || echo "   Failed to resolve"
echo "   database.${domain_name} (alias):"
nslookup database.${domain_name} 2>/dev/null || echo "   Failed to resolve"
echo ""

echo "3. Resolving load balancer:"
echo "   lb-internal.${domain_name}:"
nslookup lb-internal.${domain_name} 2>/dev/null || echo "   Failed to resolve"
echo ""

echo "4. Testing connectivity:"
if ping -c 1 web-1.${domain_name} >/dev/null 2>&1; then
    echo "   ✓ Can ping web-1.${domain_name}"
else
    echo "   ✗ Cannot ping web-1.${domain_name}"
fi
echo ""

echo "5. MySQL Service Status:"
systemctl is-active mysqld
echo ""

echo "6. Current hostname:"
hostname
echo ""

echo "7. Private DNS resolver:"
echo "   Using resolver: 169.254.169.253"
echo ""

echo "8. /etc/resolv.conf:"
cat /etc/resolv.conf
EOF

chmod +x /var/www/html/dns-test

# Configure Apache to handle the DNS test script
cat >> /etc/httpd/conf/httpd.conf << 'EOF'

# Enable CGI for DNS test
<Directory "/var/www/html">
    Options +ExecCGI
    AddHandler cgi-script .cgi
</Directory>

# Handle dns-test as CGI
<Files "dns-test">
    SetHandler cgi-script
</Files>
EOF

# Restart Apache to apply configuration
systemctl restart httpd

# Configure MySQL (basic setup)
mysql -e "CREATE DATABASE IF NOT EXISTS testdb;" 2>/dev/null || echo "MySQL setup will be completed after secure installation"

# Create status file
cat > /home/ec2-user/instance-status.txt << EOF
Instance: ${instance_name}
Started: $(date)
Private Domain: ${domain_name}
Role: Database Server
MySQL Status: $(systemctl is-active mysqld)
Status: Database server configured and running
EOF

chown ec2-user:ec2-user /home/ec2-user/instance-status.txt

# Log completion
echo "Database server setup completed at $(date)" >> /var/log/user-data.log
