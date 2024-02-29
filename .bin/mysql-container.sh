# container id
CONTAINER_ID=$(docker ps -aqf "name=gab-mysql")

docker exec -it ${CONTAINER_ID} bash