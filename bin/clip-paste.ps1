#!/usr/bin/env pwsh

# Cross platform clipboard-paste helper
#
# Dependencies
# Windows: `Win32Yank` or `pasteboard` package
# Linux: `xsel`. Install xsel from your package manager e.g. `sudo apt install xsel`

# NOTE: only windows from prowershell should ever land here
# but let the whole structure in case running powershell somewhere else.

# About variables: See detection script

# Original encoding backup
$InitialOutputEncoding = $OutputEncoding
$InitialConsoleEncoding = [Console]::OutputEncoding

try {
  # Ensure UTF-8 for windows
  $OutputEncoding = [Console]::OutputEncoding = New-Object System.Text.Utf8Encoding

  if ($IsWindows -or ($env:OS -eq 'Windows_NT')) {
    With-UTF8 {
      if (Get-Command -Name 'win32yank' -ErrorAction SilentlyContinue) {
        win32yank -o @args
      } elseif (Get-Command -Name 'pbpaste' -ErrorAction SilentlyContinue) {
        pbpaste @args
      } else {
        Get-Clipboard @args
      }
    }
  } elseif ("${env:IS_TERMUX}" -eq 'true' ) {
    termux-clipboard-set @args
  } elseif ($IsMacos) {
    try {
      pbpaste @args
    } catch {
      Get-Clipboard @args
    }
  } elseif ($IsLinux) {
    if (Get-Command -Name 'wl-paste' -ErrorAction SilentlyContinue) {
      wl-paste @args
    } elseif (Get-Command -Name 'xsel' -ErrorAction SilentlyContinue) {
      xsel -o -b @args
    } elseif (Get-Command -Name 'xclip' -ErrorAction SilentlyContinue) {
      xclip -o -selection clipboard @args
    } else {
      Get-Clipboard @args
    }
  } else {
    Get-Clipboard
  }
} finally {
  $OutputEncoding = $InitialOutputEncoding
  [Console]::OutputEncoding = $InitialConsoleEncoding
}

