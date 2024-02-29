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
PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;');

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

# Create MySQL database and user for Laravel
MYSQL_ROOT_PASSWORD="your_mysql_root_password"
MYSQL_LARAVEL_DB="laravel_db"
MYSQL_LARAVEL_USER="laravel_user"
MYSQL_LARAVEL_PASSWORD="laravel_password"

sudo mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS ${MYSQL_LARAVEL_DB};
CREATE USER IF NOT EXISTS '${MYSQL_LARAVEL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_LARAVEL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_LARAVEL_DB}.* TO '${MYSQL_LARAVEL_USER}'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# Update Laravel application's .env file with MySQL database configuration
sed -i "s/DB_DATABASE=.*/DB_DATABASE=${MYSQL_LARAVEL_DB}/" /path/to/your/laravel/project/.env.example
sed -i "s/DB_USERNAME=.*/DB_USERNAME=${MYSQL_LARAVEL_USER}/" /path/to/your/laravel/project/.env.example
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=${MYSQL_LARAVEL_PASSWORD}/" /path/to/your/laravel/project/.env.example

# Restart PHP-FPM
sudo systemctl restart php"${PHP_VERSION}"-fpm

# Obtain SSL certificate
sudo certbot --nginx

# Configure firewall (UFW)
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw enable

echo "Setup completed successfully!"
