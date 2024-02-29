#!/bin/bash

# Move to docker/
cd ./docker

# Load environment variables from setup.sh
source gab-app/scripts/setup.sh

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
docker exec -i ${nginx_container_id} bash -c "cd /var/www/html/gab-app && composer install"

# Moving `.env` file
docker cp .configs/.env ${nginx_container_id}:/var/www/html/gab-app/.env
docker cp .configs/.env.testing ${nginx_container_id}:/var/www/html/gab-app/.env.testing

# Executing final commands
docker exec -i ${nginx_container_id} bash -c "cd /var/www/html/gab-app && php artisan optimize:clear && php artisan migrate:fresh --seed && php artisan storage:link && php artisan bagisto:publish --force && php artisan optimize:clear"
