#!/usr/bin/env bash

[[ -v debug ]] && set -x

if ! command -v zstd &>/dev/null; then
  printf "%s\n" "Missing zstd package to extract '.tar.zst'"
  printf "%s\n" "Hint: scoop install zstd"
  exit
fi

if ! command -v gsudo &>/dev/null; then
  printf "%s\n" "Missing 'gsudo' package to elevate copy process"
  printf "%s\n" "Hint: scoop install gsudo"
  exit
fi

if ! command -v rclone &>/dev/null; then
  printf "%s\n" "Missing 'rclone' package to copy safely"
  printf "%s\n" "Hint: scoop install rclone"
  exit
fi

temp_zsh_dir="$TEMP/zsh"
tarball_url="https://mirror.msys2.org/msys/x86_64/zsh-5.9-2-x86_64.pkg.tar.zst"
gitbash_dir="$(where.exe bash | grep 'Git\\usr\\bin\\bash' | sed 's/\\usr\\bin\\bash.exe//')"
# Generated with wcurl. Requires updated curl to work
curl_ops=(
  --globoff
  --location
  --no-clobber
  --proto-default
  https
  --remote-name-all
  --remote-time
  --retry
  10
  --retry-max-time
  10
)

cleanup () {
  if test -d "$temp_zsh_dir"; then
    rm -rf -- "$temp_zsh_dir"
  fi
}

# Remove tmp dir on exit
trap cleanup EXIT

# Yes, another zsh nested directory
mkdir -p "$temp_zsh_dir/zsh"
pushd "$temp_zsh_dir" || exit
# Download zsh
curl "${curl_ops[@]}" "$tarball_url"
# Extract zsh archive. Name could vary but the end should remain the same, so use glob
tar --zstd -xvf *x86_64.pkg.tar.zst --directory "$temp_zsh_dir/zsh"

win_temp_zsh_dir="$(cygpath -ma "$temp_zsh_dir")"
# Copy files. Using gsudo to elevate and rclone to copy only new files (and because I don't know better... sorry).
gsudo rclone -v -u copy "$win_temp_zsh_dir/zsh" "$gitbash_dir"
popd || exit

printf "%s\n" "Testing if it works..."
printf "%s\n" "$(which zsh)"

