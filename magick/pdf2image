#!/usr/bin/env bash

pdf_file="$1"
img_file="$2"

if [ -z "$pdf_file" ] || [ -z "$img_file" ]; then
  printf "Missing args"
  exit
fi

magick convert -verbose -density 150 -quality 100 "$pdf_file" -background white -colorspace RGB -alpha remove "$img_file"

