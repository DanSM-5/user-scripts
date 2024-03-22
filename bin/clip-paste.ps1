#!/usr/bin/env pwsh

# Cross platform clipboard-paste helper
# NOTE: only windows from prowershell should ever land here
# but let the whole structure in case running powershell somewhere else.

# This could use Get-Clipboard cmdlet but since that
# should be available out of the box, then use here a native binary

if ($IsWindows) {
  pbpaste $args
} elseif ("${env:IS_TERMUX}" -eq 'true' ) {
  termux-clipboard-set $args
} elseif ($IsMacos) {
  pbpaste $args
} elseif ($IsLinux) {
  xsel -ob $args
}
