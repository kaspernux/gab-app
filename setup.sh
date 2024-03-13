#!/bin/bash

# Function to handle errors
handle_error() {
    echo -e "\e[31mError: $1\e[0m" >&2
    exit 1
}

# Function to backup a file or directory
backup_file() {
    if [ -e "$1" ]; then
        if [ ! -e "$1.backup" ]; then
            cp -r "$1" "$1.backup" || handle_error "Failed to backup $1"
            echo "Backup created: $1.backup"
        else
            echo "Backup already exists: $1.backup"
        fi
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
        sudo systemctl restart apache2 || handle_error "Failed to restart Apache"
    fi

    # Check if MySQL configuration file exists
    if [ -f "/etc/mysql/mysql.conf.d/mysqld.cnf" ]; then
        echo "MySQL configuration file already exists. Creating a backup..."
        # Create a backup of the existing MySQL configuration file
        sudo cp /etc/mysql/mysql.conf.d/mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf.backup || handle_error "Failed to backup MySQL configuration"
        echo "Backup created: /etc/mysql/mysql.conf.d/mysqld.cnf.backup"
        # Update MySQL configuration to point to the new Laravel app
        sudo sed -i 's|/var/www/html/gab-app|/var/www/html/gab-app|g' /etc/mysql/mysql.conf.d/mysqld.cnf
        sudo systemctl restart mysql || handle_error "Failed to restart MySQL"
    fi

    # Check if old Laravel project directory exists
    if [ -d "/var/www/html/gab-app" ]; then
        echo "Old Laravel project directory exists. Backing up..."
        backup_file "/var/www/html/gab-app"
        echo "Removing old Laravel project directory..."
        rm -rf /var/www/html/gab-app || handle_error "Failed to remove old Laravel project directory"
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

# Check root privilege
if [ "$(id -u)" -ne 0 ]; then
    handle_error "Please run this script with root privilege"
fi

# Backup existing data and configurations
check_conflicts

# Add error handling
set -e

# Prompt user for server domain or IP address
read -p $'\e[32mEnter server domain or IP address:\e[0m' server_domain

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
    *) echo -e "\033[0;31mUnsupported CPU architecture! \033[0m" >&2 && rm -f install.sh && exit 1 ;;
    esac
}

echo "arch: $(arch3xui)"

os_version=""
os_version=$(grep -i version_id /etc/os-release | cut -d '"' -f2 | cut -d . -f1)

# Check OS version
case "${release}" in
    centos)
        if [[ ${os_version} -lt 8 ]]; then
            echo -e "\033[0;31mPlease use CentOS 8 or higher \033[0m\n" >&2 && exit 1
        fi
        ;;
    ubuntu)
        if [[ ${os_version} -lt 20 ]]; then
            echo -e "\033[0;31mPlease use Ubuntu 20 or higher version!\033[0m\n" >&2 && exit 1
        fi
        ;;
    fedora)
        if [[ ${os_version} -lt 36 ]]; then
            echo -e "\033[0;31mPlease use Fedora 36 or higher version!\033[0m\n" >&2 && exit 1
        fi
        ;;
    debian)
        if [[ ${os_version} -lt 11 ]]; then
            echo -e "\033[0;31mPlease use Debian 11 or higher \033[0m\n" >&2 && exit 1
        fi
        ;;
    almalinux)
        if [[ ${os_version} -lt 9 ]]; then
            echo -e "\033[0;31mPlease use AlmaLinux 9 or higher \033[0m\n" >&2 && exit 1
        fi
        ;;
    rocky)
        if [[ ${os_version} -lt 9 ]]; then
            echo -e "\033[0;31mPlease use RockyLinux 9 or higher \033[0m\n" >&2 && exit 1
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
        echo -e "\033[0;31mFailed to check the OS version, please contact the author!\033[0m" >&2 && exit 1
        ;;
esac

# Install LAMP stack
sudo apt install software-properties-common -y

# Check if PHP is already installed
if ! command -v php >/dev/null; then
    sudo apt update
    sudo apt install php php-{bcmath,bz2,intl,gd,mbstring,mysql,zip} unzip -y
fi

# Check if Composer is already installed
if ! command -v composer >/dev/null; then
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer && php -r "unlink('composer-setup.php');"
fi

# Check if Apache is already installed
if ! command -v apache2 >/dev/null; then
    sudo apt install apache2 -y
    sudo a2enmod rewrite
    sudo systemctl restart apache2
fi

# Check if MySQL is already installed
if ! command -v mysql >/dev/null; then
    sudo apt install mysql-server -y
    sudo systemctl start mysql
    sudo systemctl enable mysql

    # Define MySQL credentials for Laravel
    MYSQL_LARAVEL_DB="gab_app"
    MYSQL_LARAVEL_USER="gab_app_user"
    MYSQL_LARAVEL_PASSWORD=$(openssl rand -base64 12)
    
    # Save MySQL credentials to a text file
    echo "Laravel database: ${MYSQL_LARAVEL_DB}" > mysql_credentials.txt
    echo "Laravel database user: ${MYSQL_LARAVEL_USER}" >> mysql_credentials.txt
    echo "Laravel database password: ${MYSQL_LARAVEL_PASSWORD}" >> mysql_credentials.txt
    
    # Create MySQL database and user for Laravel
    sudo mysql -e \
    "CREATE DATABASE IF NOT EXISTS ${MYSQL_LARAVEL_DB}; \
    CREATE USER IF NOT EXISTS '${MYSQL_LARAVEL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_LARAVEL_PASSWORD}'; \
    GRANT ALL PRIVILEGES ON ${MYSQL_LARAVEL_DB}.* TO '${MYSQL_LARAVEL_USER}'@'localhost' WITH GRANT OPTION; \
    FLUSH PRIVILEGES;"
    
    # Append MySQL credentials to Laravel .env file
    echo "DB_DATABASE=${MYSQL_LARAVEL_DB}" >> /var/www/html/gab-app/.env
    echo "DB_USERNAME=${MYSQL_LARAVEL_USER}" >> /var/www/html/gab-app/.env
    echo "DB_PASSWORD=${MYSQL_LARAVEL_PASSWORD}" >> /var/www/html/gab-app/.env

fi

if [ ! -f "/etc/phpmyadmin/config.inc.php" ]; then
    sudo apt install phpmyadmin -y

    # Create a symbolic link for Apache configuration
    sudo ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-available/phpmyadmin.conf
    sudo a2enconf phpmyadmin
    sudo systemctl restart apache2

    # Create phpMyAdmin configuration file
    sudo tee /etc/apache2/conf-available/phpmyadmin.conf > /dev/null <<EOF
        Alias /phpmyadmin /usr/share/phpmyadmin
        <Directory /usr/share/phpmyadmin>
            Options SymLinksIfOwnerMatch
            DirectoryIndex index.php
        
            <IfModule mod_php5.c>
                <IfModule mod_mime.c>
                    AddType application/x-httpd-php .php
                </IfModule>
                <FilesMatch ".+\.php$">
                    SetHandler application/x-httpd-php
                </FilesMatch>
        
                php_flag magic_quotes_gpc Off
                php_flag track_vars On
                php_flag register_globals Off
                php_admin_flag allow_url_fopen Off
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

    # Enable phpMyAdmin configuration
    sudo a2enconf phpmyadmin
    sudo systemctl restart apache2
fi

# Install Laravel
cd /var/www/html/gab-app || handle_error "Failed to change directory to /var/www/html/gab-app"
composer create-project --prefer-dist laravel/laravel .
sudo chown -R www-data:www-data /var/www/html/gab-app
sudo chmod -R 755 /var/www/html/gab-app/storage
sudo chmod -R 755 /var/www/html/gab-app/bootstrap/cache

# Embed database credentials into Laravel .env file
echo "DB_CONNECTION=mysql" >> /var/www/html/gab-app/.env
echo "DB_HOST=127.0.0.1" >> /var/www/html/gab-app/.env
echo "DB_PORT=3306" >> /var/www/html/gab-app/.env
echo "DB_DATABASE=${MYSQL_LARAVEL_DB}" >> /var/www/html/gab-app/.env
echo "DB_USERNAME=${MYSQL_LARAVEL_USER}" >> /var/www/html/gab-app/.env
echo "DB_PASSWORD=${MYSQL_LARAVEL_PASSWORD}" >> /var/www/html/gab-app/.env

# Update Apache configuration to point to the Laravel app
sudo sed -i 's|DocumentRoot /var/www/html|DocumentRoot /var/www/html/gab-app/public|g' /etc/apache2/sites-available/gab-app.conf


# Configure Apache virtual host for your Laravel project
sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/gab-app.conf

# Edit Apache virtual host configuration file
sudo tee /etc/apache2/sites-available/gab-app.conf > /dev/null <<EOF
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

# Configure Apache virtual host for your Laravel project
sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/gab-app.conf

# Edit Apache virtual host configuration file
sudo sed -i 's|/var/www/html|/var/www/html/gab-app/public|g' /etc/apache2/sites-available/gab-app.conf

# Enable Apache virtual host for your Laravel project
sudo a2ensite gab-app.conf

# Restart Apache to apply changes
sudo systemctl restart apache2

# Allow Apache through firewall
sudo ufw allow 'Apache'

# Inform user about MySQL credentials
echo -e "${green}Your MySQL database name, username, and password are saved in mysql_credentials.txt${plain}"

# Inform user about successful installation
echo -e "${green}Laravel has been successfully installed on your server!${plain}"
echo "You can access your Laravel application at: http://$server_domain"
