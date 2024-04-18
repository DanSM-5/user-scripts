#!/usr/bin/env pwsh

[Cmdletbinding()]
Param (
  [String]
  [Parameter(Mandatory)]
  $PdfFile = '',
  [String]
  [Parameter(Mandatory)]
  $ImgFile = ''
)

$pdf_file = $PdfFile
$img_file = $ImgFile

magick convert -verbose -density 150 -quality 100 "$pdf_file" -background white -colorspace RGB -alpha remove "$img_file"
