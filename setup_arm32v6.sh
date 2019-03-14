#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   return
fi


# get docker compose yml
DOCKER_COMPOSE_FILE=https://github.com/lightningcn/ln-node/raw/master/arm32v6/docker-compose_bitcoin_lnd_rtl.yml
curl -L "$DOCKER_COMPOSE_FILE" -o docker-compose.yml

docker-compose up -d
