#!/bin/bash
apt-get update -y
apt-get install -y nginx
systemctl start nginx
systemctl enable nginx

TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)

# 5. REMOVE the default Ubuntu boilerplate page so it doesn't block your custom code
rm -f /var/www/html/index.nginx-debian.html

cat > /usr/share/nginx/html/index.html <<HTML
<!DOCTYPE html>
<html>
<head><title>Terraform + ASG</title></head>
<body>
  <h1>Deployed via Terraform</h1>
  <p>Instance ID: $INSTANCE_ID</p>
  <p>This instance is part of an Auto Scaling Group</p>
</body>
</html>
HTML
