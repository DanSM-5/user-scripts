#!/usr/bin/env pwsh

[Cmdletbinding()]
Param (
  [String]
  $ImgFile = '',
  [String]
  $FileExt = 'png'
)

$img_file = $ImgFile
$ext = $FileExt

if (-not $img_file) {
  Write-Output "No Image"
  exit
}

# Icon sizes
$sizes = @(16,20,32,48,64,96,128,256)
$outdir = "output-$(Get-Date -UFormat %s)"

# Make outdir
New-Item $outdir -ItemType Directory -ea 0

foreach ($size in $sizes) {
  magick convert "$img_file" -colorspace sRGB -resize "${size}x${size}" "$outdir/icon${size}.$ext"
}
