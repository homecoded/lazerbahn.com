#!/bin/bash
docker build -t lazerbahn --label="lazerbahn" .
cd build
docker run --name lazerbahn_web -d --volume $(pwd)/../:/var/www/html -p 80:80 lazerbahn 