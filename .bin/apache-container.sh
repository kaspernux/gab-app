# container id
CONTAINER_ID=$(docker ps -aqf "name=gab-php-apache")

docker exec -w /var/www/html/gab-app -it ${CONTAINER_ID} bash