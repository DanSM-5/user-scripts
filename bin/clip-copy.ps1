#!/usr/bin/env pwsh

# Cross platform clipboard-copy helper
# NOTE: only windows from prowershell should ever land here
# but let the whole structure in case running powershell somewhere else.

# TODO: requires transformation to accept pipe input
# This currently hangs

if ("${env:IS_WINDOWS}" -eq 'true' ) {
  pbcopy.exe $args
} elseif ("${env:IS_TERMUX}" -eq 'true' ) {
  termux-clipboard-set $args
} elseif ("${env:IS_MAC}" -eq 'true' ) {
  pbpcopy $args
} elseif ("${env:IS_LINUX}" -eq 'true' ) {
  xsel -ib $args
}

