#!/usr/bin/env bash
yf () {
  # Set starting page with flag -p[n]
  local startpage=1
  local direct_play=false
  local linkOnly=false
  local selection=""
  for arg do
    shift
    if [[ "$arg" =~ -p[0-9]+ ]]; then
      # Remove -p arg and use value as pages_start
      startpage="${arg:2}"
      continue
    elif [[ "$arg" = "--direct-play" ]]; then
      direct_play=true
      continue
    elif [[ "$arg" = "-L" ]]; then
      # -L is always called in this wrapper
      # Detect it here to prevent playback
      linkOnly=true
    fi
    set -- "$@" "$arg"
  done

  if [[ "$linkOnly" = false ]] && [[ "$direct_play" = true ]]; then
    selection="$(pages_start="$startpage" ytfzf -L "$@")"

    if [ -z "$selection" ]; then
      return 1 
    fi

    echo "Playing: $selection\n"

    yt-dlp -o - "$selection" | mpv --cache -
    return
  fi

  pages_start="$startpage" ytfzf "$@"
}

yfd () {
  yf --direct-play "$@"
}

export MPV_HOME="$HOME/sdcard/mpv"

"$@"
