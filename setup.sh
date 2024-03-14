#!/bin/bash

# Function to handle errors
handle_error() {
    echo -e "\e[31mError: $1\e[0m" >&2
    exit 1
}

# Function to backup a file or directory
backup_file() {
    local file="$1"
    if [ -e "$file" ]; then
        if [ ! -e "$file.backup" ]; then
            cp -r "$file" "$file.backup" || handle_error "Failed to backup $file"
            echo "Backup created: $file.backup"
        else
            echo "Backup already exists: $file.backup"
        fi
    fi
}

# Function to check for conflicting packages and old files
check_conflicts() {
    echo "Checking for conflicting packages and old files..."

    local apache_conf="/etc/apache2/sites-available/gab-app.conf"
    local mysql_conf="/etc/mysql/mysql.conf.d/mysqld.cnf"
    local laravel_dir="/var/www/html/gab-app"

    # Backup existing Apache configuration file
    [ -f "$apache_conf" ] && {
        echo "Apache configuration file already exists. Creating a backup..."
        backup_file "$apache_conf"
    }

    # Backup existing MySQL configuration file
    [ -f "$mysql_conf" ] && {
        echo "MySQL configuration file already exists. Creating a backup..."
        backup_file "$mysql_conf"
    }

    # Backup and remove old Laravel project directory
    [ -d "$laravel_dir" ] && {
        echo "Old Laravel project directory exists. Backing up and removing..."
        backup_file "$laravel_dir"
        echo "Removing old Laravel project directory..."
        rm -rf "$laravel_dir" || handle_error "Failed to remove old Laravel project directory"
    }
}

# Print GAB APP ASCII art
printf "\e[34m
 ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄               ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄ 
▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░▌             ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌
▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌            ▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌
▐░▌          ▐░▌       ▐░▌▐░▌       ▐░▌            ▐░▌       ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌
▐░▌ ▄▄▄▄▄▄▄▄ ▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄█░▌▄▄▄▄▄▄▄▄▄▄▄ ▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄█░▌
▐░▌▐░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌
▐░▌ ▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌▀▀▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀▀▀ 
▐░▌       ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌            ▐░▌       ▐░▌▐░▌          ▐░▌          
▐░█▄▄▄▄▄▄▄█░▌▐░▌       ▐░▌▐░█▄▄▄▄▄▄▄█░▌            ▐░▌       ▐░▌▐░▌          ▐░▌          
▐░░░░░░░░░░░▌▐░▌       ▐░▌▐░░░░░░░░░░▌             ▐░▌       ▐░▌▐░▌          ▐░▌          
 ▀▀▀▀▀▀▀▀▀▀▀  ▀         ▀  ▀▀▀▀▀▀▀▀▀▀               ▀         ▀  ▀            ▀                                                                                                                                                                                                                                        
                                                                
\e[0m"

# Define colors
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# Check root privilege
if [ "$(id -u)" -ne 0 ]; then
    handle_error "Please run this script with root privilege"
fi

# Backup existing data and configurations
check_conflicts

# Add error handling
set -e

# Prompt user for server domain or IP address
read -p $'\e[32mEnter server domain or IP address:\e[0m ' server_domain

# Check if the directory exists, if not, create it
if [ ! -d "/var/www/html/gab-app" ]; then
    mkdir -p /var/www/html/gab-app
fi

# OS detection and version check
source /etc/os-release || handle_error "Failed to check the system OS"
case "$ID" in
    centos)
        [ "${VERSION_ID%%.*}" -lt 8 ] && handle_error "Please use CentOS 8 or higher"
        ;;
    ubuntu)
        [ "${VERSION_ID%%.*}" -lt 20 ] && handle_error "Please use Ubuntu 20 or higher version!"
        ;;
    fedora)
        [ "${VERSION_ID%%.*}" -lt 36 ] && handle_error "Please use Fedora 36 or higher version!"
        ;;
    debian)
        [ "${VERSION_ID%%.*}" -lt 11 ] && handle_error "Please use Debian 11 or higher"
        ;;
    almalinux)
        [ "${VERSION_ID%%.*}" -lt 9 ] && handle_error "Please use AlmaLinux 9 or higher"
        ;;
    rocky)
        [ "${VERSION_ID%%.*}" -lt 9 ] && handle_error "Please use RockyLinux 9 or higher"
        ;;
    arch|manjaro|armbian)
        echo "Your OS is supported."
        ;;
    *)
        handle_error "Unsupported OS"
        ;;
esac

# Install LAMP stack
sudo apt install software-properties-common -y

# Install necessary dependencies
echo "Installing necessary dependencies..."
sudo apt update
sudo apt install -y \
    apache2 \
    mysql-server \
    php \
    php-mysql \
    php-cli \
    php-curl \
    php-gd \
    php-mbstring \
    php-xml \
    php-sqlite3\
    php-fpm \
    php-common \
    php-xmlrpc \
    php-soap \
    php-zip \
    composer \
    nodejs \
    npm \
    git \
    fail2ban

# Inform user about successful installation of dependencies
    echo -e "${green}Dependencies installed successfully.${plain}"

# Check if necessary packages are installed
packages=("apache2" "mysql-server" "php" "composer" "nodejs" "npm" "git")

# Enable Apache and MySQL services
    echo "Enabling Apache and MySQL services..."
    sudo systemctl enable apache2
    sudo systemctl enable mysql

    # Check if Apache and MySQL services are running
    if ! systemctl is-active --quiet apache2; then
        handle_error "Apache service failed to start."
    fi

    if ! systemctl is-active --quiet mysql; then
        handle_error "MySQL service failed to start."
    fi


for package in "${packages[@]}"; do
    if ! command -v "$package" &>/dev/null; then
        echo -e "${green}Installing $package...${plain}"
        sudo apt install "$package" -y
    else
        echo -e "${red}$package is already installed. Skipping installation.${plain}"
    fi
done

# Retrieve PHP version installed on the system
PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")

# Construct the path to the PHP configuration file
PHP_CONFIG_FILE="/etc/php/${PHP_VERSION}/apache2/php.ini"

# Check if the PHP configuration file exists
if [ ! -f "$PHP_CONFIG_FILE" ]; then
    # Fallback path for PHP configuration file
    PHP_CONFIG_FILE="/etc/php/${PHP_VERSION}/cli/php.ini"
fi

# Check if the PHP configuration file exists
if [ ! -f "$PHP_CONFIG_FILE" ]; then
    echo -e "${red}PHP configuration file not found.${plain}"
    exit 1
fi

# Retrieve server timezone
SERVER_TIMEZONE=$(timedatectl | grep "Time zone" | awk '{print $3}')

# Replace placeholder with server timezone in PHP configuration
sudo sed -i "s|;date.timezone =|date.timezone = \"${SERVER_TIMEZONE}\"|" "$PHP_CONFIG_FILE"

# Enable Apache modules
sudo a2enmod rewrite
sudo systemctl restart apache2

# Install phpMyAdmin
if [ ! -f "/etc/phpmyadmin/config.inc.php" ]; then
    echo -e "${green}Installing phpMyAdmin...${plain}"
    sudo apt install phpmyadmin -y

    # Configure phpMyAdmin
    sudo tee /etc/apache2/conf-available/phpmyadmin.conf > /dev/null <<EOF
    Alias /phpmyadmin /usr/share/phpmyadmin
    <Directory /usr/share/phpmyadmin>
        Options SymLinksIfOwnerMatch
        DirectoryIndex index.php

        <IfModule mod_php.c>
            <IfModule mod_mime.c>
                AddType application/x-httpd-php .php
            </IfModule>
            <FilesMatch ".+\.php$">
                SetHandler application/x-httpd-php
            </FilesMatch>

            php_flag magic_quotes_gpc Off
            php_flag track_vars On
            php_flag register_globals Off
            php_flag allow_url_fopen Off
            php_value include_path .
            php_admin_value upload_tmp_dir /var/lib/phpmyadmin/tmp
            php_admin_value open_basedir /usr/share/phpmyadmin/:/etc/phpmyadmin/:/var/lib/phpmyadmin/:/usr/share/php/php-gettext/:/usr/share/javascript/
        </IfModule>

        <IfModule mod_php7.c>
            <IfModule mod_mime.c>
                AddType application/x-httpd-php .php
            </IfModule>
            <FilesMatch ".+\.php$">
                SetHandler application/x-httpd-php
            </FilesMatch>

            php_flag magic_quotes_gpc Off
            php_flag track_vars On
            php_flag register_globals Off
            php_flag short_open_tag On
            php_flag register_argc_argv On
            php_flag mbstring.func_overload 0
            php_flag default_charset 'UTF-8'
            php_admin_value open_basedir /usr/share/phpmyadmin/:/etc/phpmyadmin/:/var/lib/phpmyadmin/:/usr/share/php/php-gettext/:/usr/share/javascript/
            php_admin_value upload_tmp_dir /var/lib/phpmyadmin/tmp
            php_admin_value session.save_path /var/lib/phpmyadmin/tmp
        </IfModule>

    </Directory>

    # Disallow web access to directories that don't need it
    <Directory /usr/share/phpmyadmin/templates>
        Require all denied
    </Directory>
    <Directory /usr/share/phpmyadmin/libraries>
        Require all denied
    </Directory>
    <Directory /usr/share/phpmyadmin/setup/lib>
        Require all denied
    </Directory>
EOF

    # Create a symbolic link for Apache configuration
    sudo ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-available/phpmyadmin.conf
    sudo a2enconf phpmyadmin
    sudo systemctl restart apache2
fi

# Check if Apache virtual host configuration exists, if not, create it
if [ ! -f "/etc/apache2/sites-available/gab-app.conf" ]; then
    cat >"/etc/apache2/sites-available/gab-app.conf" <<EOF
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html/gab-app/public
    <Directory /var/www/html/gab-app>
        Options -Indexes +FollowSymLinks +MultiViews
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF
    echo "Apache virtual host configuration created"
fi

# Install Laravel
if [ ! -f "/var/www/html/gab-app/composer.json" ]; then
    echo -e "${green}Installing Laravel...${plain}"
    cd /var/www/html || handle_error "Failed to change directory to /var/www/html"
    composer create-project --prefer-dist laravel/laravel gab-app
    cd gab-app || handle_error "Failed to change directory to /var/www/html/gab-app"
    composer install
    cp .env.example .env
    php artisan key:generate
    sudo chown -R www-data:www-data /var/www/html/gab-app
    sudo chmod -R 755 /var/www/html/gab-app/storage
    sudo chmod -R 755 /var/www/html/gab-app/bootstrap/cache

    # MySQL credentials for Laravel
    MYSQL_LARAVEL_DB="gab_app"
    MYSQL_LARAVEL_USER="gab_app_user"
    MYSQL_LARAVEL_PASSWORD=$(openssl rand -base64 12)

    # Save MySQL credentials
    sudo tee /root/mysql_credentials.txt > /dev/null <<EOF
    MySQL Database: ${MYSQL_LARAVEL_DB}
    MySQL User: ${MYSQL_LARAVEL_USER}
    MySQL Password: ${MYSQL_LARAVEL_PASSWORD}
EOF

    # Create MySQL database and user for Laravel
    sudo mysql -e \
    "CREATE DATABASE IF NOT EXISTS ${MYSQL_LARAVEL_DB} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci; \
    CREATE USER IF NOT EXISTS '${MYSQL_LARAVEL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_LARAVEL_PASSWORD}'; \
    GRANT ALL PRIVILEGES ON ${MYSQL_LARAVEL_DB}.* TO '${MYSQL_LARAVEL_USER}'@'localhost' WITH GRANT OPTION; \
    FLUSH PRIVILEGES;"

   # Embed database credentials into Laravel .env file
    sudo sed -i "s|^DB_DATABASE=.*|DB_DATABASE=${MYSQL_LARAVEL_DB}|" .env
    sudo sed -i "s|^DB_USERNAME=.*|DB_USERNAME=${MYSQL_LARAVEL_USER}|" .env
    sudo sed -i "s|^DB_PASSWORD=.*|DB_PASSWORD=${MYSQL_LARAVEL_PASSWORD}|" .env
    sudo sed -i "s|^# DB_CONNECTION=mysql|DB_CONNECTION=mysql|" .env
    sudo sed -i "s|^# DB_HOST=127.0.0.1|DB_HOST=127.0.0.1|" .env
    sudo sed -i "s|^# DB_PORT=3306|DB_PORT=3306|" .env

    # Configure Apache virtual host for Laravel
    sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/gab-app.conf
    sudo sed -i "s|DocumentRoot /var/www/html|DocumentRoot /var/www/html/gab-app/public|g" /etc/apache2/sites-available/gab-app.conf
    sudo a2ensite gab-app.conf
    sudo a2dissite 000-default.conf
    sudo systemctl restart apache2

    # Backup Apache virtual host configuration
    backup_file "/etc/apache2/sites-available/gab-app.conf"

    # Allow Apache through firewall
    sudo ufw allow 'Apache'

    # Update MySQL configuration to point to the new Laravel app directory
    sudo sed -i "s|/var/lib/mysql|/var/www/html/gab-app/mysql|g" /etc/mysql/mysql.conf.d/mysqld.cnf

    # Restart MySQL service
    sudo systemctl restart mysql

    # Run Laravel migrations
    php artisan migrate

    # Restart Apache
    sudo systemctl restart apache2

fi

# Inform user about MySQL credentials
echo -e "\e[32mMySQL Database: $MYSQL_LARAVEL_DB\e[0m"
echo -e "\e[32mMySQL User: $MYSQL_LARAVEL_USER\e[0m"
echo -e "\e[32mMySQL Password: $MYSQL_LARAVEL_PASSWORD\e[0m"
echo "MySQL credentials saved to mysql-credentials.txt"

# Inform user about successful installation
echo -e "${green}Laravel has been successfully installed on your server!${plain}"
echo "You can access your Laravel application at: http://$server_domain"

cat <<EOF
-------------------------------------------------------
You can access your Laravel application at: 

http://$server_domain

Don't forget to change the email and password after login!
--------------------------------------------------------
EOF
