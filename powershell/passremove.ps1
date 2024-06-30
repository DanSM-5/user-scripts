#!/usr/bin/env pwsh

Param (
  # Password for archive file
  [String] $Password,
  # Directory with archives
  [String] $Location
)

$ErrorActionPreference = "Stop"
$statingLocation = Get-Location

try {
  With-UTF8 {
    $files = Get-ChildItem $Location
    $initial_path = $Location

    foreach ($file in $files) {
      Set-Location $initial_path
      $ext = [System.IO.Path]::GetExtension($file.Name)
      $dirname = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
      $newCompressed = "${dirname}${ext}"
      $oldCompressed = $file.Name + ".old"

      $sevenZipExtractArgs = @(
        "x"
        "-p$Password"
        "-o$dirname"
        "--"
        $file.Name
      )

      $sevenZipCompressArgs = @(
        "a"
        "$newCompressed"
        "--"
      )

      try {
        7z @sevenZipExtractArgs
        if (-not $?)
        {
          throw '7z Uncompress error'
        }

        # Move original
        Move-Item $file.Name ($file.Name + ".old")

        # Change location to tempfile
        Set-Location $dirname

        7z @sevenZipCompressArgs *
        if (-not $?)
        {
          throw '7z Compress error'
        }

        Move-Item $newCompressed $initial_path
        Set-Location $initial_path
        Remove-Item -Path "$dirname" -Recurse -Force

        Write-Host "
File $file has been processed.
Old: $oldCompressed
New: $newCompressed
"
      } catch {
        Write-Error "Error with file $file " $_.Exception.Message
        Write-Host "Pass: $Password | Compress args: $sevenZipCompressArgs | Uncompress args: $sevenZipExtractArgs"
      }
    }
  }
} finally {
  Set-Location $statingLocation
}

