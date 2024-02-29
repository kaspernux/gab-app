#!/bin/bash

# Create main directory
mkdir -p gab-app/{scripts,configurations/{nginx,mysql,php,laravel},docs,samples/laravel-app,tests/integration,docker,ansible,.github/workflows}

# Create script files
touch gab-app/scripts/{install-lemp.sh,configure-nginx.sh,configure-mysql.sh,configure-php.sh,setup-security.sh,deploy-laravel.sh}

# Create configuration files
touch gab-app/configurations/nginx/default.conf
touch gab-app/configurations/mysql/my.cnf
touch gab-app/configurations/php/php.ini
touch gab-app/configurations/laravel/.env.example

# Create documentation files
touch gab-app/docs/{installation-guide.md,configuration-guide.md,security-guide.md,usage-guide.md}

# Create sample files
touch gab-app/samples/laravel-app/{.env.example,artisan,composer.json,package.json,server.php}
mkdir -p gab-app/samples/laravel-app/{app,config,database,public,resources,routes,tests}

# Create test files
touch gab-app/tests/integration/laravel-tests.sh

# Create Docker files
touch gab-app/docker/{Dockerfile,docker-compose.yml}

# Create Ansible files
touch gab-app/ansible/{playbook.yml,inventory}

# Create other files
touch gab-app/{Vagrantfile,.github/workflows/ci-cd.yml,LICENSE,README.md,.gitignore}

echo "Directory structure and files created successfully."
