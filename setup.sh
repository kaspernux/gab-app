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

# Check if Docker is installed
docker -v &>/dev/null
DOCKER_INSTALLED=$?

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

# Start Docker Compose services
docker-compose -f docker-compose.yml up -d

# Wait for services to be up and running
sleep 30

# Check MySQL connection
docker exec -it gab-mysql mysqladmin -u root -pgabtestping &>/dev/null
MYSQL_CONN=$?

if [ $MYSQL_CONN -eq 0 ]; then
    echo -e "${green}MySQL connection established.${plain}"
else
    echo -e "${red}Failed to connect to MySQL.${plain}" >&2
    exit 1
fi

# Copy Apache configuration file
docker cp ./configs/apache.conf gab-php-apache:/etc/apache2/sites-available/000-default.conf

# Restart Apache server
docker restart gab-php-apache

echo -e "${green}Setup completed successfully.${plain}"
