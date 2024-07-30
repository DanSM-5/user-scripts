#!/usr/bin/env bash

# Ref: https://wine.htmlvalidator.com/install-wine-on-linux-mint-21.html

# Download WineHQ repository key
sudo mkdir -pm755 /etc/apt/keyrings
sudo wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key

ubuntu_release="$(. /etc/os-release && echo "$UBUNTU_CODENAME")"
# Download WineHQ source files
sudo wget -NP /etc/apt/sources.list.d/ "https://dl.winehq.org/wine-builds/ubuntu/dists/$ubuntu_release/winehq-$ubuntu_release.sources"

# Update package database
sudo apt update

# Install wine
sudo apt install --install-recommends winehq-stable

