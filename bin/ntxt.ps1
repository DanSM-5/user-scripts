#!/usr/bin/env pwsh

<#
.SYNOPSIS
  Create or open a text file in a standard location.

.DESCRIPTION
  Creates text files in a standard location to store notes.
  If the file already exists, it will open it.

.PARAMETER Filename
  Optional parameter to specify file name. If not provided, it will use a random name with a UUID.

.INPUTS
  None

.OUTPUTS
  None

.EXAMPLE
  ntxt

.EXAMPLE
  ntxt filename.md

.NOTES
  Cross platform script.
  Use `PREFERRED_EDITOR` or `EDITOR` environment variable to configure the text editor to use.
  Use `TXT_LOCATION` to configure the path to the txt directory that will store the text files.
  Use it in conjunction with `ftxt` command to search for created files.

#>

# Directions:
# - Use PREFERRED_EDITOR or EDITOR to set a your prefer editor program
# - Use TXT_LOCATION to customize location of directory with text files

[CmdletBinding()]
Param(
  # To use random name if not supplied
  [String] $filename = ''
)

# Detect native path separator
$dirsep = if ($IsWindows -or ($env:OS -eq 'Windows_NT')) { '\' } else { '/' }
# Defaults to vim
$editor = if ($env:PREFERRED_EDITOR) { $env:PREFERRED_EDITOR } elseif ($env:EDITOR) { $env:EDITOR } else { 'vim' }
# Defaults to $HOME/prj/txt
$dirlocation = if ($env:TXT_LOCATION) { $env:TXT_LOCATION } else { "${HOME}${dirsep}prj${dirsep}txt" }

$filename = if ($filename) { $filename } else { "note_$(Get-Date -Format 'dd-MM-yyyy_HH:mm:ss').md" }
$filename = "${dirlocation}${dirsep}${filename}"

New-Item -Path $dirlocation -ItemType Directory -ErrorAction SilentlyContinue

& $editor "$filename"

