#!/usr/bin/env bash

make_gif () {
  local filename="$1"
  local start_time="$2"
  local end_time="$3"
  local include_subtitles="${4:-false}"
  local url="$1"
  local IS_FILE=false
  local IS_ONLINE=false
  local position=""
  local duration=""

  if [ -f "$filename" ]; then
    IS_FILE=true
  elif [[ "$filename" =~ ^https?:// ]]; then
    IS_ONLINE=true
  else
    echo "Invalid input: $filename"
    return 1
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

  local id="$(uuidgen)"
  local tmp_location="/tmp/gif-maker/$id"
  local palette="gif-maker_palette.png"
  local segment="gif-maker_segment"
  local out_name=""
  local SUB_FILTER=""
  local ytdlp_args=()

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
}

