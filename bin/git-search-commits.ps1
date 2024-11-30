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
  # Query to search
  [Parameter(ValueFromRemainingArguments = $true, position = 0 )]
  [String] $Query = ''
)

function showHelp {
  Write-Host "
    Git search in commits or patches

    Description:
      Select a mode for search and interactively search in the logs or the patches
      of the commits. Fzf have two modes, git search (initial) and fuzzy filter to
      narrow on the remaining items available.

    Usage:
      Call \`git-search-commits\` to start interactive search on fzf.
      Use ctrl-r to search with git interactively (default mode).
      Use ctrl-f to filter result with fuzzy matches.
      Use ctrl-y to copy hashes to clipboard (require dependencies on linux).

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

$base_command = ''

$trueCmd = if ($IsWindows) { 'cd .' } else { 'true' }

# Git command to perform
switch ($cmd_mode) {
  'regex' {
    $base_command = 'git log --color=always --oneline --branches --all -G {0} 2> $null'
  }
  'string' {
    $base_command = 'git log --color=always --oneline --branches --all -S {0} 2> $null'
  }
  Default {
    $base_command = 'git log --color=always --oneline --branches --all --grep {0} 2> $null'
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

$pwsh = if (Get-Command -Name 'pwsh' -All -ErrorAction SilentlyContinue) { 'pwsh' } else { 'powershell' }
$copy = '
  Get-Content {+f} | ForEach-Object { ($_ -Split "\s+")[0] } | Set-Clipboard
'

# It may be useful but prefer the initil pipe for now
# --bind "start:reload:$source_command"

# Call fzf
$commits = [System.Collections.Generic.List[string]]::new()

$source_command | Invoke-Expression |
  fzf `
  --history="$history_file" `
  --height 80% --min-height 20 --border `
  --info=inline `
  --bind 'ctrl-/:change-preview-window(down|hidden|)' `
  --bind 'ctrl-^:toggle-preview' `
  --bind 'alt-up:preview-page-up,alt-down:preview-page-down' `
  --bind 'shift-up:preview-up,shift-down:preview-down' `
  --bind 'ctrl-s:toggle-sort' `
  --bind 'alt-a:select-all' `
  --bind 'alt-d:deselect-all' `
  --bind 'alt-f:first' `
  --bind 'alt-l:last' `
  --bind 'alt-c:clear-query' `
  --prompt 'GitSearch> ' `
  --header "Mode: $cmd_mode | ctrl-r: Interactive search | ctrl-f: Filtering results | ctrl-y: Copy hashes" `
  --multi --ansi `
  --layout=reverse `
  --disabled `
  --query "$Query" `
  --with-shell "$pwsh -NoLogo -NonInteractive -NoProfile -Command" `
  --bind "ctrl-y:execute-silent:$copy" `
  --bind "ctrl-r:unbind(ctrl-r)+change-prompt(GitSearch> )+disable-search+reload($reload_command)+rebind(change,ctrl-f)" `
  --bind "ctrl-f:unbind(change,ctrl-f)+change-prompt(FzfFilter> )+enable-search+clear-query+rebind(ctrl-r)" `
  --bind "change:reload:$reload_command" `
  --preview "$fzf_preview" | ForEach-Object {
    $line = $_ -split "\s+"
    if ($line[0]) {
      $commits.Add($line[0])
    }
  }

# If no commits, exit
if ($commits.Count -eq 0) {
  exit
}

# Show selected commits
if (!$Edit) {
  git show @commits
  exit
}

# Open in editor
$tmpfile = New-TemporaryFile
git show @commits > $tmpfile.FullName

# On (n)vim editor set filetype
if ($editor -Match '^n?vim?$') {
  & "$editor" -c ":filetype detect" "$tmpfile"
} else {
  & "$editor" "$tmpfile"
}

