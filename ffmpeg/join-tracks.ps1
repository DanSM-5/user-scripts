#!/usr/bin/env pwsh

[CmdletBinding()]
Param (
  [string] $audio,
  [string] $video,
  [string] $output = 'output.mp4',
  [switch] $help = $false
)

function help () {
  Write-Output '
> join-tracks ./path/to/audio.mp3 ./path/to/video.mp4 output.mp4
'
}

if ($help) {
  help
  exit
}

if ((!(Test-Path -LiteralPath $audio -PathType Leaf -ErrorAction SilentlyContinue)) -or (!(Test-Path -LiteralPath $video -PathType Leaf -ErrorAction SilentlyContinue))) {
  Write-Error 'Missing or invalid tracks'
  help
  exit 1
}

ffmpeg -i "$video" -i "$audio" -c:v libx264 -acodec aac -map 0:v -map 1:a -y "$output"
