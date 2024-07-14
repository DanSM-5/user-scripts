#!/usr/bin/env bash

# Use jq to parse application names
nix profile list --json |
  jq -r '.elements | keys | join("\n")' |
  xargs nix profile upgrade --impure

  # Add before xargs to prevent updating nixGL if it has issues
  # awk '!/nix.+/ { print }' |
