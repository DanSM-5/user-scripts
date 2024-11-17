#!/usr/bin/env bash

# Common packages installed with pipx

pipx install ani-cli
pipx install animdl
pipx install yt-dlp
pipx install gallery-dl &&
  pipx inject gallery-dl yt-dlp
pipx install neovim-remote
pipx install speedtest-cli
pipx install vpk

pipx install mov-cli &&
  pipx inject  mov-cli beautifulsoup4 &&
  pipx inject  mov-cli yt-dlp &&
  pipx inject  mov-cli mov-cli-youtube &&
  pipx inject  mov-cli otaku-watcher &&
  pipx inject  mov-cli film-central &&
  pipx inject  mov-cli mov-cli-files
