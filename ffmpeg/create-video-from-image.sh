#!/usr/bin/env bash
input_file="$1" # img.png
output_file="$2" # out.mp4
codec="${3:-libx264}" # libx264
time="${4:-5}" # 5

ffmpeg -loop 1 -i "$input_file" -c:v "$codec" -t "$time" -pix_fmt yuv420p "$output_file"
