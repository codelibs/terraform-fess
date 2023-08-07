#!/bin/bash

# Install Docker
echo "Install docker"
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y docker-ce git

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker

# Run Elasticsearch
#sudo docker pull docker.elastic.co/elasticsearch/elasticsearch:7.10.0
#sudo docker run -d --name elasticsearch -p 8080:9200 -p 9300:9300 -e "discovery.type=single-node" docker.elastic.co/elasticsearch/elasticsearch:7.10.0

# Setup
echo "Setup vm.max_map_count"
sudo echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Run Fess
echo "Run Fess"
cd /opt || exit 1
git clone https://github.com/codelibs/docker-fess.git
cd ./docker-fess/compose || exit 1
docker compose --env-file .env.elasticsearch -f compose.yaml -f compose-elasticsearch8.yaml up -d

