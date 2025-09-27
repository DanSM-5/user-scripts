#!/usr/bin/env pwsh

# With-UTF8.ps1
# Usage
# ```powershell
# With-UTF8 { command }
# ```

[CmdletBinding()]
Param (
  [scriptblock] $block
)

# Script block info
# Ref: https://stackoverflow.com/questions/11844390/how-do-i-pass-a-scriptblock-as-one-of-the-parameters-in-start-job

$codepage = 0

try {
  # Ref: https://stackoverflow.com/questions/49476326/displaying-unicode-in-powershell
  # Save the current settings and temporarily switch to UTF-8.
  # $oldOutputEncoding = $OutputEncoding;
  # $oldConsoleEncoding = [Console]::OutputEncoding
  # $OutputEncoding = [Console]::OutputEncoding = New-Object System.Text.Utf8Encoding

  # NOTE: Changing to codepage approach to prevent issues from cli programs that
  # change codepage but fail to restore it properly
  $codepage = ($(chcp) -split ' ')[3]

  # Execute block with utf-8 encoding
  return & $block
} finally {
  # Restore the previous settings.
  # $OutputEncoding = $oldOutputEncoding;
  # [Console]::OutputEncoding = $oldConsoleEncoding
  chcp $codepage *> $null
}

