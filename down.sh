#!/bin/bash
set -e
cd "$(dirname "$0")"

echo "Stop :"
docker stop lazerbahn_web
echo "Remove :"
docker rm lazerbahn_web
