# Stop and remove existing containers along with volumes
docker compose down -v

# Build and run the Docker Compose file
docker compose up -d --build

# Retrieve container IDs by image name
apache_container_id=$(docker ps -qf "name=bagisto-php-apache")
db_container_id=$(docker ps -qf "name=bagisto-mysql")

# Check MySQL connection
echo "Please wait... Waiting for MySQL connection..."
while ! docker exec ${db_container_id} mysqladmin ping -uroot -proot --silent; do
    sleep 1
done

# Create empty databases for Bagisto and testing
echo "Creating empty databases for Bagisto..."
docker exec ${db_container_id} mysql -uroot -proot -e "CREATE DATABASE IF NOT EXISTS bagisto CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
docker exec ${db_container_id} mysql -uroot -proot -e "CREATE DATABASE IF NOT EXISTS bagisto_testing CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# Set up Bagisto
echo "Setting up Bagisto..."
docker exec ${apache_container_id} git clone https://github.com/bagisto/bagisto

# Set Bagisto stable version
echo "Setting up Bagisto stable version..."
docker exec ${apache_container_id} bash -c "cd bagisto && git fetch --tags && git checkout $(git describe --tags $(git rev-list --tags --max-count=1))"

# Install composer dependencies inside the container
docker exec ${apache_container_id} bash -c "cd bagisto && composer install"

# Copy `.env` files to the container
docker cp .configs/.env ${apache_container_id}:/var/www/html/bagisto/.env
docker cp .configs/.env.testing ${apache_container_id}:/var/www/html/bagisto/.env.testing

# Execute final commands for setup
docker exec ${apache_container_id} bash -c "cd bagisto && php artisan optimize:clear && php artisan migrate:fresh --seed && php artisan storage:link && php artisan bagisto:publish --force && php artisan optimize:clear"