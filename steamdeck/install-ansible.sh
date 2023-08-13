#!/usr/bin/env bash

# Install ansible for managing restore and dependencies
# Ref: https://www.reddit.com/r/SteamDeck/comments/w4y9h5/howto_using_ansible_to_install_flatpaks_other

sdcard="$HOME/sdcard"
if ! [[ -L $sdcard && -e $sdcard ]]; then
  echo "Make sure to create a symlick to the SD card first!!!"
  echo "ln -s /run/madia/[sdcard]" ~/sdcard
  exit 1
fi

# Install pip
python3 -m ensurepip --update
~/.local/bin/pip3 install ansible-core


# Set up important directories
rsyncdir=${sdcard}/rsync-backups
workingdir=${sdcard}/playbooks/software-installs
mkdir ${rsyncdir}
mkdir -p ${workingdir}/collections
cd $workingdir

# Install ansible dependencies
~/.local/bin/ansible-galaxy install -r requirements.yml
~/.local/bin/ansible-playbook install-flatpaks.yml


