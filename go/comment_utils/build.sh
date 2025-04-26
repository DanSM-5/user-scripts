#!/usr/bin/env bash

# Setup
[[ -v debug ]] && set -x
set -e # Exit immediately if a command exits with a non-zero status.

# Ref: https://stackoverflow.com/questions/59895/how-do-i-get-the-directory-where-a-bash-script-is-located-from-within-the-script
SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
  SOURCE=$(readlink "$SOURCE")
  [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
script_location=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )

programs=(
  'comment'
  'uncomment'
)

mkdir -p "$script_location/bin"

for program in "${programs[@]}"; do
  # Build for Linux amd64
  GOOS=linux GOARCH=amd64 go build -o "$script_location/bin/${program}_linux" "$script_location/$program/$program.go"

  # Build for Windows amd64
  GOOS=windows GOARCH=amd64 go build -o "$script_location/bin/${program}.exe" "$script_location/$program/$program.go"

  # Build for macOS amd64
  GOOS=darwin GOARCH=arm64 go build -o "$script_location/bin/${program}_darwin" "$script_location/$program/$program.go"
done

echo 'Build complete. Binaries are in the "bin" directory.'
