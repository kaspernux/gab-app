#!/bin/bash

# Create main directory
mkdir -p gab-app/{.configs/{nginx,mysql,php,laravel},docs,samples/laravel-app,tests/integration,docker,ansible,.github/workflows}

# Create other necessary files
touch gab-app/{Vagrantfile,.gitignore,LICENSE,README.md,.env.example}

# Create default Nginx configuration file
touch gab-app/.configs/nginx/default.conf

# Create MySQL configuration file
touch gab-app/.configs/mysql/my.cnf

# Create PHP configuration file
touch gab-app/.configs/php/php.ini

# Create Laravel environment file
touch gab-app/.configs/laravel/.env.example

# Create Laravel application files
touch gab-app/samples/laravel-app/{.env.example,artisan,composer.json,package.json,server.php}
mkdir -p gab-app/samples/laravel-app/{app,bootstrap,config,database,public,resources,routes,storage,tests}

# Create Ansible files
touch gab-app/ansible/{playbook.yml,inventory}

# Create Docker files
touch gab-app/docker/{Dockerfile,docker-compose.yml}

# Create documentation files
touch gab-app/docs/{installation-guide.md,configuration-guide.md,security-guide.md,usage-guide.md}

# Create sample test files
touch gab-app/tests/integration/laravel-tests.sh

# Initialize GitHub Actions workflow file
touch gab-app/.github/workflows/build.yml

echo "Directory structure and files created successfully."
