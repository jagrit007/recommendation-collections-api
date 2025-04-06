#!/bin/bash
# User data script for EC2 instance setup
app_name = recommendation-collections-api

# Update system packages
apt-get update
apt-get upgrade -y

# Install Node.js and npm
curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
apt-get install -y nodejs git

# Install PM2 for process management
npm install -g pm2

# Create app directory
mkdir -p /var/www/${app_name}
cd /var/www/${app_name}

# Clone application repository (replace with your actual repository)
git clone https://github.com/jagrit007/${app_name}.git .

# Install dependencies
npm install

# Create .env file
cat > .env << EOL
DATABASE_URL=your_neon_connection_string
PORT=3000
NODE_ENV=production
EOL

# Start application with PM2
pm2 start app.js --name=${app_name}
pm2 startup
pm2 save

# Install and configure Nginx (optional, if you want to use it as a reverse proxy)
apt-get install -y nginx

# Configure Nginx as reverse proxy
cat > /etc/nginx/sites-available/default << EOL
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOL

# Restart Nginx
systemctl restart nginx