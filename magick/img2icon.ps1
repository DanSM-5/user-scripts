#!/usr/bin/env pwsh

[Cmdletbinding()]
Param (
  [String]
  $ImgFile = '',
  [String]
  $FileSize = '',
  [String]
  $FileExt = 'png'
)

$img_file = $ImgFile
$size = $FileSize
$ext = $FileExt

if ((-not $size) -or (-not "$img_file")) {
  Write-Output "Missing args"
  exit
}

magick convert -resize "${size}x${size}" "$img_file" "icon${size}.$ext"

