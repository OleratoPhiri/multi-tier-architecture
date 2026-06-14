#!/bin/bash
set -e
exec > /var/log/user-data.log 2>&1

echo "Starting user data script..."

# Update packages
yum update -y
echo "Packages updated"

# Install Apache
yum install -y httpd
echo "Apache installed"

# Start Apache
systemctl start httpd
systemctl enable httpd
echo "Apache started"

# Verify Apache is running
systemctl status httpd

# Create webpage
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Multi-Tier Architecture</title>
    <style>
        body {
            font-family: 'Segoe UI', sans-serif;
            background: #1a365d;
            color: white;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
        }
        .card {
            background: #2b6cb0;
            padding: 40px 60px;
            border-radius: 12px;
            text-align: center;
            box-shadow: 0 8px 32px rgba(0,0,0,0.3);
        }
        h1 { font-size: 2rem; margin-bottom: 10px; }
        p  { opacity: 0.85; margin: 6px 0; }
        .badge {
            display: inline-block;
            background: #48bb78;
            color: white;
            padding: 4px 14px;
            border-radius: 20px;
            font-size: 0.85rem;
            margin-top: 16px;
        }
    </style>
</head>
<body>
    <div class="card">
        <h1>☁️ Multi-Tier Architecture</h1>
        <p>AWS · VPC · EC2 · RDS · Auto Scaling</p>
        <hr style="opacity:0.3; margin: 20px 0">
        <p><strong>Server is running!</strong></p>
        <div class="badge">✅ Healthy</div>
    </div>
</body>
</html>
EOF

echo "Webpage created"
echo "User data script completed successfully"