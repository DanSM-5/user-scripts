#!/usr/bin/env pwsh

[Cmdletbinding()]
Param (
  # Name of file to create gif (or url from video)
  [string] $Filename,
  # Start time from video source
  [decimal] $StartTime,
  # End time from video source
  [decimal] $EndTime,
  # Burn subtitles if available
  [Switch] $IncludeSubtitles = $false,
  # Save video
  [Switch] $KeepVideo
)

$IS_ONLINE = $false
$IS_FILE = $false
$url = $Filename
$position = -1
$duration = -1

if (Test-Path -Path "$Filename" -ErrorAction SilentlyContinue) {
  $IS_FILE = $true
} elseif ("$Filename" -match "^https?://") {
  $IS_ONLINE = $true
} else {
  Write-Error "Invalid input: $Filename"
  exit 1
}

if (!$StartTime) {
  Write-Error "No start time provided"
  exit 1
}

if (!$EndTime) {
  Write-Error "No end time provided"
  exit 1
}

# Default values
$EnvTable = @{
  FFMPEG = "ffmpeg"
  YT_DLP = "yt-dlp"
  FPS = "15"
  WIDTH ="600"
  HEIGHT = "-1"
  EXTENSION = "gif"
  OUT_DIR = "$HOME/gif-maker"
  FLAGS = "lanczos" # Or "spline"
}

if (Test-Path -Path "$HOME/.config/gif-maker.env" -ErrorAction SilentlyContinue) {
  $GifEnv = Get-Content "$HOME/.config/gif-maker.env" | ConvertFrom-StringData
  $GifEnv.GetEnumerator() | % {
    if ($EnvTable[$_.Name]) {
      $EnvTable[$_.Name] = $_.Value
    }
  }
}

$FFMPEG = $EnvTable['FFMPEG']
$YT_DLP = $EnvTable['YT_DLP']
$FPS = $EnvTable['FPS']
$WIDTH = $EnvTable['WIDTH']
$HEIGHT = $EnvTable['HEIGHT']
$EXTENSION = $EnvTable['EXTENSION']
$OUT_DIR = $EnvTable['OUT_DIR']
$FLAGS = $EnvTable['FLAGS']

$id = New-Guid
$tmp_location = "$("$env:Temp" -Replace "\\", "/")/$id"
$palette = "gif-maker_palette.png"
$segment = "gif-maker_segment"
$out_name = ""
$SUB_FILTER = ""
$ytdlp_args = @()

# Detect if file has subtitles
function has_subtitles([string] $lookup_file) {
  $subtitle_out = "$(ffprobe -loglevel error `
    -select_streams "s:0" `
    -show_entries "stream=codec_type" `
    -of "csv=p=0" `
    "$lookup_file")"

  if ("$subtitle_out" -match "subtitle") {
    return $true
  }

  return $false
}

function main() {
  # Ensure out dirs exists
  # Prefer "> $null". Ref https://stackoverflow.com/questions/5260125/whats-the-better-cleaner-way-to-ignore-output-in-powershell
  New-Item -ItemType Directory -Path "$OUT_DIR" -ea 0 > $null
  New-Item -ItemType Directory -Path "$tmp_location" -ea 0 > $null

  if ($IS_ONLINE) {
    $out_name = "$(& "$YT_DLP" --skip-download --get-title --no-playlist "$url")"
    $out_name = "$out_name" -replace "[\\/|?`"'>< []", "_" # Clean some chars
    $Filename = "${tmp_location}/${segment}.mp4"
    $position = "0"
    $duration = "$($end_time - $start_time)"

    if ($IncludeSubtitles) {
      # TODO: Add auto generated captions with '--write-auto-sub'
      # Ref: https://github.com/yt-dlp/yt-dlp/issues/5248
      $ytdlp_args += @('--embed-subs', '--sub-langs', 'en.*')
    }

    & "$YT_DLP" `
      -v `
      --download-sections "*${StartTime}-${EndTime}" `
      --force-keyframes-at-cuts `
      -S "proto:https" `
      --path "$tmp_location" `
      --output "${segment}.%(ext)s" `
      --force-overwrites `
      -f "mp4" `
      $ytdlp_args `
      "$url"
  } else {
    # Get file name: https://stackoverflow.com/questions/35813186/extract-the-filename-from-a-path
    $out_name = [System.IO.Path]::GetFileNameWithoutExtension("$Filename")
    $out_name = "$out_name" -replace "[\\/|?`"'>< []", "_" # Clean some chars
    $position = "$start_time"
    $duration = "$($end_time - $start_time)"
  }

  if ($IncludeSubtitles -and (has_subtitles "$Filename")) {
    Write-Host "Embeding captions in gif"
    $SUB_FILTER = ",subtitles='$("$Filename" -replace ":","\:")':si=0"
  }

  if (!(Test-Path -Path $Filename -PathType Leaf -ErrorAction SilentlyContinue)) {
    Write-Error "Online file was not downloaded: $Filename"
    exit 1
  }

  # Make palette
  & "$FFMPEG" -v warning `
    -ss "$position" -t "$duration" `
    -i "$Filename" `
    -vf "[0:v:0] fps=${FPS},scale='trunc(ih*dar/2)*2:trunc(ih/2)*2',setsar=1/1,scale=${WIDTH}:${HEIGHT}:flags=${FLAGS},palettegen=stats_mode=diff" `
    -y "$tmp_location/$palette"

  # Make gif
  & "$FFMPEG" -v warning `
    -ss "$position" -t "$duration" -copyts `
    -i "$Filename" `
    -i "$tmp_location/$palette" `
    -an -ss "$position" `
    -lavfi "[0:v:0] fps=${FPS},scale='trunc(ih*dar/2)*2:trunc(ih/2)*2',setsar=1/1,scale=${WIDTH}:${HEIGHT}:flags=${FLAGS}${SUB_FILTER} [x]; [x][1:v] paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" `
    -y "$OUT_DIR/${out_name}_${id}.${EXTENSION}"

  if ($IS_ONLINE -and $KeepVideo) {
    $video_ext = [System.IO.Path]::GetExtension("$Filename")
    Move-Item "$Filename" "$OUT_DIR/${out_name}_${id}.${video_ext}"
  }
}

try {
  main
} finally {
  # Cleanup on Exit
  Remove-Item -Recurse -Force "$tmp_location" -ErrorAction SilentlyContinue
}

