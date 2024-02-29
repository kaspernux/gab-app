#!/bin/bash

# Set permissions
chmod +x *.sh

# Install LEMP stack
sudo apt update
sudo apt install nginx mysql-server software-properties-common -y

# Add repository for latest PHP version
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update

# Install the latest PHP version
sudo apt install php php-fpm php-mysql php-common php-mbstring php-xmlrpc php-soap php-gd php-xml php-cli php-zip php-curl certbot python3-certbot-nginx -y

# Get the installed PHP version
PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')

# Start and enable services
sudo systemctl start nginx
sudo systemctl enable nginx
sudo systemctl start mysql
sudo systemctl enable mysql
sudo systemctl start php"${PHP_VERSION}"-fpm
sudo systemctl enable php"${PHP_VERSION}"-fpm

# Backup the default Nginx configuration
sudo mv /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak

# Configure Nginx
sudo cp configurations/nginx/default.conf /etc/nginx/sites-available/default
sudo nginx -t
sudo systemctl reload nginx

# Secure MySQL installation
sudo mysql_secure_installation

# Backup php.ini
sudo cp /etc/php/"${PHP_VERSION}"/fpm/php.ini /etc/php/"${PHP_VERSION}"/fpm/php.ini.bak

# Update php.ini settings
sudo sed -i 's/memory_limit = .*/memory_limit = 256M/' /etc/php/"${PHP_VERSION}"/fpm/php.ini
sudo sed -i 's/upload_max_filesize = .*/upload_max_filesize = 100M/' /etc/php/"${PHP_VERSION}"/fpm/php.ini
sudo sed -i 's/post_max_size = .*/post_max_size = 100M/' /etc/php/"${PHP_VERSION}"/fpm/php.ini
sudo sed -i 's/max_execution_time = .*/max_execution_time = 300/' /etc/php/"${PHP_VERSION}"/fpm/php.ini

# Restart PHP-FPM
sudo systemctl restart php"${PHP_VERSION}"-fpm

# Obtain SSL certificate
sudo certbot --nginx

# Configure firewall (UFW)
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw enable

echo "Setup completed successfully!"
