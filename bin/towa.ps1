#!/usr/bin/env pwsh

# Re-encode a video to make it compatible with sites like whatsapp
# Output file is copied to clipboard and path is echo out for pipe use

[CmdletBinding()]
param(
  $File = $null
)

if (!$File) {
  exit
}

$tmp_file = ''

try {
  $tmp_file = (New-TemporaryFile).FullName
} catch {
  $tmp_file = ([System.IO.Path]::GetTempFilename())
}

# We just want the filename
Remove-Item -Recurse -Force $tmp_file -ErrorAction SilentlyContinue
$tmp_file = $tmp_file + '.mp4'

ffmpeg -i "$File" '-c:v' 'libx264' -crf 23 '-c:a' 'aac' '-b:a' 128k $tmp_file

copy-file $tmp_file
Write-Output $tmp_file
