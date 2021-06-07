#!/bin/bash
set -e
cd "$(dirname "$0")"

DOCKER_HOST_PORT=80

if [ -f .env ]; then
  source .env
  DOCKER_HOST_PORT=$LOCAL_PORT
fi

docker build -t lazerbahn --label="lazerbahn" .
cd build
docker run --name lazerbahn_web -d --volume $(pwd)/../:/var/www/html -p $DOCKER_HOST_PORT:80 lazerbahn
