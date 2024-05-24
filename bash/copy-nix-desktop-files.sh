#!/usr/bin/env bash

# Copy desktop files to user applications folder
# and prepend nixGL to the "Exec" command

origin="$HOME/.nix-profile/share/applications"
destination="$HOME/.local/share/applications"

for file in "$origin"/*.desktop; do
  file_name="$(basename "$file")"
  sed 's/^Exec=/Exec=nixGL /' "$file" > "$destination/$file_name"
done
