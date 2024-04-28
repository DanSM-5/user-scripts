#!/usr/bin/env bash
input_file="$1" # video.mkv
output_file="$2" # output.mkv
start_time="$3" # 996.371000
end_time="$4" # 998.832000
vcodec="${5:-copy}" # libx264
acodec="${6:-copy}" # aac

ffmpeg -ss "$start_time" -accurate_seek -i "$input_file" \
  -t "$(printf "%.10f" "$(($end_time - $start_time))")" \
  -c:v "$vcodec" -c:a "$acodec" \
  "$output_file"
