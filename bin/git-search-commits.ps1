#!/usr/bin/env pwsh

<#
.SYNOPSIS
  Git search script

.DESCRIPTION
  Search a string in the logs or search string by exact match or regex in the patches.
  Use fzf to select the commit hashes and open them with `git show`. If delta is installed,
  it will be used as the pager.

.PARAMETER Log
  Search a string in the log of the commits

.PARAMETER Regex
  Search a string using regex in the patches of the commits

.PARAMETER String
  Search a string by direct match in the patches of the commits

.PARAMETER Mode
  Set the search mode by providing a string

.PARAMETER Edit
  Open the selected commits in your editor ($EDITOR)

.PARAMETER File
  Single file, coma separated list of files or array of files that will be used to narrow the search.

.PARAMETER Print
  Print the selected hashes on exit

.PARAMETER Display
  Open fzf using the full terminal screen

.PARAMETER Query
  Extra arguments or using the `-Query` parameter will be used to build the initial query for search.

.PARAMETER Help
  Show help message

.INPUTS
  No input from pipeline

.OUTPUTS
  Same of `git show [hash]` or none if `-Edit` was passed as output is consumed by temporary file.

.EXAMPLE
  git-search-commits 'search'

.EXAMPLE
  git-search-commits -r 'search'

.EXAMPLE
  git-search-commits -s 'search'

.EXAMPLE
  git-search-commits -m 'log' 'search'

.EXAMPLE
  git-search-commits -q 'search'

.EXAMPLE
  git-file-history -p

.EXAMPLE
  git-search-commits -f ./path/to/file1, ./path/to/file2  -q 'search'

.NOTES
  Script respects the EDITOR environment variable. If not present if defaults to vim.
  If the -Help flag is present, it will be prioritized over the other arguments and script with exit.

#>

[CmdletBinding()]
Param(
  # Mode log
  [Switch] $Log = $false,
  # Mode regex
  [Switch] $Regex = $false,
  # Mode string
  [Switch] $String = $false,
  # Manual mode
  [ValidateSet('log', 'regex', 'string')]
  [String] $Mode = '',
  # Edit
  [Switch] $Edit = $false,
  # Show help
  [Switch] $Help = $false,
  # Show fzf in full screen
  [Switch] $Display = $false,
  # Print the selected hashes on exit
  [Switch] $Print = $false,
  # Files to narrow search to
  [String[]] $File = @(),
  # Query to search
  [Parameter(ValueFromRemainingArguments = $true, position = 0 )]
  [String] $Query = ''
)

function showHelp {
  Write-Host "
    Git search in commits or patches

    Synopsis:
      > git-search-commits [flags] [search string]

    Description:
      Select a mode for search and interactively search in the logs or the patches
      of the commits. Fzf have two modes, git search (initial) and fuzzy filter to
      narrow on the remaining items available.

    Usage:
      Call ``git-search-commits`` to start interactive search on fzf. Initial query
      can be provided to start with a small result set.
      Target the files you are interested in to narrow the search (see '-File').
      Use ctrl-r to search with git interactively (default mode).
      Use ctrl-f to filter result with fuzzy matches.
      Use ctrl-y to copy hashes to clipboard (require dependencies on linux).

    Modes:
      - log:       Searches through the messages of the commits (--message/-m).
      - regex:     Search through the patches of the commits using regex.
      - string:    Search through the patches of the commits using exact match.

    Dependencies:
      - git
      - fzf
      - delta (optional)

    Flags:

      -Help [switch]               > Print this message.

      -Log [switch]                > Search in the log of the commits.

      -String [switch]             > Search in the patches of commits by exact match.

      -Regex [switch]              > Search in the patches of commits by regex.

      -Mode [string]               > Set the mode with a string instead of a boolean flag.

      -Edit [switch]               > Open the selected commits in your editor (`$EDITOR).

      -Query [string]              > String to search. The flag `-Query` can be omited.

      -Display [switch]            > Show fzf in full screen

      -File [string[]]             > File or files to use to narrow the search.

      -Print [switch]              > Print the hashes on exit

    Arguments:

      Remaining arguments are treated as the initial query for search.
  "
}

if ($Help) {
  showHelp
  exit
}

$editor = if ($env:PREFERRED_EDITOR) {
  $env:PREFERRED_EDITOR
} elseif ($env:EDITOR) {
  $env:EDITOR
} else {
  'vim'
}

$history_location = if ($env:FZF_HIST_DIR) {
  $env:FZF_HIST_DIR
} else {
  "$HOME/.cache/fzf-history"
}

# For fzf --history we need to use forward slashes even on windows
$history_file = "$history_location/git-search-commits" -Replace '\\', '/'

$cmd_mode = $Mode

# Set mode
if (!$cmd_mode) {
  if ($Log) {
    $cmd_mode = 'log'
  } elseif ($Regex) {
    $cmd_mode = 'regex'
  } elseif ($String) {
    $cmd_mode = 'string'
  } else {
    $cmd_mode = 'log'
  }
}

# Command formatting
$base_command = ''
$files = ''
$format_files = '{0}'

$trueCmd = if ($IsWindows) { 'cd .' } else { 'true' }

if ($File.Length -gt 0) {
  # Process files and ensure they are quoted
  $files = ($File | ForEach-Object { "'$_'" }) -Join ' '
  $format_files = "{0} -- $files"
}

# Git command to perform
switch ($cmd_mode) {
  'regex' {
    $base_command = 'git log --color=always --oneline --branches --all -G {0} 2> $null' -f $format_files
  }
  'string' {
    $base_command = 'git log --color=always --oneline --branches --all -S {0} 2> $null' -f $format_files
  }
  Default {
    $base_command = 'git log --color=always --oneline --branches --all --grep {0} 2> $null' -f $format_files
  }
}

$source_command = $base_command -f "'$Query'"
$reload_command = "$($base_command -f "{q}") || $trueCmd"

# Setup preview
$fzf_preview = 'git show --color=always {1} '
if (Get-Command -Name delta -All -ErrorAction SilentlyContinue) {
  $fzf_preview="$fzf_preview | delta || $trueCmd"
} else {
  $fzf_preview="$fzf_preview || $trueCmd"
}

# Ensure history location exists
New-Item -Path $history_location -ItemType Directory -ErrorAction SilentlyContinue

$fzf_args = [System.Collections.Generic.List[string]]::new()

if ($Display) {
  $fzf_args.Add('--bind')
  $fzf_args.Add('ctrl-/:change-preview-window(right|hidden|)')
  $fzf_args.Add('--preview-window')
  $fzf_args.Add('top,60%')

  # Bug in fzf making fullscreen
  # not recognizing ctrl-/ or ctrl-^
  if ($IsWindows -or ($env:OS -eq 'Windows_NT')) {
    # Bug in fzf making fullscreen
    # not recognizing ctrl-/ or ctrl-^
    $fzf_args.Add('--height')
    $fzf_args.Add('99%')
  } else {
    $fzf_args.Add('--height')
    $fzf_args.Add('100%')
  }
} else {
  $fzf_args.Add('--height')
  $fzf_args.Add('80%')
  $fzf_args.Add('--bind')
  $fzf_args.Add('ctrl-/:change-preview-window(down|hidden|)')
  $fzf_args.Add('--preview-window')
  $fzf_args.Add('right,60%')
}

$pwsh = if (Get-Command -Name 'pwsh' -All -ErrorAction SilentlyContinue) { 'pwsh' } else { 'powershell' }
$copy = '
  Get-Content {+f} | ForEach-Object { ($_ -Split "\s+")[0] } | Set-Clipboard
'

# It may be useful but prefer the initil pipe for now
# --bind "start:reload:$source_command"

# Call fzf
$commits = [System.Collections.Generic.List[string]]::new()

$source_command | Invoke-Expression | fzf `
    --ansi --cycle --multi `
    --bind 'alt-a:select-all' `
    --bind 'alt-c:clear-query' `
    --bind 'alt-d:deselect-all' `
    --bind 'alt-f:first' `
    --bind 'alt-l:last' `
    --bind 'alt-up:preview-page-up,alt-down:preview-page-down' `
    --bind 'ctrl-^:toggle-preview' `
    --bind 'ctrl-s:toggle-sort' `
    --bind 'shift-up:preview-up,shift-down:preview-down' `
    --bind "change:reload:$reload_command" `
    --bind "ctrl-f:unbind(change,ctrl-f)+change-prompt(FzfFilter> )+enable-search+clear-query+rebind(ctrl-r)" `
    --bind "ctrl-r:unbind(ctrl-r)+change-prompt(GitSearch> )+disable-search+reload($reload_command)+rebind(change,ctrl-f)" `
    --bind "ctrl-y:execute-silent($copy)+bell" `
    --disabled `
    --expect="ctrl-o,ctrl-e" `
    --header "Mode: $cmd_mode | ctrl-r: Interactive search | ctrl-f: Filtering results | ctrl-y: Copy hashes" `
    --history="$history_file" `
    --input-border `
    --layout=reverse `
    --min-height 20 --border `
    --preview "$fzf_preview" `
    --prompt 'GitSearch> ' `
    --query "$Query" `
    --with-shell "$pwsh -NoLogo -NonInteractive -NoProfile -Command" `
    @fzf_args |
  ForEach-Object {
    $line = $_ -split "\s+"
    $commits.Add($line[0])
  }

# If no commits, exit
if ($commits.Count -lt 2) {
  exit
}

$expected_key = $commits[0]
$hashes = $commits.GetRange(1, $commits.Count - 1)

function print_patches () {
  git show @hashes
}

function open_editor () {
  $tmpfile = New-TemporaryFile
  git show @hashes > $tmpfile.FullName

  # On (n)vim editor set filetype
  if ($editor -Match '^n?vim?$') {
    & "$editor" -c ":filetype detect" $tmpfile.FullName
  } else {
    & "$editor" $tmpfile.FullName
  }
}

if ($expected_key -eq 'ctrl-o') {
  print_patches
  exit
}

if ($expected_key -eq 'ctrl-e') {
  open_editor
  exit
}

if ($Print) {
  print_patches
  exit
}

if ($Edit) {
  open_editor
  exit
}

# Print selected hashes
Write-Output @hashes

