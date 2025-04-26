#!/usr/bin/env bash

[[ -v debug ]] && set -x

user_script_path="${user_script_path:-"$HOME/user-scripts"}"

if ! [ -d "$user_script_path" ]; then
  exit 1
fi

# Ref: https://stackoverflow.com/questions/59895/how-do-i-get-the-directory-where-a-bash-script-is-located-from-within-the-script
SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
  SOURCE=$(readlink "$SOURCE")
  [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
script_location=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )

for item in "$script_location/bin/"*; do
  chmod +x "$item"
  cp "$item" "$user_script_path/bin"
done
