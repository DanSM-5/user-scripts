#!/usr/bin/env pwsh

<#
.SYNOPSIS
  Add [Target] to the Start Menu directory

.DESCRIPTION
  Add the [Target] to the "Start Menu" directory as a shortcut to allow
  the file to be visible in the start menu on windows.

.PARAMETER Target
  File or directory to add to "Start Menu" directory.

.PARAMETER LinkArgs
  List of arguments to add to the shortcut ".lnk" file.

.INPUTS
  String to be used as the "Target" argument.

.OUTPUTS
  Message if link was created.

.EXAMPLE
  add-start './path/to/file.exe'

.EXAMPLE
  add-start './path/to/directory'

.EXAMPLE
  add-start -Target './path/to/chrome.exe' -LinkArgs '--disable-web-security', '--disable-site-isolation-trials'

.EXAMPLE
  Write-Output 'path/to/file' | add-start
#>

[CmdletBinding()]
Param(
  [Parameter(
    ValueFromPipeline = $true,
    ValueFromPipelineByPropertyName = $true
  )]
  [String] $Target,
  [Parameter(ValueFromRemainingArguments = $true)]
  [String[]] $LinkArgs = @()
)

$fullpath = (Resolve-Path -LiteralPath $Target).Path

if (-not (Test-Path -LiteralPath $fullpath -ErrorAction SilentlyContinue)) {
  Write-Error "The path $Target is invalid"
  exit 1
}

# Version lower than 6 can only be possible in windows powershell
if (($PSVersionTable.PSVersion -lt [version]'6.0.0')) {
  $pathsep = '\'
} else {
  $pathsep = [System.IO.Path]::DirectorySeparatorChar
}

# $pathsep = if ($IsWindows) { '\' } else { '/' }
$destination = "$env:APPDATA${pathsep}Microsoft${pathsep}Windows${pathsep}Start Menu"


if (-not (Test-Path -LiteralPath $destination -ErrorAction SilentlyContinue -PathType Container)) {
  Write-Error 'Could not finde "Start Menu" directory in system'
  exit 1
}

$link = [System.IO.Path]::GetFileNameWithoutExtension("$fullpath") + '.lnk'
$shortcutPath = "$destination${pathsep}$link"

# Create shortcut
$shell = New-Object -ComObject WScript.Shell
$Shortcut = $shell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = $fullpath
if ($LinkArgs.Length -gt 0) {
  $Shortcut.Arguments = "$LinkArgs"
}
$Shortcut.Save()

Write-Output "Success"
