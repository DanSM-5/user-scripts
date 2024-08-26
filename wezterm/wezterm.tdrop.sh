#!/usr/bin/env bash

# export WEZTERM_QUAKE_MODE=1

# Disable tab bar 'enable_tab_bar=false'
# also 'hide_tab_bar_if_only_one_tab=true'

# Flags: -n wezterm --class=wezterm
tdrop -ma -w 100% -h 50% \
  -n wezterm --class=wezterm \
   wezterm \
    --config 'window_decorations="NONE"' \
    --config 'enable_tab_bar=false' \
    "$@"

