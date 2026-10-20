#!/usr/bin/env pwsh

$document = "$args"

if (!(Test-Path -LiteralPath $document -ErrorAction SilentlyContinue)) {
  Write-Error "Path '$document' does not exists"
  exit
}

$tmp_script = ''

try {
  $tmp_script = New-TemporaryFile
  $tmp_script = $tmp_script.FullName
} catch {
  $tmp_script = [System.IO.Path]::GetTempFilename()
} finally {
  if (Test-Path -LiteralPath $tmp_script -ErrorAction SilentlyContinue) {
    Remove-Item -Recurse -Force -LiteralPath $tmp_script -ErrorAction SilentlyContinue
  }

  $tmp_script = "$tmp_script.cmd"
}

@"
@echo off
takeown /f "%*" /r /d y
icacls "%*" /grant administrators:F /t
rd /s /q "%*"
"@ > $tmp_script

try {
  & $tmp_script $document
} finally {
  if (Test-Path -LiteralPath $tmp_script -ErrorAction SilentlyContinue) {
    Remove-Item -Recurse -Force -LiteralPath $tmp_script -ErrorAction SilentlyContinue
  }
}
