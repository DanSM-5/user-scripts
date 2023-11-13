#!/usr/bin/env pwsh

# Cross platform clipboard-paste helper
# NOTE: only windows from prowershell should ever land here
# but let the whole structure in case running powershell somewhere else.

if ("${env:IS_WINDOWS}" -eq 'true' ) {
  pbpaste.exe $args
} elseif ("${env:IS_TERMUX}" -eq 'true' ) {
  termux-clipboard-get $args
} elseif ("${env:IS_MAC}" -eq 'true' ) {
  pbpaste $args
} elseif ("${env:IS_LINUX}" -eq 'true' ) {
  xsel -ob $args
}

