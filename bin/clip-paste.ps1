#!/usr/bin/env pwsh

# Cross platform clipboard-paste helper
#
# Dependencies
# Windows: `pasteboard` package. Install from scoop: `scoop install pasteboard`
# Linux: `xsel`. Install xsel from your package manager e.g. `sudo apt install xsel`

# NOTE: only windows from prowershell should ever land here
# but let the whole structure in case running powershell somewhere else.

# This could use Get-Clipboard cmdlet but since that
# should be available out of the box, then use here a native binary

# About variables: See detection script

# Original encoding backup
$InitialOutputEncoding = $OutputEncoding
$InitialConsoleEncoding = [Console]::OutputEncoding

try {
  # Ensure UTF-8 for windows
  $OutputEncoding = [Console]::OutputEncoding = New-Object System.Text.Utf8Encoding

  if ($IsWindows) {
    With-UTF8 {
      pbpaste $args
    }
  } elseif ("${env:IS_TERMUX}" -eq 'true' ) {
    termux-clipboard-set $args
  } elseif ($IsMacos) {
    pbpaste $args
  } elseif ($IsLinux) {
    xsel -ob $args
  }
} finally {
  $OutputEncoding = $InitialOutputEncoding
  [Console]::OutputEncoding = $InitialConsoleEncoding
}

