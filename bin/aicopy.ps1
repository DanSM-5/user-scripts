#!/usr/bin/env pwsh

<#
.SYNOPSIS
  Copy helper for multiple file contents or paths

.DESCRIPTION
  Copy helper script that can copy the content of multiple selected files at once or their paths as relative or absolute to CWD

.PARAMETER Exclude
  List of exclude items. See `--exclude` flag of fd command

.PARAMETER Ignore
  List ignored files. See `--no-ignore` flag of fd command

.PARAMETER All
  List hidden files. See `--hidden` flag of fd command

.PARAMETER Help
  Show help message

.INPUTS
  No input from pipeline

.OUTPUTS
  No output for pipeline

.EXAMPLE
  aicopy

.EXAMPLE
  aicopy -All

.EXAMPLE
  aicopy -Ignore

.EXAMPLE
  aicopy -Exclude @('*.py', '*.js')

.EXAMPLE
  aicopy -A -I

.EXAMPLE
  aicopy -I search query

.EXAMPLE
  aicopy -H

.NOTES
  This script requires fzf 0.63.0 and fd (any version)
#>

[CmdletBinding()]
Param(
  # List of patterns to exclude
  [string[]] $Exclude = @(),
  # No ignore flag
  [Switch] $Ignore = $false,
  # No hidden flag
  [Switch] $All = $false,
  # Show help
  [Switch] $Help = $false,
  # Query to search
  [Parameter(ValueFromRemainingArguments = $true, position = 0 )]
  [String] $Query = ''
)

function showHelp {
  Write-Host "
    Copy helper for multiple file contents or paths

    Synopsis:
      > aicopy [flags]

    Description:
      Copy helper script that can copy the content of multiple selected files at once or their paths as relative or absolute to CWD

    Usage:
      Call the aicopy command. Select the files that you want to copy.
      Use ctrl-e to copy the content.
      Use ctrl-r to copy relative paths.
      Use ctrl-t to copy absolute paths.
      Use ctrl-d to show selected files contents.
      Use ctrl-f to show selected files relative paths.
      Use ctrl-g to show selected files absolute paths.

    Dependencies:
      - fzf (0.63.0)
      - fd

    Flags:

      -Help [switch]               > Print this message.

      -Exclude [string[]]          > List of exclude items.
                                     See `--exclude` flag of fd command

      -Ignore [switch]             > List ignored files.
                                     See `--no-ignore` flag of fd command

      -All [switch]                > List hidden files.
                                     See `--hidden` flag of fd command

    Arguments:

      Remaining arguments are treated as the initial query for search.
  "
}
if ($Help) {
  showHelp
  exit
}

$exclude_args = [System.Collections.Generic.List[string]]::new()
$fd_args = [System.Collections.Generic.List[string]]::new()
$pwsh = if (Get-Command -Name 'pwsh' -All -ErrorAction SilentlyContinue) { 'pwsh' } else { 'powershell' }

foreach ($item in $Exclude) {
  $exclude_args.Add("--exclude '$item'")
}

if ($Ignore) { $fd_args.Add('-I') }
if ($All) { $fd_args.Add('-H') }

$help_cat_cmd = ''
if (Get-Command -Name 'bat' -ErrorAction SilentlyContinue) {
  $help_cat_cmd = '| bat --color=always --language help --style=plain'
}

$help_cmd = @"
Write-Output '
  Preview window keys:
    ctrl-^: Toggle preview
    ctrl-/: Toggle preview position
    ctrl-s: Toggle sort
    shift-up: Preview up
    shift-down: Preview down
    alt-up: Preview page up
    alt-down: Preview page down

  Preview keys:
    ctrl-d: Preview all the text
    ctrl-f: Preview paths of selected files as relative to cwd
    ctrl-g: Preview paths of selected files as absolute paths

  Utility keys:
    ctrl-e: Copy text of selected files
    ctrl-r: Copy paths of selected files as relative to cwd
    ctrl-t: Copy paths of selected files as absolute paths

  Cursor keys:
    alt-a: Select all
    alt-d: Deselect all
    alt-f: Go first
    alt-l: Go last
    alt-c: Clear query
' $help_cat_cmd
"@

$placeholder = '{+f}'
if ($IsWindows -or ($env:OS -eq 'Windows_NT')) {
  $placeholder = '"{+f}"'
}

# preview commands
$preview_content = "
  `$files = [String[]](Get-Content -LiteralPath $placeholder)
  Get-Content -LiteralPath `$files
"
$preview_relative = "
  Get-Content -LiteralPath $placeholder | % {
    Resolve-Path -LiteralPath `$_ -Relative
  }
"
$preview_absolute = "
  Get-Content -LiteralPath $placeholder | % {
    (Resolve-Path -LiteralPath `$_).Path
  }
"

# copy commands
$copy_content = "
  `$files = [String[]](Get-Content -LiteralPath $placeholder)
  Get-Content -LiteralPath `$files | Set-Clipboard
"
$copy_relative = "
  Get-Content -LiteralPath $placeholder | % {
    Resolve-Path -LiteralPath `$_ -Relative
  } |
  Set-Clipboard
"
$copy_absolute = "
  Get-Content -LiteralPath $placeholder | % {
    (Resolve-Path -LiteralPath `$_).Path
  } |
  Set-Clipboard
"

fd --type file @fd_args @exclude_args |
  fzf --preview "$preview_content" `
    --ghost 'Type in your query' `
    --preview-label ' Files Content ' `
    --bind "ctrl-d:bg-transform-preview-label(Write-Output ' Files Content ')+change-preview:$preview_content" `
    --bind "ctrl-f:bg-transform-preview-label(Write-Output ' Relative Paths ')+change-preview:$preview_relative" `
    --bind "ctrl-g:bg-transform-preview-label(Write-Output ' Absolute Paths ')+change-preview:$preview_absolute" `
    --bind "ctrl-e:execute-silent($copy_content)+bell" `
    --bind "ctrl-r:execute-silent($copy_relative)+bell" `
    --bind "ctrl-t:execute-silent($copy_absolute)+bell" `
    --bind "alt-h:preview:$help_cmd" `
    --input-border `
    --header-border `
    --footer-border `
    --list-border `
    --header 'Select files to copy | alt-h for help' `
    --footer 'Change Preview: ctrl-d | ctrl-f | ctrl-g' `
    --bind 'result:bg-transform-list-label:
      if ($env:FZF_QUERY.Length -eq 0) {
        Write-Output " $env:FZF_MATCH_COUNT items "
      } else {
        Write-Output " $env:FZF_MATCH_COUNT matches for [$env:FZF_QUERY] "
      }
    ' `
    --bind 'alt-a:select-all' `
    --bind 'alt-c:clear-query' `
    --bind 'alt-d:deselect-all' `
    --bind 'alt-f:first' `
    --bind 'alt-l:last' `
    --bind 'alt-up:preview-page-up,alt-down:preview-page-down' `
    --bind 'ctrl-^:toggle-preview' `
    --bind 'ctrl-s:toggle-sort' `
    --bind 'shift-up:preview-up,shift-down:preview-down' `
    --bind 'ctrl-/:change-preview-window(down|hidden|)' `
    --preview-window 'right,50%,wrap' `
    --query $Query `
    --multi --ansi --cycle `
    --with-shell "$pwsh -NoLogo -NonInteractive -NoProfile -Command"
