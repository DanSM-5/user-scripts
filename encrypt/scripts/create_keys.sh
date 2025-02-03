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
ssh-keygen -t rsa -b 4096 -m PEM -f RS256-private.pem -q -N "$passphrase"
# For powershell
# ssh-keygen -b 2048 -t rsa -f C:/temp/sshkey -q -N '""'
# Other valid commands
# openssl genpkey -algorithm RSA -out RS256-private.pem -aes256
# openssl genpkey -algorithm RSA -out RS256-private.pem -pkeyopt rsa_keygen_bits:2048
# openssl genrsa -out RS256-private.pem 2048

# Public key
openssl rsa -pubout -outform PEM -in RS256-private.pem -out RS256-public.pem

