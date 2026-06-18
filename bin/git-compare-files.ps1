#!/usr/bin/env pwsh

<#
.SYNOPSIS
  Git compare files

.DESCRIPTION
  Show the files changed between HEAD and a target branch using fzf.
  Shell counterpart of the vim 'fzfgit#compare_files' function.

.PARAMETER Help
  Show help message

.PARAMETER Fzf
  Fuzzy select the comparison branch with fzf instead of passing it as an argument.

.PARAMETER Target
  Target branch to compare against (defaults to the repository default branch).

.INPUTS
  No input from pipeline

.OUTPUTS
  The selected file path(s), or `git diff` output, depending on the key pressed.

.EXAMPLE
  git-compare-files

.EXAMPLE
  git-compare-files feat/my-branch

.EXAMPLE
  git-compare-files origin/main

.EXAMPLE
  git-compare-files -Help

.NOTES
  Script respects the EDITOR environment variable. If not present it defaults to vim.
  If the -Help flag is present, it will be prioritized over the other arguments.
  You can pass the target branch without the `-Target` flag.
#>

[CmdletBinding()]
Param(
  # Show help
  [Switch] $Help = $false,
  # Fuzzy select the comparison branch
  [Switch] $Fzf = $false,
  # Target branch to compare against
  [Parameter(ValueFromRemainingArguments = $true, Position = 0)]
  [String[]] $Target = @()
)

function showHelp {
  Write-Host "
    Compare the files changed between HEAD and a target branch

    Synopsis:
      > git-compare-files [flags] [target-branch]

    Description:
      List the files that differ between the current branch and a target
      branch (the repository's default branch when none is given), computed
      from their merge base. The preview shows each file's patch.

    Usage:
      git-compare-files                 # compare against the default branch
      git-compare-files feat/my-branch  # compare against a branch
      git-compare-files origin/main     # remote refs are fine
      git-compare-files -Fzf            # fuzzy select the branch first

    Keys:
      enter    Print the selected file path(s) (default)
      ctrl-o   Print the diff of the selected file(s)
      ctrl-e   Edit the selected file(s) in `$EDITOR
      ctrl-r   Open the selected file(s) diff in `$EDITOR
      ctrl-f   Show the file diff fullscreen through a pager (loop)
      ctrl-y   Copy the selected file path(s) to the clipboard
      alt-h    Show the help in the preview window

    Dependencies:
      - git
      - fzf
      - delta (optional)
      - less  (optional, for ctrl-f)

    Flags:
      -Help [switch]               > Print this message.
      -Fzf [switch]                > Fuzzy select the comparison branch.

    Arguments:
      Target branch to compare against.
  "
}

if ($Help) {
  showHelp
  exit
}

# Check if it's a git repo
git rev-parse HEAD *> $null
if ($LASTEXITCODE -ne 0) {
  Write-Error 'Not a git repo!'
  exit 1
}

# Run from the repository root so paths from 'git diff' resolve for editing
$toplevel = (git rev-parse --show-toplevel).Trim()
Set-Location -LiteralPath $toplevel

# Resolve the repository default branch (e.g. origin/main), falling back to
# a local main/master when origin/HEAD is not set.
function Get-DefaultBranch {
  $head = (git symbolic-ref --quiet refs/remotes/origin/HEAD 2>$null)
  if ($head) {
    return ($head -replace '^refs/remotes/', '')
  }

  foreach ($branch in @('main', 'master')) {
    git rev-parse --verify --quiet $branch *> $null
    if ($LASTEXITCODE -eq 0) {
      return $branch
    }
  }

  return 'master'
}

# Fuzzy select a branch (local or remote) to compare against
function Select-CompareBranch {
  git for-each-ref --format='%(refname:short)' refs/heads refs/remotes |
    Where-Object { $_ -notmatch '/HEAD$' } |
    fzf --reverse --height=40% --cycle --prompt 'Compare with branch> '
}

# Resolve the target. '-Fzf' fuzzy selects it; otherwise use the positional
# argument, falling back to the repo default branch. Strip a leading
# 'remotes/' so that 'origin/<branch>' refs are passed straight to git.
if ($Fzf) {
  $target = Select-CompareBranch
  if (-not $target) { exit }
} elseif ($Target.Count -gt 0) {
  $target = $Target[-1]
} else {
  $target = Get-DefaultBranch
}
$target = ($target -replace '^remotes/', '').Trim()

# Resolve the merge base once so the source and preview reuse it.
$base = (git merge-base HEAD $target).Trim()
if (-not $base) {
  Write-Error "Could not find merge base with $target"
  exit 1
}

$editor = if ($env:PREFERRED_EDITOR) {
  $env:PREFERRED_EDITOR
} elseif ($env:EDITOR) {
  $env:EDITOR
} else {
  'vim'
}

$pwsh = if (Get-Command -Name 'pwsh' -All -ErrorAction SilentlyContinue) { 'pwsh' } else { 'powershell' }

# Copy the whole path(s), one per line
$copy = 'Get-Content {+f} | Set-Clipboard'

# Preview the patch of the file under the cursor. 'ctrl-f' shows the same
# diff fullscreen through a pager, mimicking the git-stack loop.
if (Get-Command -Name 'delta' -All -ErrorAction SilentlyContinue) {
  $preview = "git diff --color=always $base -- {} | delta"
  $pager_view = "git diff --color=always $base -- {} | delta | less -R"
} else {
  $preview = "git diff --color=always $base -- {}"
  $pager_view = "git diff --color=always $base -- {} | less -R"
}

# Help shown in the preview window with alt-h
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
    ctrl-d: Preview patch of file (default)

  Utility keys:
    ctrl-f: Show file diff fullscreen (pager loop)
    ctrl-y: Copy selected file path(s)
    ctrl-o: Exit and print selected file(s) diff
    ctrl-e: Exit and edit selected file(s)
    ctrl-r: Exit and open selected file(s) diff in editor
    alt-x: Drop selected file(s) from result

  Cursor keys:
    alt-a: Select all
    alt-d: Deselect all
    alt-f: Go first
    alt-l: Go last
    alt-c: Clear query
' $help_cat_cmd
"@

# Call fzf
$selected = [System.Collections.Generic.List[string]]::new()

git diff --name-only $base | fzf `
  --ansi --cycle --multi `
  --bind 'alt-a:select-all' `
  --bind 'alt-c:clear-query' `
  --bind 'alt-d:deselect-all' `
  --bind 'alt-f:first' `
  --bind 'alt-l:last' `
  --bind 'alt-up:preview-page-up,alt-down:preview-page-down' `
  --bind 'shift-up:preview-up,shift-down:preview-down' `
  --bind 'ctrl-^:toggle-preview' `
  --bind 'ctrl-/:change-preview-window(down|hidden|)' `
  --bind 'ctrl-s:toggle-sort' `
  --bind 'alt-x:exclude-multi' `
  --bind "ctrl-d:change-preview:$preview" `
  --bind "alt-h:preview:$help_cmd" `
  --bind "ctrl-f:execute($pager_view)" `
  --bind "ctrl-y:execute-silent($copy)+bell" `
  --expect='ctrl-o,ctrl-e,ctrl-r' `
  --header 'alt-h: Help | ctrl-o: Print diff | ctrl-e: Edit | ctrl-r: Diff in editor | ctrl-f: Fullscreen | ctrl-y: Copy' `
  --footer="Compare: $target" `
  --input-border `
  --layout=reverse `
  --min-height 20 --border `
  --preview "$preview" `
  --preview-window 'right,60%,wrap-word' `
  --prompt 'Compare Files> ' `
  --with-shell "$pwsh -NoLogo -NonInteractive -NoProfile -Command" | ForEach-Object {
    $selected.Add($_)
  }

# selected[0] is the --expect key line (empty for enter); files follow.
# Nothing selected -> exit
if ($selected.Count -lt 2) {
  exit
}

$expected_key = $selected[0]
$files = $selected.GetRange(1, $selected.Count - 1)

function open_diff_editor {
  $tmpfile = New-TemporaryFile
  git diff $base -- @files > $tmpfile.FullName

  # On (n)vim editor set the git filetype
  if ($editor -Match '^n?vim?$') {
    & "$editor" -c 'setlocal filetype=git' $tmpfile.FullName
  } else {
    & "$editor" $tmpfile.FullName
  }
}

switch ($expected_key) {
  'ctrl-o' { git diff $base -- @files }
  'ctrl-e' { & "$editor" @files }
  'ctrl-r' { open_diff_editor }
  # Default action: print the selected file path(s)
  default  { Write-Output @files }
}
