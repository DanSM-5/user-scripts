#!/usr/bin/env pwsh

[Cmdletbinding()]
Param (
  [String]
  $ImgFile = '',
  [String]
  $OutFile = 'img24.png'
)

$img_file = $ImgFile
$out_file = $OutFile

if (-not "$img_file") {
  Write-Output "No Image"
  exit
}

magick convert "$img_file" -depth 24 -type TrueColor PNG24:"$out_file"

