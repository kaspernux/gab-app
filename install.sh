#!/bin/sh

# Print GAB APP ASCII art
printf "
  ____  _   _ ____ ____      _    ____ _  __
 / ___|| | | / ___|  _ \    / \  / ___| |/ /
 \___ \| | | \___ \| |_) |  / _ \| |   | ' / 
  ___) | |_| |___) |  __/  / ___ \ |___| . \ 
 |____/ \___/|____/|_|    /_/   \_\____|_|\_\
                                             
"

# Install Docker
sudo apt update
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Node.js repository and install Node.js and npm
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
NODE_MAJOR=20
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
sudo apt-get update && sudo apt-get install nodejs -y

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Set permissions
chmod +x gab-app/scripts/*.sh

# Install LEMP stack
sudo apt install nginx mysql-server software-properties-common -y

# Add repository for latest PHP version
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update

# Install the latest PHP version
sudo apt install php php-fpm php-mysql php-common php-mbstring php-xmlrpc php-soap php-gd php-xml php-cli php-zip php-curl certbot python3-certbot-nginx -y

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

# Clone the repository
git clone https://github.com/kaspernux/gab-app.git "$APP_DIR"

# Define the directory where your app will be deployed
APP_DIR="gab-app"

# Change directory to the app directory
cd "$APP_DIR" || exit

# Just to be sure that no traces left
docker-compose down -v

# Building and running docker-compose file
docker-compose build && docker-compose up -d

# Container ID by image name
nginx_container_id=$(docker ps -aqf "name=${NGINX_CONTAINER_NAME}")
db_container_id=$(docker ps -aqf "name=${DB_CONTAINER_NAME}")

# Checking connection
echo "Please wait... Waiting for MySQL connection..."
while ! docker exec ${db_container_id} mysql --user=root --password="${MYSQL_ROOT_PASSWORD}" -e "SELECT 1" >/dev/null 2>&1; do
    sleep 1
done

# Creating empty database for Gabapp
echo "Creating empty database for Gabapp..."
while ! docker exec ${db_container_id} mysql --user=root --password="${MYSQL_ROOT_PASSWORD}" -e "CREATE DATABASE ${MYSQL_GABAPP_DB} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" >/dev/null 2>&1; do
    sleep 1
done

# Creating empty database for Gabapp testing
echo "Creating empty database for Gabapp testing..."
while ! docker exec ${db_container_id} mysql --user=root --password="${MYSQL_ROOT_PASSWORD}" -e "CREATE DATABASE ${MYSQL_GABAPP_TESTING_DB} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" >/dev/null 2>&1; do
    sleep 1
done

# Setting up Gabapp
echo "Now, setting up Gabapp..."
docker exec ${nginx_container_id} git clone https://github.com/bagisto/bagisto /var/www/html/gab-app

# Setting Gabapp stable version
echo "Now, setting up Gabapp stable version..."
docker exec -i ${nginx_container_id} bash -c "cd /var/www/html/gab-app && git reset --hard $(git describe --tags $(git rev-list --tags --max-count=1))"

# Installing Composer dependencies inside container
docker exec -i ${nginx_container_id} bash -c "cd /var/www/html/gab-app && composer install --no-dev"

# Generate application key and capture the output
app_key=$(docker exec ${nginx_container_id} php artisan key:generate | grep "Your application key is" | awk '{print $5}')

# Replace placeholder with the generated APP_KEY in .env file
sed -i "s/APP_KEY=.*/APP_KEY=${app_key}/" .configs/.env

# Moving `.env` file
docker cp .configs/.env ${nginx_container_id}:/var/www/html/gab-app/.env
docker cp .configs/.env.testing ${nginx_container_id}:/var/www/html/gab-app/.env.testing

# Executing final commands
docker exec -i ${nginx_container_id} bash -c "cd /var/www/html/gab-app && php artisan optimize:clear && php artisan migrate:fresh --seed && php artisan storage:link && php artisan bagisto:publish --force && php artisan optimize:clear"

# Update the .env file inside the container
docker exec ${nginx_container_id} bash -c "cp /var/www/html/gab-app/.env /var/www/html/gab-app/.env.example"

# Executing final commands
docker exec -i ${nginx_container_id} bash -c "cd /var/www/html/gab-app && php artisan optimize:clear && php artisan migrate:fresh --seed && php artisan storage:link && php artisan bagisto:publish --force && php artisan optimize:clear"

# Just to be sure that no traces left
docker-compose down -v

# Building and running docker-compose file
docker-compose build && docker-compose up -d

echo "Setup completed successfully!"
