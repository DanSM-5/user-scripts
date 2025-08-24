#!/usr/bin/env pwsh

<#
.SYNOPSIS
  Add [Target] to the Startup directory

.DESCRIPTION
  Add the [Target] to the "Startup" directory to allow auto start the script
  on device boot.

.PARAMETER Target
  File or directory to add to "Start Menu" directory.

.PARAMETER AsShortcut
  Create the link as a shortcut file (".lnk") instead of a symlink.

.PARAMETER LinkArgs
  List of arguments to add to the shortcut ".lnk" file if "AsShortcut" is true.

.INPUTS
  String to be used as the "Target" argument.

.OUTPUTS
  Message if link was created.

.EXAMPLE
  make-start './path/to/file.exe'

.EXAMPLE
  make-start './path/to/directory'

.EXAMPLE
  make-start -Target './path/to/directory' -AsShortcut

.EXAMPLE
  make-start -Target './path/to/chrome.exe' -AsShortcut -LinkArgs '--disable-web-security', '--disable-site-isolation-trials'

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
  [Switch] $AsShortcut = $false,
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

$destination = "$env:APPDATA${pathsep}Microsoft${pathsep}Windows${pathsep}Start Menu${pathsep}Programs${pathsep}Startup"


if (-not (Test-Path -LiteralPath $destination -ErrorAction SilentlyContinue -PathType Container)) {
  Write-Error 'Could not finde "Startup" directory in system'
  exit 1
}

if ($AsShortcut) {
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
} else {
  $symlinkPath = [System.IO.Path]::GetFileName($fullpath)
  $symlinkPath = "$destination${pathsep}$symlinkPath"
  New-Item -ItemType SymbolicLink -Target $fullpath -Path $symlinkPath
}

Write-Output "Success"
