#!/usr/bin/env bash

dryrun=false

if [ "$1" = "--dry-run" ]; then
  dryrun=true
fi

# Copy desktop files to user applications folder
# and prepend nixGL to the "Exec" command

origin="$HOME/.nix-profile/share/applications"
destination="$HOME/.local/share/applications"
temp="/tmp/nix-desktop"

mkdir -p "$temp"

cleanup () {
  if [ -d "$temp" ]; then
    rm -rf "$temp"
  fi
}

trap cleanup EXIT

for file in "$origin"/*.desktop; do
  file_name="${file##*/}"
  # Important to add nixGL for GUI apps within nix
  sed 's/^Exec=/Exec=nixGL /' "$file" > "$temp/$file_name"
done

if [ "$dryrun" = true ]; then
  echo cp --force "$temp"/* "$destination"
else
  cp --force "$temp"/* "$destination"
fi

