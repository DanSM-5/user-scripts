#!/usr/bin/env pwsh

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

$editor = if ($env:PREFERRED_EDITOR) {
  $env:PREFERRED_EDITOR
} elseif ($env:EDITOR) {
  $env:EDITOR
} else {
  'vim'
}

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

# Git command to perform
switch ($cmd_mode) {
  'regex' {
    $base_command = 'git log --color=always --oneline --branches --all -G {0}'
  }
  'string' {
    $base_command = 'git log --color=always --oneline --branches --all -S {0}'
  }
  Default {
    $base_command = 'git log --color=always --oneline --grep {0}'
  }
}

$source_command = $base_command -f "'$Query'"
$reload_command = $base_command -f '{q} || true'

# Setup preview
$fzf_preview = 'git show --color=always {1} '
if (Get-Command -Name delta -All -ErrorAction SilentlyContinue) {
  $trueCmd = if ($IsWindows) { 'cd .' } else { 'true' }
  $fzf_preview="$fzf_preview | delta || $trueCmd"
} else {
  $fzf_preview="$fzf_preview || $trueCmd"
}

# It may be useful but prefer the initil pipe for now
# --bind "start:reload:$source_command"

# Call fzf
$commits = [System.Collections.Generic.List[string]]::new()

$source_command | Invoke-Expression |
  fzf `
  --height 80% --min-height 20 --border `
  --info=inline `
  --bind 'ctrl-/:change-preview-window(down|hidden|)' `
  --bind 'alt-up:preview-page-up,alt-down:preview-page-down' `
  --bind 'ctrl-s:toggle-sort' `
  --bind 'alt-f:first' `
  --bind 'alt-l:last' `
  --bind 'alt-c:clear-query' `
  --prompt 'GitSearch> ' `
  --header 'ctrl-r: interactive search | ctrl-f: Fzf filtering of results' `
  --multi --ansi `
  --layout=reverse `
  --disabled `
  --query "$Query" `
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
& "$editor" -c ":filetype detect" "$tmpfile"

