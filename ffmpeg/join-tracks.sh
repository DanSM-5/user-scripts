#!/usr/bin/env bash

[[ -v debug ]] && set -x

audio=''
video=''
output='output.mp4'
help=false
POSITIONAL_ARGS=()

help () {
  printf '%s\n' '' '> join-tracks ./path/to/audio.mp3 ./path/to/video.mp4 output.mp4' ''
}

# Allow complex regex globs
shopt -s extglob           

# Args parsing
# shellcheck disable=SC2221 disable=SC2222
while [[ $# -gt 0 ]]; do
  case $1 in
    -[aA]|-?(-)[aA]udio)
      audio="$1"
      shift # past argument
      shift # past value
      ;;
    -[vV]|-?(-)[vV]ideo)
      video="$1"
      shift # past argument
      shift # past value
      ;;
    -[oO]|-?(-)[oO]utput)
      output="$1"
      shift # past argument
      shift # past value
      ;;
    -[hH]|-?(-)[hH]elp)
      help
      exit
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # Positional args are considered urls to download
      shift # past argument
      ;;
  esac
done

# Restore positional arguments
set -- "${POSITIONAL_ARGS[@]}"

if [ -z "$audio" ]; then
  audio="$1"
  shift
fi

if [ -z "$video" ]; then
  video="$1"
  shift
fi

if [ -z "$output" ]; then
  output="$1"
  shift
fi

if [ ! -f "$audio" ] || [ ! -f "$video" ]; then
  COLOR_ERROR="$(tput setaf 1)"
  COLOR_RESET="$(tput sgr0)"   
  printf '%s\n' "${COLOR_ERROR}Missing or invalid tracks${COLOR_RESET}" >&2
  help
  exit 1
fi

ffmpeg -i "$video" -i "$audio" -c:v libx264 -acodec aac -map 0:v -map 1:a -y "$output"
