#!/usr/bin/env pwsh

[Cmdletbinding()]
Param (
  [String]
  $ImgFile = '',
  [String]
  $OutFile = 'icon.ico'
)

$img_file = $ImgFile
$out_file = $OutFile

if (-not "$img_file") {
  Write-Output "No Image"
  exit
}

$ico_sizes = "16,20,32,48,64,96,128,256"

magick convert "$img_file" -colorspace sRGB -resize 256x256 -define icon:auto-resize="$ico_sizes" "$out_file"

