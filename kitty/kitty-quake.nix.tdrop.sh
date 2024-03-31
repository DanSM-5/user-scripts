#!/usr/bin/env bash

# Flags: -n kitty --class=kitty
# are required because kitty from nix package manager
# needs to be wrapped in nixGL in order to launch
tdrop -ma -w 100% -h 50% \
  -n kitty --class=kitty \
  nixGL kitty --config "$HOME/user-scripts/kitty/kitty-quake.conf" "$@"
