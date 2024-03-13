#!/bin/bash

# Function to handle errors
handle_error() {
    echo -e "\e[31mError: $1\e[0m" >&2
    exit 1
}

# Function to backup a file or directory
backup_file() {
    if [ -e "$1" ]; then
        cp -r "$1" "$1.backup" || handle_error "Failed to backup $1"
        echo "Backup created: $1.backup"
    fi
}

# Function to check for conflicting packages and old files
check_conflicts() {
    echo "Checking for conflicting packages and old files..."
    
    # Check if Apache configuration file exists
    if [ -f "/etc/apache2/apache2.conf" ]; then
        echo "Apache configuration file already exists. Setting it to the new Laravel app..."
        # Update Apache configuration to point to the new Laravel app
        sudo sed -i 's|/var/www/html|/var/www/html/gab-app/public|g' /etc/apache2/apache2.conf
        sudo systemctl restart apache2
    fi

    # Check if MySQL configuration file exists
    if [ -f "/etc/mysql/mysql.conf.d/mysqld.cnf" ]; then
        echo "MySQL configuration file already exists. Creating a backup..."
        # Create a backup of the existing MySQL configuration file
        sudo cp /etc/mysql/mysql.conf.d/mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf.backup
        echo "Backup created: /etc/mysql/mysql.conf.d/mysqld.cnf.backup"
        # Update MySQL configuration to point to the new Laravel app
        sudo sed -i 's|/path/to/old/laravel|/var/www/html/gab-app|g' /etc/mysql/mysql.conf.d/mysqld.cnf
        sudo systemctl restart mysql
    fi

    # Check if old Laravel project directory exists
    if [ -d "/var/www/html/gab-app" ]; then
        echo "Old Laravel project directory exists. Backing up..."
        backup_file "/var/www/html/gab-app"
        echo "Removing old Laravel project directory..."
        rm -rf /var/www/html/gab-app
    fi
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

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)
# Check root privilege
if [ "$(id -u)" -ne 0 ]; then
    handle_error "Please run this script with root privilege"
fi

# Backup existing data and configurations
check_conflicts

# Add error handling
set -e

# Prompt user for server domain or IP address
read -p "Enter server domain or IP address: " server_domain

# Check if the directory exists, if not, create it
if [ ! -d "/var/www/html/gab-app" ]; then
    mkdir -p /var/www/html/gab-app
fi

# Check OS and set release variable
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    release=$ID
elif [[ -f /usr/lib/os-release ]]; then
    source /usr/lib/os-release
    release=$ID
else
    echo "Failed to check the system OS, please contact the author!" >&2
    exit 1
fi
echo "The OS release is: $release"

arch3xui() {
    case "$(uname -m)" in
    x86_64 | x64 | amd64) echo 'amd64' ;;
    i*86 | x86) echo '386' ;;
    armv8* | armv8 | arm64 | aarch64) echo 'arm64' ;;
    armv7* | armv7 | arm) echo 'armv7' ;;
    armv6* | armv6) echo 'armv6' ;;
    armv5* | armv5) echo 'armv5' ;;
    *) echo -e "${green}Unsupported CPU architecture! ${plain}" && rm -f install.sh && exit 1 ;;
    esac
}

echo "arch: $(arch3xui)"

os_version=""
os_version=$(grep -i version_id /etc/os-release | cut -d \" -f2 | cut -d . -f1)

# Check OS version
case "${release}" in
    centos)
        if [[ ${os_version} -lt 8 ]]; then
            echo -e "${red} Please use CentOS 8 or higher ${plain}\n" && exit 1
        fi
        ;;
    ubuntu)
        if [[ ${os_version} -lt 20 ]]; then
            echo -e "${red} Please use Ubuntu 20 or higher version!${plain}\n" && exit 1
        fi
        ;;
    fedora)
        if [[ ${os_version} -lt 36 ]]; then
            echo -e "${red} Please use Fedora 36 or higher version!${plain}\n" && exit 1
        fi
        ;;
    debian)
        if [[ ${os_version} -lt 11 ]]; then
            echo -e "${red} Please use Debian 11 or higher ${plain}\n" && exit 1
        fi
        ;;
    almalinux)
        if [[ ${os_version} -lt 9 ]]; then
            echo -e "${red} Please use AlmaLinux 9 or higher ${plain}\n" && exit 1
        fi
        ;;
    rocky)
        if [[ ${os_version} -lt 9 ]]; then
            echo -e "${red} Please use RockyLinux 9 or higher ${plain}\n" && exit 1
        fi
        ;;
    arch)
        echo "Your OS is ArchLinux"
        ;;
    manjaro)
        echo "Your OS is Manjaro"
        ;;
    armbian)
        echo "Your OS is Armbian"
        ;;
    *)
        echo -e "${red}Failed to check the OS version, please contact the author!${plain}" && exit 1
        ;;
esac

# Install LAMP stack
sudo apt install software-properties-common -y

# Check if Apache is installed
apache2 -v &>/dev/null
APACHE_INSTALLED=$?

# Check if MySQL is installed
mysql --version &>/dev/null
MYSQL_INSTALLED=$?

# Check if PHP is installed
php -v &>/dev/null
PHP_INSTALLED=$?

# Check if Composer is installed
composer -v &>/dev/null
COMPOSER_INSTALLED=$?

# Check if Node.js is installed
node -v &>/dev/null
NODE_INSTALLED=$?

# Check if NPM is installed
npm -v &>/dev/null
NPM_INSTALLED=$?

# Check if Git is installed
git --version &>/dev/null
GIT_INSTALLED=$?

# Check if necessary packages are installed
if [ $APACHE_INSTALLED -eq 0 ]; then
    echo -e "${red}Apache is already installed. Skipping installation.${plain}"
else
    echo -e "${green}Installing Apache...${plain}"
    # Install Apache
    sudo apt update
    sudo apt install -y apache2
    
    # Enable Apache modules
    sudo a2enmod rewrite
    sudo systemctl restart apache2
fi

if [ $MYSQL_INSTALLED -eq 0 ]; then
    echo -e "${red} MySQL Server is already installed. Skipping installation.${plain}"
else
    echo -e "${green} Installing MySQL Server...${plain}"
    # Install MySQL
    sudo apt install mysql-server -y
    sudo mysql_secure_installation
fi

if [ $PHP_INSTALLED -eq 0 ]; then
    echo -e "${red} PHP is already installed. Skipping installation.${plain}"
else
    echo -e "${green} Installing PHP and required extensions...${plain}"
    # Add repository for latest PHP version
    sudo add-apt-repository ppa:ondrej/php -y
    sudo apt update
    
    # Install the latest PHP version and required extensions
    sudo apt install php php-fpm php-mysql php-common php-mbstring php-xmlrpc php-soap php-gd php-xml php-cli php-zip php-curl -y
    
    # Retrieve server timezone
    SERVER_TIMEZONE=$(timedatectl | grep "Time zone" | awk '{print $3}')
    
    # Replace placeholder with server timezone in PHP configuration
    sudo sed -i "s|date.timezone = \"Your/Timezone\"|date.timezone = \"${SERVER_TIMEZONE}\"|" /etc/php/{VERSION}/apache2/php.ini
fi

if [ $COMPOSER_INSTALLED -eq 0 ]; then
    echo -e "${red} Composer is already installed. Skipping installation.${plain}"
else
    echo -e "${green} Installing Composer...${plain}"
    # Install Composer
    sudo apt update
    sudo apt install composer -y
fi

if [ $NODE_INSTALLED -eq 0 ]; then
    echo -e "${red} Node.js is already installed. Skipping installation.${plain}"
else
    echo -e "${green} Installing Node.js...${plain}"
    # Install Node.js
    sudo apt update
    sudo apt install -y nodejs
fi

if [ $NPM_INSTALLED -eq 0 ]; then
    echo -e "${red} NPM is already installed. Skipping installation.${plain}"
else
    echo -e "${green} Installing NPM...${plain}"
    # Install NPM
    sudo apt update
    sudo apt install -y npm
fi

if [ $GIT_INSTALLED -eq 0 ]; then
    echo -e "${red} Git is already installed. Skipping installation.${plain}"
else
    echo -e "${green} Installing Git...${plain}"
    # Install Git
    sudo apt update
    sudo apt install -y git
fi

# Install phpMyAdmin
sudo apt update
sudo apt install phpmyadmin -y

# Configure phpMyAdmin for Apache
sudo ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-available/phpmyadmin.conf
sudo a2enconf phpmyadmin
sudo systemctl reload apache2

# Create MySQL database and user for Laravel
MYSQL_ROOT_PASSWORD=$(openssl rand -base64 12)
MYSQL_LARAVEL_DB="gab_app"
MYSQL_LARAVEL_USER="gab_app_user"
MYSQL_LARAVEL_PASSWORD=$(openssl rand -base64 12)

# Save MySQL password to a text file
echo "MySQL root password: ${MYSQL_ROOT_PASSWORD}" > mysql_password.txt

sudo mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS ${MYSQL_LARAVEL_DB};
CREATE USER IF NOT EXISTS '${MYSQL_LARAVEL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_LARAVEL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_LARAVEL_DB}.* TO '${MYSQL_LARAVEL_USER}'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# Update Laravel application's .env file with MySQL database configuration
sed -i "s/DB_DATABASE=.*/DB_DATABASE=${MYSQL_LARAVEL_DB}/" /var/www/html/gab-app/.env
sed -i "s/DB_USERNAME=.*/DB_USERNAME=${MYSQL_LARAVEL_USER}/" /var/www/html/gab-app/.env
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=${MYSQL_LARAVEL_PASSWORD}/" /var/www/html/gab-app/.env

# Update Apache configuration to point to the Laravel app
sudo sed -i "s|/var/www/html|/var/www/html/gab-app/public|g" /etc/apache2/sites-available/000-default.conf

# Restart Apache to apply changes
sudo systemctl restart apache2

# Configure Apache virtual host with user-provided domain or IP address
cat <<EOF > /etc/apache2/sites-available/gab-app.conf
<VirtualHost *:80>
    ServerName $server_domain
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html/gab-app/public

    <Directory /var/www/html/gab-app>
        AllowOverride All
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

# Backup Apache virtual host configuration
backup_file "/etc/apache2/sites-available/gab-app.conf"

# Navigate to the web server root directory
cd /var/www/html

# Create a new Laravel project
composer create-project laravel/laravel:^10.0 gab-app --prefer-dist

# Change ownership of Laravel project directory to Apache user
sudo chown -R www-data:www-data /var/www/html/gab-app

# Set proper permissions for Laravel project directory
sudo chmod -R 755 /var/www/html/gab-app/storage

# Configure Apache virtual host for your Laravel project
sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/gab-app.conf

# Edit Apache virtual host configuration file
sudo sed -i 's|/var/www/html|/var/www/html/gab-app/public|g' /etc/apache2/sites-available/gab-app.conf

# Enable Apache virtual host for your Laravel project
sudo a2ensite gab-app.conf

# Disable the default Apache virtual host
sudo a2dissite 000-default.conf

# Restart Apache web server to apply changes
sudo systemctl restart apache2

# Install Laravel dependencies
cd /var/www/html/gab-app
composer install

# Generate Laravel application key
php artisan key:generate

# Run database migrations and seeders
php artisan migrate --seed

# Set proper permissions for Laravel project directory after installation
sudo chmod -R 755 /var/www/html/gab-app/storage
sudo chmod -R 755 /var/www/html/gab-app/bootstrap/cache

# Display Laravel installation completion message
echo -e "${green}Laravel application is installed and configured successfully!${plain}"
echo -e "${green}You can now access your Laravel application${plain}"
cat <<EOF

cat <<EOF

You can access the admin panel at:

[http://$server_domain/admin/login](http://$server_domain/admin/login)

- Email: admin@example.com
- Password: admin123

To log in as a customer, you can directly register as a customer and then log in at:

[http://$server_domain/customer/register](http://$server_domain/customer/register)

EOF
