#!/usr/bin/env pwsh

<#
.SYNOPSIS
  Helper to bulk remove a password from archives multiple archives.

.DESCRIPTION
  This is not a hack password removal tool. Rather, if you have many archives with a
  password (that you know of) and you'd like to recreate the archives without it,
  then this script can help you out.

.PARAMETER Password
  The password for the archives. This is needed to be able to extract the content of the
  archive.

.PARAMETER Location
  Directory that contains the archives

.PARAMETER SevenZipCmd
  Command to be used for archiving and unarchiving. It must be 7z compatible (e.g. p7zip).

.PARAMETER InTypeArchive
  Type of archive to uncompress. Default 7z.

.PARAMETER OutTypeArchive
  Type of archive to compress. Default 7z.

.INPUTS
  No inputs from pipeline

.OUTPUTS
  The script does not provide useful output besides the output of the 7z command

.EXAMPLE
  passremove -Password 'secret1' -Location $HOME/archives

.EXAMPLE
  passremove -Password 'secret1' -Location $HOME/archives -SevenZipCmd '7zz'

.NOTES
  This script can be easily changed to use a different archiving tool and changing the flags
  for compression and extraction.
  If an error occurs, the script will print detailed information of the commands for extract and
  compress the archive.
#>

[CmdletBinding()]
Param (
  # Password for archive file
  [String] $Password,
  # Directory with archives
  [String] $Location,
  # Command to be used. It has to be 7z compatible
  # This is for linux where there is 7z and 7zz
  [String] $SevenZipCmd = '7z',
  [String] $InTypeArchive = '7z',
  [String] $OutTypeArchive = '7z'
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

      # Modify args for command here

      # [Extract]
      $sevenZipExtractArgs = @(
        "x"
        "-t$InTypeArchive"
        "-p$Password"
        "-o$dirname"
        "--"
        $file.Name
      )

      # [Compress]
      $sevenZipCompressArgs = @(
        "a"
        "-t$OutTypeArchive"
        "$newCompressed"
        # Important: This is added because the next argument
        # will be the files which are matched with a glob
        "--"
      )

      try {

        # [Extract content]
        & $SevenZipCmd @sevenZipExtractArgs
        if (-not $?) {
          throw '7z Uncompress error'
        }

        # Move original
        Move-Item $file.Name $oldCompressed

        # Change location to tempfile
        Set-Location $dirname

        # [Compress content]
        & $SevenZipCmd @sevenZipCompressArgs *
        if (-not $?) {
          throw '7z Compress error'
        }

        # [Update]
        Move-Item $newCompressed $initial_path
        Set-Location $initial_path
        # [Cleanup]
        Remove-Item -Path "$dirname" -Recurse -Force

        Write-Host "
File $file has been processed.
Old: $oldCompressed
New: $newCompressed
"
      } catch {
        Write-Error "Error with file $file " $_.Exception.Message
        Write-Host "
        Process used args
        Pass: $Password
        Compress args: $sevenZipCompressArgs
        Uncompress args: $sevenZipExtractArgs
"
      }
    }
  }
} finally {
  Set-Location $statingLocation
}

