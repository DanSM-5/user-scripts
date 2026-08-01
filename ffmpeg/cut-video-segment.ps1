#!/usr/bin/env pwsh

[CmdletBinding()]
param(
  # video.mkv
  [string] $InputFile,
  # output.mkv
  [string] $OutputFile,
  # 996.371000
  [int] $StartTime,
  # 998.832000
  [int] $EndTime,
  # libx264
  [string] $Vcodec = "copy",
  # aac
  [string] $Acodec = "copy"
)

ffmpeg -ss "$StartTime" -accurate_seek -i "$InputFile" `
  -t "$(printf "%.10f" "$(($EndTime - $StartTime))")" `
  '-c:v' "$Vcodec" '-c:a' "$Acodec" `
  "$OutputFile"
