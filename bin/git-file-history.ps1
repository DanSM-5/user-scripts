#!/usr/bin/env pwsh

<#
.SYNOPSIS
  Git file history

.DESCRIPTION
  Search the commit history of a file using fzf

.PARAMETER GitArgs
  Add arguments to git to customize output like '--all' to include all references

.PARAMETER File
  File to use for search.

.PARAMETER Edit
  Open the selected commits in your editor ($EDITOR)

.PARAMETER Help
  Show help message

.PARAMETER Display
  Open fzf using the full terminal screen

.PARAMETER Print
  Print the selected hashes on exit

.INPUTS
  No input from pipeline

.OUTPUTS
  Same of `git show [hash]` or none if `-Edit` was passed as output is consumed by temporary file.

.EXAMPLE
  git-file-history

.EXAMPLE
  git-file-history -g '--all'

.EXAMPLE
  git-file-history -d

.EXAMPLE
  git-file-history -e

.EXAMPLE
  git-file-history -p

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
  # Send arguments to git to customize output
  [string[]] $GitArgs = @(),
  # Edit
  [Switch] $Edit = $false,
  # Show help
  [Switch] $Help = $false,
  # Show fzf in full screen
  [Switch] $Display = $false,
  # Print the selected hashes on exit
  [Switch] $Print = $false,
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

      -GitArgs [string[]]          > Git arguments. E.g. '--branches --tags'

      -Edit [switch]               > Open the selected commits in your editor (`$EDITOR).

      -File [filename]             > File to use for search.

      -Display [switch]            > Show fzf in full screen

      -Print [switch]              > Print the hashes on exit

    Arguments:

      Path to the file to check commit history.
  "
}

if ($Help) {
  showHelp
  exit
}

$pwsh = if (Get-Command -Name 'pwsh' -All -ErrorAction SilentlyContinue) { 'pwsh' } else { 'powershell' }
$copy = '
  Get-Content {+f} | ForEach-Object { ($_ -Split "\s+")[0] } | Set-Clipboard
'
$fzf_args = [System.Collections.Generic.List[string]]::new()

if ($Display) {
  $fzf_args.Add('--bind')
  $fzf_args.Add('ctrl-/:change-preview-window(right|hidden|)')
  $fzf_args.Add('--preview-window')
  $fzf_args.Add('+{2}-/2,top,60%,wrap')

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
  $fzf_args.Add('+{2}-/2,right,60%,wrap')
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

if ($File.Count -eq 0 -or !(Test-Path -PathType Leaf -LiteralPath $File[-1])) {
  if ($File.Count -ne 0) {
    Write-Warning "File `"$($File[-1])`" is invalid. Starting selection"
  }

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

  # Preview commits that changed the file
  $commits_preview="
    `$FILE = {1}
    git log --color=always --oneline --decorate --follow -- `$FILE || true
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

  $help_cat_cmd = ''
  if (Get-Command -Name 'bat' -All -ErrorAction SilentlyContinue) {
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
    ctrl-d: Preview file content (default)
    ctrl-g: Preview commits that changed the file

  Utility keys:
    alt-r: Reload fuzzy filter
    ctrl-r: Change search base on grep
    ctrl-f: Fuzzy filter on grep search

  Cursor keys:
    alt-a: Select all
    alt-d: Deselect all
    alt-f: Go first
    alt-l: Go last
    alt-c: Clear query
' $help_cat_cmd
"@

  $filename = $reload_files | Invoke-Expression |
    fzf `
      --accept-nth '{1}' `
      --ansi --cycle --no-multi `
      --bind 'alt-c:clear-query' `
      --bind 'alt-f:first' `
      --bind 'alt-l:last' `
      --bind 'alt-up:preview-page-up,alt-down:preview-page-down' `
      --bind 'ctrl-^:toggle-preview' `
      --bind 'ctrl-s:toggle-sort' `
      --bind 'ctrl-f:unbind(change,ctrl-f)+change-prompt(Select file> )+enable-search+clear-query+rebind(ctrl-r,alt-r)' `
      --bind 'shift-up:preview-up,shift-down:preview-down' `
      --bind 'start:unbind(change)' `
      --bind "alt-r:reload($reload_files)" `
      --bind "change:reload:$grep_command" `
      --bind "ctrl-r:unbind(ctrl-r,alt-r)+change-prompt(Search> )+disable-search+reload($grep_command)+rebind(change,ctrl-f)" `
      --bind "alt-h:preview:$help_cmd" `
      --bind "ctrl-d:change-preview:$file_preview" `
      --bind "ctrl-g:change-preview:$commits_preview" `
      --delimiter : `
      --header 'Help: alt-h | Select a file to search:' `
      --input-border `
      --layout=reverse `
      --min-height 20 --border `
      --preview "$file_preview" `
      --prompt 'Select file> ' `
      --with-shell "$pwsh -NoLogo -NonInteractive -NoProfile -Command" `
      @fzf_args
} else {
  # Last one passed
  $filename = $File[-1]
}

if (-Not $filename) {
  Write-Error 'You need to provide a file or select one'
  exit
}

if (!(Test-Path -LiteralPath $filename -PathType Leaf -ErrorAction SilentlyContinue)) {
  Write-Error "Cannot find the specified file: $filename"
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

$git_command = "git log --color=always --oneline --decorate --follow $GFH_GIT_ARGS $GitArgs -- {0} || true"
$source_command = $git_command -f $filename

$preview = 'git show --color=always {0}'
if (Get-Command -Name 'delta' -All -ErrorAction SilentlyContinue) {
  $preview_cmd = $preview -f "--follow {1} -- '$filename' | delta"
  $preview_all = $preview -f '{1} | delta '
} else {
  $preview_cmd = $preview -f "--follow {1} -- '$filename'"
  $preview_all = $preview -f '{1}'
}
$preview_file = $preview -f "{1}:`"$($filename.Replace('\', '/'))`""
# Preview graph up to current commit
$preview_graph = 'git log --color=always --oneline --decorate --graph {1}'
# Preview file names
$preview_file_names = 'git show --color=always --name-only {1} || true'
$help_cat_cmd = ''

if (Get-Command -Name 'bat' -All -ErrorAction SilentlyContinue) {
  $bat_style = if ($env:BAT_STYLE) { $env:BAT_STYLE } else { 'numbers,header' }
  $preview_file = $preview_file + " | bat --color=always --style=$bat_style --file-name `"$filename`""
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
    ctrl-a: Preview whole patch
    ctrl-d: Preview patch on file (default)
    ctrl-f: Preview file at hash
    ctrl-g: Preview graph at hash
    alt-g: Preview names of changed files in commit

  Utility keys:
    ctrl-y: Copy selected hash(es)
    ctrl-o: Exit and print selected hash(es) with \`git show\`
    ctrl-e: Exit and open selected hash(es) in editor
    alt-x: Remove selected hash(es) from result
    alt-r: Reload history

  Cursor keys:
    alt-a: Select all
    alt-d: Deselect all
    alt-f: Go first
    alt-l: Go last
    alt-c: Clear query
' $help_cat_cmd
"@

# Call fzf
$commits = [System.Collections.Generic.List[string]]::new()

$source_command | Invoke-Expression | fzf `
  --accept-nth '{1}' `
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
  --bind "ctrl-a:change-preview:$preview_all" `
  --bind "ctrl-d:change-preview:$preview_cmd" `
  --bind "ctrl-f:change-preview:$preview_file" `
  --bind "ctrl-g:change-preview:$preview_graph" `
  --bind "alt-g:change-preview:$preview_file_names" `
  --bind "ctrl-y:execute-silent($copy)+bell" `
  --bind 'alt-x:exclude-multi' `
  --bind "alt-r:reload:$source_command" `
  --expect="ctrl-o,ctrl-e" `
  --bind "alt-h:preview:$help_cmd" `
  --header "ctrl-a: Full patch | ctrl-d: File patch | alt-h: Help" `
  --history="$history_file" `
  --input-border `
  --layout=reverse `
  --min-height 20 --border `
  --preview "$preview_cmd" `
  --prompt 'File History> ' `
  --with-shell "$pwsh -NoLogo -NonInteractive -NoProfile -Command" `
  @fzf_args | ForEach-Object {
    $commits.Add($_)
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

