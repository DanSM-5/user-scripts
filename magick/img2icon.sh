#!/usr/bin/env bash

img_file="$1"
size="$2"
ext="${3:-png}"

if [ -z "$size" ] || [ -z "$img_file" ]; then
  printf "Missing args"
  exit
fi

magick convert -resize "${size}x${size}" "$img_file" "icon${size}.$ext"

