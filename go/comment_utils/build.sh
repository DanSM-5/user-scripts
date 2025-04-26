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

if [ -z "$script_location" ]; then
  printf 'Cannot identify the build script location\n' >&2
  exit 1
fi

out_bin="${script_location:?Error creating bin directory}/bin"

if [ -d "$out_bin" ]; then
  rm --recursive "$out_bin"
fi

mkdir -p "$out_bin"

build_flags=()

# Do not include if `dev` environment variable is set
if ! [[ -v dev ]]; then
  build_flags+=(
    -ldflags
    "-s -w"
    -trimpath
  )
fi

for program in "${programs[@]}"; do
  # Build for Linux amd64
  CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build "${build_flags[@]}" -o "$out_bin/${program}_linux" "$script_location/$program/$program.go"

  # Build for Windows amd64
  CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build "${build_flags[@]}" -o "$out_bin/${program}.exe" "$script_location/$program/$program.go"

  # Build for macOS amd64
  if [[ -v buildmac ]]; then
    arch="${MACARCH:-}"
    if [ -z "$arch" ]; then
      if [[ "$(uname -a)" =~ x86_64.* ]]; then
        arch='amd64'
      else
        arch='arm64'
      fi
    fi

    CGO_ENABLED=0 GOOS=darwin GOARCH="$arch" go build "${build_flags[@]}" -o "$out_bin/${program}_darwin" "$script_location/$program/$program.go"
  fi

  if ! [[ -v dev ]]; then
    if ! command -v upx &>/dev/null; then
      printf '%s' "Cannot optimize '$program'. No upx program found."
      continue
    fi

    upx --best --lzma "$out_bin/${program}_linux"
    upx --best --lzma "$out_bin/${program}.exe"
    # upx --best --lzma "$out_bin/${program}_darwin"
  fi
done

printf '%s\n' 'Build complete. Binaries are in the "bin" directory.'
