#!/bin/bash

# Set permissions
chmod +x gab-app/scripts/*.sh

# Install LEMP stack
sudo apt update
sudo apt install nginx mysql-server software-properties-common -y

# Add repository for latest PHP version
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update

# Install the latest PHP version
sudo apt install php php-fpm php-mysql php-common php-mbstring php-xmlrpc php-soap php-gd php-xml php-cli php-zip php-curl certbot python3-certbot-nginx -y

# Install Node.js and npm
curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt install nodejs -y

# Get the installed PHP version
PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;');

# Retrieve server timezone
SERVER_TIMEZONE=$(timedatectl | grep "Time zone" | awk '{print $3}')

# Replace placeholder with server timezone in PHP configuration
sed -i "s|date.timezone = \"Your/Timezone\"|date.timezone = \"${SERVER_TIMEZONE}\"|" gab-app/configurations/php/php.ini

# Extract PHP version
PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;');

# Replace placeholder with actual PHP version in Nginx configuration
sed -i "s|fastcgi_pass unix:/var/run/php/php[0-9].[0-9]-fpm.sock;|fastcgi_pass unix:/var/run/php/php${PHP_VERSION}-fpm.sock;|" gab-app/configurations/nginx/default.conf

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
sudo cp gab-app/configurations/nginx/default.conf /etc/nginx/sites-available/default
sudo nginx -t
sudo systemctl reload nginx

# Secure MySQL installation
sudo mysql_secure_installation

# Create MySQL database and user for Laravel
MYSQL_ROOT_PASSWORD="root"
MYSQL_LARAVEL_DB="gab_app"
MYSQL_LARAVEL_USER="root"
MYSQL_LARAVEL_PASSWORD=$(openssl rand -base64 12)

sudo mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS ${MYSQL_LARAVEL_DB};
CREATE USER IF NOT EXISTS '${MYSQL_LARAVEL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_LARAVEL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_LARAVEL_DB}.* TO '${MYSQL_LARAVEL_USER}'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# Update Laravel application's .env file with MySQL database configuration
sed -i "s/DB_DATABASE=.*/DB_DATABASE=${MYSQL_LARAVEL_DB}/" gab-app/.env.example
sed -i "s/DB_USERNAME=.*/DB_USERNAME=${MYSQL_LARAVEL_USER}/" gab-app/.env.example
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=${MYSQL_LARAVEL_PASSWORD}/" gab-app/.env.example

# Set the application key
cd gab-app
php artisan key:generate

# Clear configuration cache
php artisan config:cache

# Restart PHP-FPM
sudo systemctl restart php"${PHP_VERSION}"-fpm

# Deploy Laravel application
gab-app/scripts/deploy-laravel.sh

# Install Composer dependencies
composer install --no-dev

# Hash the Laravel password
php artisan migrate --seed

# Obtain SSL certificate
sudo certbot --nginx

# Configure firewall (UFW)
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw enable

# Navigate to gab-app directory for Bagisto deployment
cd ..

# Download Bagisto project using Composer
composer create-project bagisto/bagisto gab-app

# Navigate to the Bagisto directory
cd gab-app

# Copy the .env.example file to .env
cp .env.example .env

# Set the environment variables in the .env file
# You may need to replace these values with your actual database and email credentials
sed -i "s/APP_URL=.*/APP_URL=http:\/\/example.com/" .env
sed -i "s/DB_CONNECTION=.*/DB_CONNECTION=mysql/" .env
sed -i "s/DB_HOST=.*/DB_HOST=127.0.0.1/" .env
sed -i "s/DB_PORT=.*/DB_PORT=3306/" .env
sed -i "s/DB_DATABASE=.*/DB_DATABASE=gab_app/" .env
sed -i "s/DB_USERNAME=.*/DB_USERNAME=root/" .env
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=root/" .env

# Generate the application key
php artisan key:generate

# Run database migrations
php artisan migrate

# Seed the database with default data
php artisan db:seed

# Publish configuration and assets
php artisan vendor:publish

# Create a symbolic link for the storage directory
php artisan storage:link

echo "Setup completed successfully!"
