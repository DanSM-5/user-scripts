#!/usr/bin/env bash

[[ -v debug ]] && set -x

# Create certificates in a directory
target="${1:-./jwt}"
passphrase="$2"

if [[ -n "$passphrase" ]]; then
  passphrase='""'
fi

mkdir -p "$target"
cd "$target" || exit
pwd

# Private key
ssh-keygen -t rsa -b 4096 -m PEM -f RS256.key -q -N "$passphrase"
# For powershell
# ssh-keygen -b 2048 -t rsa -f C:/temp/sshkey -q -N '""'

# Public key
openssl rsa -in RS256.key -pubout -outform PEM -out RS256.pub

