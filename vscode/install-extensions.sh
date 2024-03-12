#!/usr/bin/env bash

awk '$0 !~ /^#/ && NF { print $0 }' extensions.sh | xargs -n 1 code --install-extension
