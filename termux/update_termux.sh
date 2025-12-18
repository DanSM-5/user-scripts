#!/usr/bin/env bash

install_ytdlp () {
  rm -rf "$HOME/.local/bin/yt-dlp" || true
  rm -rf "$HOME/.local/share/pipx" || true
  python3 -m pip install pipx
  pipx install yt-dlp
}

check_dep () {
  if command -v "$1" &> /dev/null; then
    printf '%s installed\n' "$1"
  else
    printf '%s NOT installed\n' "$1"
  fi
}

verify_programs () {
  check_dep node
  check_dep python
  check_dep deno
  check_dep ffmpeg
  check_dep yt-dlp
}

install_dep () {
  if ! command -v "$1" &> /dev/null; then
    pkg install "$1" -y
  fi
}

install_packages () {
  if ! command -v 'node' &> /dev/null; then
    pkg install nodejs -y
  fi
  if ! command -v 'python' &> /dev/null; then
    pkg install python python-pip -y
  fi
  install_dep deno
  install_dep ffmpeg
}

update_termux () {
  yes | pkg upgrade
  install_packages

  # Check if yt-dlp exitst
  if ! command -v yt-dlp &> /dev/null; then
    install_ytdlp
  # Check if yt-dlp is not broken
  elif ! yt-dlp --version &> /dev/null; then
    install_ytdlp
  elif [ "$FORCE_YTDLP_UPDATE" = 1 ]; then
    install_ytdlp
  fi

  pipx upgrade yt-dlp --include-injected
}

setup_termux () {
  termux-setup-storage
  update_termux
  verify_programs
}

# Update bashrc
cat <<EOF > "$HOME/.bashrc"
#!/usr/bin/env bash

# Termux update helper script
# Generated $(date)

alias bj="cd /storage/emulated/0"
export PATH="\$HOME/.local/bin:\$PATH"

youtube () {
  # Prepare variables
  output_dir=/storage/emulated/0/youtube
  mkdir -p "\$output_dir"

  # Navigate to output
  pushd "\$output_dir" || exit

  # Download video
  yt-dlp -S res,ext:mp4:m4a --recode mp4 "\$(termux-clipboard-get)"

  # Restore
  popd || exit
}

update () {
  curl -sSL https://raw.githubusercontent.com/DanSM-5/user-scripts/refs/heads/master/termux/update_termux.sh | bash
}
EOF

setup_termux
