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
  $(lf.ps1 -print-last-dir @args) | Set-Location
}

# For user in other platforms
if ((Get-Command -Name "lf" -ErrorAction SilentlyContinue) -and !$IsWindows) {
  lf -print-last-dir @args | Set-Location
}

