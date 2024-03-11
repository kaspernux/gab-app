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

# Check if Node.js is installed
node -v &>/dev/null
NODE_INSTALLED=$?

# Check if Composer is installed
composer -v &>/dev/null
COMPOSER_INSTALLED=$?

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
sed -i "s/DB_DATABASE=.*/DB_DATABASE=${MYSQL_LARAVEL_DB}/" gab-app/.env
sed -i "s/DB_USERNAME=.*/DB_USERNAME=${MYSQL_LARAVEL_USER}/" gab-app/.env
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=${MYSQL_LARAVEL_PASSWORD}/" gab-app/.env

if [ $NODE_INSTALLED -eq 0 ]; then
    echo -e "${red} Node.js is already installed. Skipping installation.${plain}"
else
    echo -e "${red} Installing Node.js ...${plain}"
    # Install Node.js
    sudo apt-get update
    sudo apt-get install -y nodejs
fi

if [ $PHP_INSTALLED -eq 0 ]; then
    echo -e "${red} PHP latest version is already installed. Skipping installation.${plain}"
else
    echo -e "${green} Installing PHP Latest version ...${plain}"
    # Add repository for latest PHP version
    sudo add-apt-repository ppa:ondrej/php -y
    sudo apt update
    
    # Install the latest PHP version
    sudo apt install php php-fpm php-mysql php-common php-mbstring php-xmlrpc php-soap php-gd php-xml php-cli php-zip php-curl -y
    
    # Retrieve server timezone
    SERVER_TIMEZONE=$(timedatectl | grep "Time zone" | awk '{print $3}')
    
    # Replace placeholder with server timezone in PHP configuration
    sed -i "s|date.timezone = \"Your/Timezone\"|date.timezone = \"${SERVER_TIMEZONE}\"|" gab-app/.configs/php/php.ini
fi

echo -e "${green} Starting all the services on your server...${plain}"

# Start and enable services
sudo systemctl start apache2
sudo systemctl enable apache2
sudo systemctl start mysql
sudo systemctl enable mysql
sudo systemctl start php-fpm
sudo systemctl enable php-fpm

# Check if necessary packages are installed
if [ $DOCKER_INSTALLED -eq 0 ]; then
    echo -e "${red}Docker is already installed. Skipping installation.${plain}"
else
    echo -e "${green}Installing Docker...${plain}"
    # Install Docker
    sudo apt update
    sudo apt install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    echo \
        "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io

    # Install Docker Compose
    mkdir -p ~/.docker/cli-plugins/
    curl -SL https://github.com/docker/compose/releases/download/v2.3.3/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose
    chmod +x ~/.docker/cli-plugins/docker-compose

fi

# Function to fetch .env file from GitHub repository and copy into gab-app/.configs/php/php.ini and .configs/.env
fetch_env_file() {
    local repo_url="https://raw.githubusercontent.com/kaspernux/gab-app/main/.env"
    curl -sSf "$repo_url" > gab-app/.configs/.env
    cp gab-app/.configs/.env gab-app/.configs/php/php.ini
}

# Fetch .env file from GitHub repository
fetch_env_file


# Define the directory where your app will be deployed
APP_DIR="/root/gab-app"

# Remove the old repository if it exists
if [ -d "$APP_DIR" ]; then
    echo "Removing the old gab-app repository..."
    rm -rf "$APP_DIR" || { echo "Failed to remove the old gab-app repository"; exit 1; }
fi

# Clone the repository
git clone https://github.com/kaspernux/gab-app.git "$APP_DIR" || { echo "Failed to clone the repository"; exit 1; }

# Change directory to the app directory
cd "$APP_DIR" || { echo "Failed to change directory to $APP_DIR"; exit 1; }

echo "Let's build the GAB APP"

# Change directory 
cd /root/gab-app/docker

# just to be sure that no traces left
docker compose down -v

# building and running docker-compose file
docker compose build && docker compose up -d

# container id by image name
apache_container_id=$(docker ps -aqf "name=gab-php-apache")
db_container_id=$(docker ps -aqf "name=gab-mysql")

# checking connection
echo "Please wait... Waiting for MySQL connection..."
while ! docker exec ${db_container_id} mysql --user=root --password=root -e "SELECT 1" >/dev/null 2>&1; do
    sleep 1
done

# creating empty database for gab-app
echo "Creating empty database for gab-app..."
while ! docker exec ${db_container_id} mysql --user=root --password=root -e "CREATE DATABASE gabbana CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" >/dev/null 2>&1; do
    sleep 1
done

# creating empty database for gab-app testing
echo "Creating empty database for gab-app testing..."
while ! docker exec ${db_container_id} mysql --user=root --password=root -e "CREATE DATABASE gabbana_testing CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" >/dev/null 2>&1; do
    sleep 1
done

# setting up Gab-app
echo "Now, setting up DOLCE GABBANA..."
docker exec ${apache_container_id} git clone https://github.com/bagisto/bagisto /var/www/html/gab-app
# setting bagisto stable version
echo "Now, setting up Gab-app stable version..."
docker exec -i ${apache_container_id} bash -c "cd gab-app && git reset --hard $(git describe --tags $(git rev-list --tags --max-count=1))"

# installing composer dependencies inside container
docker exec -i ${apache_container_id} bash -c "cd gab-app && composer install"

# moving `.env` file
docker cp .configs/.env ${apache_container_id}:/var/www/html/gab-app/.env
docker cp .configs/.env.testing ${apache_container_id}:/var/www/html/gab-app/.env.testing

# executing final commands
docker exec -i ${apache_container_id} bash -c "cd gab-app && php artisan optimize:clear && php artisan migrate:fresh --seed && php artisan storage:link && php artisan gab-app:publish --force && php artisan optimize:clear"
echo "Setup completed successfully! The GAB APP has been installed."

cat <<EOF

You can access the admin panel at:

[http://localhost/admin/login](http://localhost/admin/login)

- Email: admin@example.com
- Password: admin123

To log in as a customer, you can directly register as a customer and then log in at:

[http://localhost/customer/register](http://localhost/customer/register)

EOF
