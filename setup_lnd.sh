#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   return
fi

if ! [ -x "$(command -v docker)" ] || ! [ -x "$(command -v docker-compose)" ]; then
    if ! [ -x "$(command -v curl)" ]; then
        apt-get update 2>error
        apt-get install -y \
            curl \
            apt-transport-https \
            ca-certificates \
            software-properties-common \
            2>error
    fi
    if ! [ -x "$(command -v docker)" ]; then
        if [[ "$(uname -m)" == "x86_64" ]] || [[ "$(uname -m)" == "armv7l" ]]; then
            echo "Trying to install docker..."
            curl -fsSL https://get.docker.com -o get-docker.sh
            chmod +x get-docker.sh
            sh get-docker.sh
            rm get-docker.sh
        elif [[ "$(uname -m)" == "aarch64" ]]; then
            echo "Trying to install docker for armv7 on a aarch64 board..."
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
            RELEASE=$(lsb_release -cs)
            if [[ "$RELEASE" == "bionic" ]]; then
                RELEASE=xenial
            fi
            add-apt-repository "deb https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $RELEASE stable"
            apt-get update -y
            apt-get install -y docker-ce:armhf
        fi
    fi
    if ! [ -x "$(command -v docker-compose)" ]; then
        if [[ "$(uname -m)" == "x86_64" ]]; then
            DOCKER_COMPOSE_DOWNLOAD="https://github.com/docker/compose/releases/download/1.23.2/docker-compose-`uname -s`-`uname -m`"
            echo "Trying to install docker-compose by downloading on $DOCKER_COMPOSE_DOWNLOAD ($(uname -m))"
            curl -L "$DOCKER_COMPOSE_DOWNLOAD" -o /usr/local/bin/docker-compose
            chmod +x /usr/local/bin/docker-compose
        else
            echo "Trying to install docker-compose by using the docker-compose-builder ($(uname -m))"
            ! [ -d "dist" ] && mkdir dist
            docker run --rm -ti -v "$(pwd)/dist:/dist" btcpayserver/docker-compose-builder:1.23.2
            mv dist/docker-compose /usr/local/bin/docker-compose
            chmod +x /usr/local/bin/docker-compose
            rm -rf "dist"
        fi
    fi
fi

if ! [ -x "$(command -v docker)" ]; then
    echo "Failed to install docker"
    return
fi

if ! [ -x "$(command -v docker-compose)" ]; then
    echo "Failed to install docker-compose"
    return
fi

# get docker compose yml
DOCKER_COMPOSE_FILE=https://github.com/lightningcn/ln-node/raw/master/x86_64/docker-compose_bitcoin_lnd_rtl.yml
curl -L "$DOCKER_COMPOSE_FILE" -o docker-compose.yml

PublicIP=$(curl -s http://v4.ipv6-test.com/api/myip.php)

export BITCOIN_NETWORK=mainnet
export LIGHTNING_HOST=${PublicIP}
export LIGHTNING_ALIAS=nodex.lightningcn.com
 
docker-compose up -d
