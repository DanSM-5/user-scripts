#!/usr/bin/env pwsh

[Cmdletbinding()]
Param (
  [String]
  $ImgFile = '',
  [String]
  $OutFile = 'output.png'
)

$img_file = $ImgFile
$out_file = $OutFile

if (-not "$img_file") {
  Write-Output "No Image"
  exit
}

# Not sure why using ffmpeg but keep just in case
ffmpeg -y -hide_banner -stats -i "$img_file" "$out_file"
