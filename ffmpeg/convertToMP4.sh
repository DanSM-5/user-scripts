#!/usr/bin/env bash

# NOTE: To send video in whatsapp it has to be libx264 and aac

file="$1" # Filename
output="${2:-outfile.mp4}" # Out file
vcodec="${3:-libx264}" # "copy" | "libx264" | "vp9"
acodec="${4:-aac}" # "copy" | "aac" | "opus"

if ! [ -f "$file" ]; then
  printf "%s" "No file $file"
  exit 1
fi

ffmpeg -i "$file" -c:v "$vcodec" -c:a "$acodec" "$output"

