#!/bin/sh

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

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}Fatal error: ${plain} Please run this script with root privilege \n " && exit 1

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

if [[ "${release}" == "centos" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red} Please use CentOS 8 or higher ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "ubuntu" ]]; then
    if [[ ${os_version} -lt 20 ]]; then
        echo -e "${red} Please use Ubuntu 20 or higher version!${plain}\n" && exit 1
    fi

elif [[ "${release}" == "fedora" ]]; then
    if [[ ${os_version} -lt 36 ]]; then
        echo -e "${red} Please use Fedora 36 or higher version!${plain}\n" && exit 1
    fi

elif [[ "${release}" == "debian" ]]; then
    if [[ ${os_version} -lt 11 ]]; then
        echo -e "${red} Please use Debian 11 or higher ${plain}\n" && exit 1
    fi

elif [[ "${release}" == "almalinux" ]]; then
    if [[ ${os_version} -lt 9 ]]; then
        echo -e "${red} Please use AlmaLinux 9 or higher ${plain}\n" && exit 1
    fi

elif [[ "${release}" == "rocky" ]]; then
    if [[ ${os_version} -lt 9 ]]; then
        echo -e "${red} Please use RockyLinux 9 or higher ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "arch" ]]; then
    echo "Your OS is ArchLinux"
elif [[ "${release}" == "manjaro" ]]; then
    echo "Your OS is Manjaro"
elif [[ "${release}" == "armbian" ]]; then
    echo "Your OS is Armbian"

else
    echo -e "${red}Failed to check the OS version, please contact the author!${plain}" && exit 1
fi

# Install LEMP stack
sudo apt install software-properties-common -y

# Check if Docker is installed
docker -v &>/dev/null
DOCKER_INSTALLED=$?

# Check if Nginx is installed
nginx -v &>/dev/null
NGINX_INSTALLED=$?

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
if [ $DOCKER_INSTALLED -eq 0 ]; then
    echo -e "${red}Docker is already installed. Skipping installation."
else
    echo -e "${green}Installing Docker..."
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

if [ $NGINX_INSTALLED -eq 0 ]; then
    echo -e "${red} Nginx is already installed. Skipping installation."
else
    echo -e "${green} Installing Nginx..."
    # Install Nginx
    sudo apt install nginx certbot python3-certbot-nginx -y
    # Backup the default Nginx configuration
    sudo mv /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak
    
    # Configure Nginx
    sudo cp gab-app/configurations/nginx/default.conf /etc/nginx/sites-available/default
    sudo nginx -t
    sudo systemctl reload nginx
fi


if [ $MYSQL_INSTALLED -eq 0 ]; then
    echo -e "${red} MySQL Server is already installed. Skipping installation."
else
    echo -e "${green} Installing MySQL Server..."
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
sed -i "s/DB_DATABASE=.*/DB_DATABASE=${MYSQL_LARAVEL_DB}/" gab-app/.env.example
sed -i "s/DB_USERNAME=.*/DB_USERNAME=${MYSQL_LARAVEL_USER}/" gab-app/.env.example
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=${MYSQL_LARAVEL_PASSWORD}/" gab-app/.env.example


if [ $NODE_INSTALLED -eq 0 ]; then
    echo -e "${red} Node.js is already installed. Skipping installation."
else
    echo -e "${red} Installing Node.js ..."
    # Install Node.js
    sudo apt-get update
    sudo apt-get install -y nodejs
fi

if [ $PHP_INSTALLED -eq 0 ]; then
    echo -e "${red} PHP latest version is already installed. Skipping installation."
else
    echo -e "${green} Installing PHP Latest version ..."
    # Add repository for latest PHP version
    sudo add-apt-repository ppa:ondrej/php -y
    sudo apt update
    
    # Install the latest PHP version
    sudo apt install php php-fpm php-mysql php-common php-mbstring php-xmlrpc php-soap php-gd php-xml php-cli php-zip php-curl -y
    
    # Retrieve server timezone
    SERVER_TIMEZONE=$(timedatectl | grep "Time zone" | awk '{print $3}')
    
    # Replace placeholder with server timezone in PHP configuration
    sed -i "s|date.timezone = \"Your/Timezone\"|date.timezone = \"${SERVER_TIMEZONE}\"|" gab-app/configurations/php/php.ini
fi

echo -e "${green} Starting all the services on your server..."

# Start and enable services
sudo systemctl start nginx
sudo systemctl enable nginx
sudo systemctl start mysql
sudo systemctl enable mysql
sudo systemctl start php"${PHP_VERSION}"-fpm
sudo systemctl enable php"${PHP_VERSION}"-fpm

# Clone the repository
cd .. && mkdir gab-app && git clone https://github.com/kaspernux/gab-app.git "$APP_DIR"

# Define the directory where your app will be deployed
APP_DIR="gab-app"

# Change directory to the app directory
cd "$APP_DIR" || exit

# Set permissions
chmod +x gab-app/scripts/*.sh

echo "Let Build the GAB APP"

# Just to be sure that no traces left
docker compose down -v

# Building and running docker compose file
docker compose build && docker compose up -d

# Container ID by image name
nginx_container_id=$(docker ps -aqf "name=${NGINX_CONTAINER_NAME}")
db_container_id=$(docker ps -aqf "name=${DB_CONTAINER_NAME}")

# Checking connection
echo -e "${yellow} Please wait... Waiting for MySQL connection..."
while ! docker exec ${db_container_id} mysql --user=root --password="${MYSQL_ROOT_PASSWORD}" -e "SELECT 1" >/dev/null 2>&1; do
    sleep 1
done

# Creating empty database for Gabapp
echo -e "${yellow} Creating empty database for Gabapp..."
while ! docker exec ${db_container_id} mysql --user=root --password="${MYSQL_ROOT_PASSWORD}" -e "CREATE DATABASE ${MYSQL_GABAPP_DB} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" >/dev/null 2>&1; do
    sleep 1
done

# Creating empty database for Gabapp testing
echo -e "${yellow} Creating empty database for Gabapp testing..."
while ! docker exec ${db_container_id} mysql --user=root --password="${MYSQL_ROOT_PASSWORD}" -e "CREATE DATABASE ${MYSQL_GABAPP_TESTING_DB} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" >/dev/null 2>&1; do
    sleep 1
done

# Setting up Gabapp
echo -e "${yellow} Now, setting up GAB APP..."
docker exec ${nginx_container_id} git clone https://github.com/bagisto/bagisto /var/www/html/gab-app

# Setting Gabapp stable version
echo -e "${yellow} Now, setting up GABAPP stable version..."
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

# Update the .env file inside the container
docker exec ${nginx_container_id} bash -c "cp /var/www/html/gab-app/.env /var/www/html/gab-app/.env.example"

# Settiing permissions
docker exec ${nginx_container_id} bash -c "chmod -R 775 /var/www/html/storage/logs/ && chown -R $USER:$USER /var/www/html/storage/logs/"

# Executing final commands
docker exec -i ${nginx_container_id} bash -c "cd /var/www/html/gab-app && php artisan optimize:clear && php artisan migrate:fresh --seed && php artisan storage:link && php artisan bagisto:publish --force && php artisan optimize:clear"

# Just to be sure that no traces left
docker-compose down -v

# Building and running docker-compose file
docker compose build && docker compose up -d

echo -e "${green} Setup completed successfully! The GAB APP has been installed"
echo -e"${yellow}
 You can access the admin panel at:

   [http://your_domain.com/admin/login](http://localhost/admin/login)

   - Email: admin@example.com
   - Password: admin123

   To log in as a customer, you can directly register as a customer and then login at:

   [http://your_domain.com/customer/register](http://localhost/customer/register)"
