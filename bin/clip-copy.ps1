#!/usr/bin/env pwsh

[CmdletBinding()]
param(
  $RegularInput = $null,
  [Parameter(ValueFromPipeline = $true)]
  $PipeInput
)

$value = if ($PipeInput) { $PipeInput } else { $RegularInput }

if (-not $value) {
  exit
}

# Cross platform clipboard-copy helper
# NOTE: only windows from prowershell should ever land here
# but let the whole structure in case running powershell somewhere else.

# TODO: requires transformation to accept pipe input
# This currently hangs

# This could use Set-Clipboard cmdlet but since that
# should be available out of the box, then use here a native binary

if ($IsWindows) {
  $value | pbcopy
} elseif ("${env:IS_TERMUX}" -eq 'true' ) {
  termux-clipboard-set $args
} elseif ($IsMacos) {
  pbpcopy $args
} elseif ($IsLinux) {
  xsel -ib $args
}

