#!/usr/bin/env pwsh

# Change working dir in powershell to last dir in lf on exit.
#
# You need to put this file to a folder in $ENV:PATH variable.
#
# You may also like to assign a key to this command:
#
#     Set-PSReadLineKeyHandler -Chord Ctrl+o -ScriptBlock {
#         [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
#         [Microsoft.PowerShell.PSConsoleReadLine]::Insert('lfcd.ps1')
#         [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
#     }
#
# You may put this in one of the profiles found in $PROFILE.
#

if (Get-Command -Name "lf.exe" -ErrorAction SilentlyContinue) {
  return lf.ps1 -print-last-dir @args
}

# For user in other platforms
if ((Get-Command -Name "lf" -ErrorAction SilentlyContinue) -and !$IsWindows) {
  return lf -print-last-dir @args
}

