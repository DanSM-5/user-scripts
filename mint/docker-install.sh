#!/usr/bin/env bash

# ######################################### #
#    Install docker engine in Linux Mint    #
# ######################################### #

# gpg key location
sing_key="/etc/apt/keyrings/docker.gpg"

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get -y install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o "$sing_key"
sudo chmod a+r "$sing_key"

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=$sing_key] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$UBUNTU_CODENAME") stable" |
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update repositories
sudo apt-get update

# Install the dependencies
sudo apt-get -y install \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

# Create docker group
sudo groupadd docker
sudo usermod -aG docker "$USER"
newgrp docker

