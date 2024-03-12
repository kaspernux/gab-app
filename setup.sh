#!/bin/bash

# Print GAB APP ASCII art
printf "\e[34m
 $$$$$$\   $$$$$$\  $$$$$$$\         $$$$$$\  $$$$$$$\  $$$$$$$\  
$$  __$$\ $$  __$$\ $$  __$$\       $$  __$$\ $$  __$$\ $$  __$$\ 
$$ /  \__|$$ /  $$ |$$ |  $$ |      $$ /  $$ |$$ |  $$ |$$ |  $$ |
$$ |$$$$\ $$$$$$$$ |$$$$$$$\ |      $$$$$$$$ |$$$$$$$  |$$$$$$$  |
$$ |\_$$ |$$  __$$ |$$  __$$\       $$  __$$ |$$  ____/ $$  ____/ 
$$ |  $$ |$$ |  $$ |$$ |  $$ |      $$ |  $$ |$$ |      $$ |      
\$$$$$$  |$$ |  $$ |$$$$$$$  |      $$ |  $$ |$$ |      $$ |      
 \______/ \__|  \__|\_______/       \__|  \__|\__|      \__|      
                                                                  
                                                                  
                                                                
\e[0m"

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# Check root privilege
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${red}Fatal error: ${plain}Please run this script with root privilege\n" >&2
    exit 1
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

# Continue with the rest of your script...
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

You can access the admin panel at:

[http://localhost/admin/login](http://localhost/admin/login)

- Email: admin@example.com
- Password: admin123

To log in as a customer, you can directly register as a customer and then log in at:

[http://localhost/customer/register](http://localhost/customer/register)

EOF
