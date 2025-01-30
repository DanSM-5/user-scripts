#!/usr/bin/env pwsh

<#
.SYNOPSIS
  Git file history

.DESCRIPTION
  Search the commit history of a file using fzf

.PARAMETER All
  Include all refs for git `--all` flag

.PARAMETER File
  File to use for search.

.PARAMETER Edit
  Open the selected commits in your editor ($EDITOR)

.PARAMETER Help
  Show help message

.PARAMETER Display
  Open fzf using the full terminal screen

.INPUTS
  No input from pipeline

.OUTPUTS
  Same of `git show [hash]` or none if `-Edit` was passed as output is consumed by temporary file.

.EXAMPLE
  git-file-history

.EXAMPLE
  git-file-history -a

.EXAMPLE
  git-file-history -d

.EXAMPLE
  git-file-history -e 

.EXAMPLE
  git-file-history -e -a ./path/to/file

.EXAMPLE
  git-file-history -Help

.EXAMPLE
  git-file-history -f ./path/to/file

.EXAMPLE
  git-file-history ./path/to/file

.NOTES
  Script respects the EDITOR environment variable. If not present if defaults to vim.
  If the -Help flag is present, it will be prioritized over the other arguments and script with exit.
  You can pass the path to a file without the `-File` flag.

#>

[CmdletBinding()]
Param(
  # Show all refs like tags, branches, etc.
  [Switch] $All = $false,
  # Edit
  [Switch] $Edit = $false,
  # Show help
  [Switch] $Help = $false,
  # Show fzf in full screen
  [Switch] $Display = $false,
  # Query to search
  [Parameter(ValueFromRemainingArguments = $true, position = 0 )]
  [String[]] $File = @()
)

function showHelp {
  Write-Host "
    Show the commit history on a file

    Synopsis:
      > git-file-history [flags] [file to search]

    Description:
      Show the commit history of a file and preview the patches of that file.

    Note:
      You can pass the path to the file or set it with the -File flag.
      Only last one in the command will be used.

    Usage:
      Call \`git-file-history\` to view the history of commits on a specific file.
      Use ctrl-y to copy hashes to clipboard (require dependencies on linux).
      Use ctrl-a to display the full patch and ctrl-d to display the patch on the specific file (default).

    Dependencies:
      - git
      - fzf
      - delta (optional)

    Dependencies:
      - git
      - fzf
      - delta (optional)

      Windows only. For changing preview to full patch.
      - echo.exe (from gitbash, gow, etc.)

    Flags:

      -Help [switch]               > Print this message.

      -All [switch]                > Include all references in the search (tags, branches, etc.)

      -Edit [switch]               > Open the selected commits in your editor (`$EDITOR).

      -File [filename]             > File to use for search.

      -Display [switch]            > Show fzf in full screen

    Arguments:

      Path to the file to check commit history.
  "
}

if ($Help) {
  showHelp
  exit
}

$pwsh = if (Get-Command -Name 'pwsh' -All -ErrorAction SilentlyContinue) { 'pwsh' } else { 'powershell' }
$echo = if ($IsWindows -or ($env:OS -eq 'Windows_NT')) { 'echo.exe' } else { 'echo' }
$copy = '
  Get-Content {+f} | ForEach-Object { ($_ -Split "\s+")[0] } | Set-Clipboard
'
$fzf_args = [System.Collections.Generic.List[string]]::new()

if ($Display) {
  $fzf_args.Add('--height')
  $fzf_args.Add('100%')
  $fzf_args.Add('--bind')
  $fzf_args.Add('ctrl-/:change-preview-window(right|hidden|)')
  $fzf_args.Add('--preview-window')
  $fzf_args.Add('+{2}-/2,top,60%')
} else {
  $fzf_args.Add('--height')
  $fzf_args.Add('80%')
  $fzf_args.Add('--bind')
  $fzf_args.Add('ctrl-/:change-preview-window(down|hidden|)')
  $fzf_args.Add('--preview-window')
  $fzf_args.Add('+{2}-/2,right,60%')
}

# Special environment variables to customize internal commands
$GFH_FZF_ARGS = if ($env:GFH_FZF_ARGS) { $env:GFH_FZF_ARGS } else { '' }
$GFH_GIT_ARGS = if ($env:GFH_GIT_ARGS) { $env:GFH_GIT_ARGS } else { '' }
$GFH_FD_ARGS = if ($env:GFH_FD_ARGS) { $env:GFH_FD_ARGS } else { '' }
$GFH_RG_ARGS = if ($env:GFH_RG_ARGS) { $env:GFH_RG_ARGS } else { '' }
$GFH_BAT_ARGS = if ($env:GFH_BAT_ARGS) { $env:GFH_BAT_ARGS } else { '' }

foreach ($farg in ($GFH_FZF_ARGS -Split ' ')) {
  if ($farg.Trim()) {
    $fzf_args.Add($farg.Trim())
  }
}

if ($File.Count -eq 0) {
  # Preview window command
  $file_preview = "
    `$FILE = {1}
    `$LINE = {2}
    `$NUMBER = if (-Not (`$LINE.Trim())) { '0' } else { `$LINE }

    # set preview command
    if (Get-Command -All -Name 'bat' -ErrorAction SilentlyContinue) {
      bat --style='numbers' --color=always --pager=never --highlight-line=`$NUMBER $GFH_BAT_ARGS -- `$FILE
    } else {
      Get-Content $GFH_BAT_ARGS `$FILE
    }
  "

  # Set grep command
  if (Get-Command -Name 'rg' -All) {
    $grep_command = "rg --with-filename --line-number --color=always $GFH_RG_ARGS {q}"
  } else {
    $grep_command = "grep --with-filename --line-number --color=always --dereference-recursive $GFH_RG_ARGS {q}"
  }

  # Set reload command
  if (Get-Command -Name 'fd' -All) {
    $reload_files = "fd --type file --color=always $GFH_FD_ARGS"
  } else {
    $reload_files = "Get-ChildItem -Recurse $GFH_FD_ARGS | % { Resolve-Path -Relative $_.FullName }"
  }

  $filename = $reload_files | Invoke-Expression |
    fzf `
      --ansi --cycle `
      --border `
      --delimiter : `
      --header 'Select a file to search' `
      --input-border `
      --layout=reverse `
      --min-height 20 `
      --no-multi `
      --preview "$file_preview" `
      --with-shell "$pwsh -NoLogo -NonInteractive -NoProfile -Command" `
      --bind "alt-r:reload($reload_files)" `
      --bind 'ctrl-f:unbind(change,ctrl-f)+change-prompt(Select file> )+enable-search+clear-query+rebind(ctrl-r,alt-r)' `
      --bind "ctrl-r:unbind(ctrl-r,alt-r)+change-prompt(Search> )+disable-search+reload($grep_command)+rebind(change,ctrl-f)" `
      --bind "change:reload:$grep_command" `
      --bind 'start:unbind(change)' `
      --bind 'ctrl-^:toggle-preview' `
      --bind 'alt-up:preview-page-up,alt-down:preview-page-down' `
      --bind 'shift-up:preview-up,shift-down:preview-down' `
      --bind 'alt-f:first' `
      --bind 'alt-l:last' `
      --bind 'alt-c:clear-query' `
      --prompt 'Select file> ' `
      @fzf_args |
    ForEach-Object { ($_ -Split ':')[0] }
} else {
  # Last one passed
  $filename = $File[-1]
}

if (-Not $filename) {
  Write-Error "You need to provide a file or select one"
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
$history_file = "$history_location/git-file-history" -Replace '\\', '/'

# Ensure history location exists
New-Item -Path $history_location -ItemType Directory -ErrorAction SilentlyContinue


$git_args = [System.Collections.Generic.List[string]]::new()

if ($All) {
  $git_args.Add('--all')
}

$git_command = "git log --color=always --oneline --follow $git_args $GFH_GIT_ARGS -- {0} || true"
$source_command = $git_command -f $filename

$preview = 'git show --color=always {0}'
if (Get-Command -Name 'delta' -All) {
  $preview_cmd = $preview -f "--follow {1} -- '$filename' | delta"
  $preview_all = $preview -f '{1} | delta '
} else {
  $preview_cmd = $preview -f "--follow {1} -- '$filename'"
  $preview_all = $preview -f '{1}'
}

# Call fzf
$commits = [System.Collections.Generic.List[string]]::new()

$source_command | Invoke-Expression | fzf `
  --history="$history_file" `
  --min-height 20 --border `
  --input-border `
  --bind 'ctrl-^:toggle-preview' `
  --bind 'alt-up:preview-page-up,alt-down:preview-page-down' `
  --bind 'shift-up:preview-up,shift-down:preview-down' `
  --bind 'ctrl-s:toggle-sort' `
  --bind 'alt-a:select-all' `
  --bind 'alt-d:deselect-all' `
  --bind 'alt-f:first' `
  --bind 'alt-l:last' `
  --bind 'alt-c:clear-query' `
  --prompt 'File History> ' `
  --header "ctrl-a: Show full patch | ctrl-f: Show file patch | ctrl-y: Copy hashes" `
  --multi --ansi `
  --layout=reverse `
  --with-shell "$pwsh -NoLogo -NonInteractive -NoProfile -Command" `
  --bind "ctrl-y:execute-silent:$copy" `
  --bind "ctrl-a:transform:$echo 'preview:$preview_all'" `
  --bind "ctrl-f:transform:$echo 'preview:$preview_cmd'" `
  --preview "$preview_cmd" `
  @fzf_args | ForEach-Object {
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

