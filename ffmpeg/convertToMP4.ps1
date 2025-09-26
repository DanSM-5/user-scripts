#!/usr/bin/env pwsh

Param(
  # Filename
  [string] $File,
  # Out file
  [string] $Output = "outfile.mp4",
  # "copy" | "libx264" | "vp9"
  [string] $Vcodec = "libx264",
  # "copy" | "aac" | "opus"
  [string] $Acodec = "aac"
)

# NOTE: To send video in whatsapp it has to be libx264 and aac

if (!(Test-Path -Path "$file" -PathType Leaf -ErrorAction SilentlyContinue)) {
  Write-Error "No file $file"
  exit
}

ffmpeg -i "$File" -c:v "$Vcodec" -c:a "$Acodec" "$Output"

