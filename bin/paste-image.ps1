<#
.SYNOPSIS
Saves the Windows clipboard image to a file.

.DESCRIPTION
Writes the clipboard image to NAME in the current directory. A supported file
extension selects the output format. When NAME has no extension, .png is used
because the Windows clipboard API does not expose the source MIME type. This
script is also the Windows clipboard backend used by paste-image.sh in WSL,
Git Bash, and Cygwin.

Supported extensions are .png, .jpg, .jpeg, .bmp, .gif, .tif, and .tiff.

.EXAMPLE
.\paste-image.ps1 diagram

Creates diagram.png in the current directory.

.EXAMPLE
.\paste-image.ps1 photo.jpg

Creates photo.jpg as a JPEG image in the current directory.

.EXAMPLE
.\paste-image.ps1 --help

Displays this help text. The help, -h, and --help forms are supported.
#>

[CmdletBinding()]
param (
  [Parameter(Position = 0)]
  [String] $Filename = 'out',

  [String] $OutputPath,

  [Alias('h', '-help')]
  [Switch] $Help,

  [Switch] $Quiet
)

if ($Help -or $Filename -eq 'help') {
  Get-Help $PSCommandPath -Detailed
  Exit 0
}

if ([String]::IsNullOrWhiteSpace($Filename)) {
  $Filename = 'out'
}

if ([String]::IsNullOrWhiteSpace($OutputPath)) {
  if ([String]::IsNullOrWhiteSpace([IO.Path]::GetExtension($Filename))) {
    $Filename = "$Filename.png"
  }
  $file = Join-Path -Path $PWD.Path -ChildPath $Filename
} else {
  $file = [IO.Path]::GetFullPath($OutputPath)
  if ([String]::IsNullOrWhiteSpace([IO.Path]::GetExtension($file))) {
    $file = "$file.png"
  }
}

Add-Type -AssemblyName PresentationCore

$extension = [IO.Path]::GetExtension($file).ToLowerInvariant()
switch ($extension) {
  '.png' {
    $encoder = New-Object Windows.Media.Imaging.PngBitmapEncoder
  }
  { $_ -in '.jpg', '.jpeg' } {
    $encoder = New-Object Windows.Media.Imaging.JpegBitmapEncoder
    $encoder.QualityLevel = 95
  }
  '.bmp' {
    $encoder = New-Object Windows.Media.Imaging.BmpBitmapEncoder
  }
  '.gif' {
    $encoder = New-Object Windows.Media.Imaging.GifBitmapEncoder
  }
  { $_ -in '.tif', '.tiff' } {
    $encoder = New-Object Windows.Media.Imaging.TiffBitmapEncoder
  }
  default {
    Write-Error "Unsupported image extension: $extension"
    Exit 2
  }
}

if (-not $Quiet) {
  Write-Output "Creating: $file"
}

$image = [Windows.Clipboard]::GetImage()
if ($null -eq $image) {
  Write-Error 'Clipboard does not contain an image.'
  Exit 1
}

$convertedImage = New-Object Windows.Media.Imaging.FormatConvertedBitmap($image, [Windows.Media.PixelFormats]::Rgb24, $null, 0)
$encoder.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($convertedImage))

$stream = [IO.File]::Open(
  $file,
  [IO.FileMode]::Create,
  [IO.FileAccess]::Write,
  [IO.FileShare]::None
)
try {
  $encoder.Save($stream)
} finally {
  $stream.Dispose()
}

if (-not $Quiet) {
  Write-Output "Created: $file"
}
