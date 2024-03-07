#!/usr/bin/env bash

awk '$0 !~ /^#/ && NF { print $0 }' extensions.sh | xargs -n code --install-extension
