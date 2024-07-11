#!/usr/bin/env bash

filename="$1"
start_time="$2"
end_time="$3"
include_subtitles="$4"
keep_video="$5"
# POSITIONAL_ARGS=()

# This may require an updated bash version
shopt -s extglob

# Args parsing
# Ref: https://stackoverflow.com/a/14203146
while [[ $# -gt 0 ]]; do
  case $1 in
    -f|-?(-)[Ff]ilename)
      filename="$2"
      shift # past argument
      shift # past value
      ;;
    -s|-?(-)[Ss]tart?(-)[Tt]ime)
      start_time="$2"
      shift # past argument
      shift # past value
      ;;
    -e|-?(-)[Ee]nd?(-)[Tt]ime)
      end_time="$2"
      shift # past argument
      shift # past value
      ;;
    -i|-?(-)[Ii]nclude?(-)[Ss]usbtitles)
      include_subtitles=true
      shift # past argument
      ;;
    -k|-?(-)[Kk]eep?(-)[Vv]video)
      keep_video=true
      shift # past argument
      ;;
    -*|--*)
      printf "%s" "Unknown argument"
      exit 1
      ;;
  esac
done

# restore positional parameters
# set -- "${POSITIONAL_ARGS[@]}"

filename="$filename"
start_time="$start_time"
end_time="$end_time"
include_subtitles="${include_subtitles:-false}"
keep_video="${keep_video:-false}"
url="$filename"
IS_FILE=false
IS_ONLINE=false
position=""
duration=""

if [ -f "$filename" ]; then
  IS_FILE=true
elif [[ "$filename" =~ ^https?:// ]]; then
  IS_ONLINE=true
else
  printf "%s" "Invalid input: $filename" >&2
  exit 1
fi

if [ -z "$start_time" ]; then
  printf "%s" "No start time provided" >&2
  exit 1
fi

if [ -z "$end_time" ]; then
  printf "%s" "No end time provided" >&2
  exit 1
fi

# Add a uuidgen if it doesn't exist
if ! command -v "uuidgen" &> /dev/null; then
  uuidgen () {
    od -x /dev/urandom | head -1 | awk '{OFS="-"; print $2$3,$4,$5,$6,$7$8$9}'
  }
fi

# Detect if file has subtitles
has_subtitles () {
  local lookup_file="$1"
  local subtitle_out="$(ffprobe -loglevel error \
    -select_streams "s:0" \
    -show_entries "stream=codec_type" \
    -of "csv=p=0" \
    "$lookup_file")"

  if [[ "$subtitle_out" =~ subtitle ]]; then
    return 0
  fi

  return 1
}

if [ -f ~/.config/gif-maker.env ]; then
  # Add env variables for gif
  \. ~/.config/gif-maker.env
fi

FFMPEG="${FFMPEG:-ffmpeg}"
YT_DLP="${YT_DLP:-yt-dlp}"
FPS="${FPS:-15}"
WIDTH="${WIDTH:-600}"
HEIGHT="${HEIGHT:--1}"
EXTENSION="${EXTENSION:-gif}"
OUT_DIR="${OUT_DIR:-$HOME/gif-maker}"
FLAGS="${FLAGS:-lanczos}" # Or "spline"

id="$(uuidgen)"
tmp_location="/tmp/gif-maker/$id"
palette="gif-maker_palette.png"
segment="gif-maker_segment"
out_name=""
SUB_FILTER=""
ytdlp_args=()

: Set trap for cleanup on script EXIT
trap "rm -rf -- '$tmp_location' 2> /dev/null" EXIT

\mkdir -p "$OUT_DIR"
\mkdir -p "$tmp_location"

if [ "$IS_ONLINE" = true ]; then
  # Get filename of video
  # https://unix.stackexchange.com/questions/684116/download-and-sort-list-of-all-videos-from-a-youtube-channel-with-youtube-dl
  out_name="$("$YT_DLP" --skip-download --get-title --no-playlist "$url")"
  out_name="$(sed -re "s/[]\\\/|?\[><\"' ]/_/g" <<< "$out_name")" # Clean some chars
  filename="${tmp_location}/${segment}.mp4"
  position="0"
  duration="$(($end_time - $start_time))"

  # TODO: Add auto generated captions with '--write-auto-sub'
  # Ref: https://github.com/yt-dlp/yt-dlp/issues/5248
  if [ "$include_subtitles" = true ]; then
    ytdlp_args+=('--embed-subs' '--sub-langs' 'en.*')
  fi

  # -S Avoid hls m3u8 for ffmpeg bug (https://github.com/yt-dlp/yt-dlp/issues/7824)
  : Donwload Video Segment
  "$YT_DLP" \
    -v \
    --download-sections "*${start_time}-${end_time}" \
    --force-keyframes-at-cuts \
    -S "proto:https" \
    --path "$tmp_location" \
    --output "${segment}.%(ext)s" \
    --force-overwrites \
    -f "mp4" \
    $ytdlp_args \
    "$url"
    # --remux-video "mp4"
else
  out_name="$(basename "$filename")"
  out_name="${out_name%.*}" # Only name, no ext
  out_name="$(sed -re "s/[]\\\/|?\[><\"' ]/_/g" <<< "$out_name")" # Clean some chars
  position="$start_time"
  duration="$(($end_time - $start_time))"
fi

if [ "$include_subtitles" = true ] && has_subtitles "$filename"; then
  printf "%q" "Embeding captions in gif"
  SUB_FILTER=",subtitles='$(sed -re "s/:/\\\\:/" <<< "${filename}")':si=0"
fi

if ! [ -f "$Filename" ]; then
  printf "%s" "Online file was not downloaded: $Filename" >&2
  exit 1
fi

: Make palette
"$FFMPEG" -v warning \
  -ss "$position" -t "$duration" \
  -i "$filename" \
  -vf "[0:v:0] fps=${FPS},scale='trunc(ih*dar/2)*2:trunc(ih/2)*2',setsar=1/1,scale=${WIDTH}:${HEIGHT}:flags=${FLAGS},palettegen=stats_mode=diff" \
  -y "$tmp_location/$palette"

: Make gif
"$FFMPEG" -v warning \
  -ss "$position" -t "$duration" -copyts \
  -i "$filename" \
  -i "$tmp_location/$palette" \
  -an -ss "$position" \
  -lavfi "[0:v:0] fps=${FPS},scale='trunc(ih*dar/2)*2:trunc(ih/2)*2',setsar=1/1,scale=${WIDTH}:${HEIGHT}:flags=${FLAGS}${SUB_FILTER} [x]; [x][1:v] paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" \
  -y "$OUT_DIR/${out_name}_${id}.${EXTENSION}"

if [ "$IS_ONLINE" = true ] && [ "$keep_video" = true ]; then
  video_ext="${filename##*.}"
  mv "$filename" "$OUT_DIR/${out_name}_${id}.${video_ext}"
fi
