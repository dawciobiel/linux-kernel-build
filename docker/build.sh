#!bin/bash

CONTAINER_NAME=$1
DOCKER_FILE=$2

docker build -t $1 -f $DOCKER_FILE .
