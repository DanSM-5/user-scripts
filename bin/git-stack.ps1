#!/usr/bin/env pwsh

<#
.SYNOPSIS
  Git stack

.DESCRIPTION
  Show the commits reachable from HEAD but not from a target branch (the
  "stack"), i.e. 'git log <target>..HEAD', using fzf.
  Shell counterpart of the vim 'fzfgit#compare_commits' function.

.PARAMETER Help
  Show help message

.PARAMETER Fzf
  Fuzzy select the comparison branch with fzf instead of passing it as an argument.

.PARAMETER Target
  Target branch to compare against (defaults to the repository default branch).

.INPUTS
  No input from pipeline

.OUTPUTS
  The selected sha(s), or `git show` output, depending on the key pressed.

.EXAMPLE
  git-stack

.EXAMPLE
  git-stack feat/my-branch

.EXAMPLE
  git-stack origin/main

.EXAMPLE
  git-stack -Fzf

.EXAMPLE
  git-stack -Help

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
    Show the commit stack between a target branch and HEAD

    Synopsis:
      > git-stack [flags] [target-branch]

    Description:
      List the commits reachable from HEAD but not from a target branch
      (the repository's default branch when none is given), i.e. the commit
      stack 'git log <target>..HEAD'. The preview shows each commit's patch.

    Usage:
      git-stack                 # compare against the default branch
      git-stack feat/my-branch  # compare against a branch
      git-stack origin/main     # remote refs are fine
      git-stack -Fzf            # fuzzy select the branch first

    Keys:
      enter    Print the selected commit sha(s) (default)
      ctrl-o   Print the patch of the selected commit(s)
      ctrl-e   Open the selected commit(s) patch in `$EDITOR
      ctrl-f   Show the commit patch fullscreen through a pager (loop)
      ctrl-y   Copy the selected commit sha(s) to the clipboard
      alt-h    Show the help in the preview window

    Dependencies:
      - git
      - fzf
      - delta (optional)
      - bat   (optional, prettier help)
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

# Run from the repository root so the commands are repo scoped
$toplevel = (git rev-parse --show-toplevel).Trim()
Set-Location -LiteralPath $toplevel

# Color scheme used exclusively in git-stack (appended so other
# FZF_DEFAULT_OPTS are preserved). Set before any fzf call so the branch
# selection picker uses the same styling.
$env:FZF_DEFAULT_OPTS = "$env:FZF_DEFAULT_OPTS --color hl:33,fg+:214,hl+:33 --color spinner:208,pointer:196,marker:208"

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

$editor = if ($env:PREFERRED_EDITOR) {
  $env:PREFERRED_EDITOR
} elseif ($env:EDITOR) {
  $env:EDITOR
} else {
  'vim'
}

$pwsh = if (Get-Command -Name 'pwsh' -All -ErrorAction SilentlyContinue) { 'pwsh' } else { 'powershell' }

# Copy the first field (the sha), one per line
$copy = 'Get-Content {+f} | ForEach-Object { ($_ -Split "\s+")[0] } | Set-Clipboard'

# Rich, git-stack inspired log line. The short hash is always field {1}.
$format = '%C(auto)%h%d %s %C(black)%C(bold)%cr %C(auto)%an'
$source_command = "git log $target..HEAD --color=always --format='$format'"

# Preview the patch of the commit under the cursor. 'ctrl-f' shows the same
# patch fullscreen through a pager, mimicking the git-stack loop.
if (Get-Command -Name 'delta' -All -ErrorAction SilentlyContinue) {
  $preview = 'git show --color=always {1} | delta'
  $pager_view = 'git show --color=always {1} | delta | less -R'
} else {
  $preview = 'git show --color=always {1}'
  $pager_view = 'git show --color=always {1} | less -R'
}
# Preview file names changed in the commit
$preview_names = 'git show --color=always --name-only {1}'

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
    ctrl-d: Preview patch of commit (default)
    alt-g: Preview names of changed files in commit

  Utility keys:
    ctrl-f: Show commit patch fullscreen (pager loop)
    ctrl-y: Copy selected sha(s)
    ctrl-o: Exit and print selected sha(s) patch
    ctrl-e: Exit and open selected sha(s) patch in editor
    alt-x: Drop selected sha(s) from result
    alt-r: Reload

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
  --ansi --cycle --multi --no-sort `
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
  --bind "alt-r:reload:$source_command" `
  --bind "ctrl-d:change-preview:$preview" `
  --bind "alt-g:change-preview:$preview_names" `
  --bind "alt-h:preview:$help_cmd" `
  --bind "ctrl-f:execute($pager_view)" `
  --bind "ctrl-y:execute-silent($copy)+bell" `
  --bind 'alt-x:exclude-multi' `
  --expect 'ctrl-o,ctrl-e' `
  --header 'alt-h: Help | ctrl-o: Print | ctrl-e: Edit | ctrl-f: Fullscreen | ctrl-y: Copy' `
  --footer="Compare: $target..HEAD" `
  --input-border `
  --layout=reverse `
  --min-height 20 --border `
  --preview "$preview" `
  --preview-window 'right,60%,wrap-word' `
  --prompt 'Stack> ' `
  --with-shell "$pwsh -NoLogo -NonInteractive -NoProfile -Command" | ForEach-Object {
    $commits.Add($_)
  }

# commits[0] is the --expect key line (empty for enter); sha(s) follow.
# Nothing selected -> exit
if ($commits.Count -lt 2) {
  exit
}

$expected_key = $commits[0]
$hashes = $commits.GetRange(1, $commits.Count - 1)

function open_editor {
  $tmpfile = New-TemporaryFile
  git show @hashes > $tmpfile.FullName

  # On (n)vim editor set the git filetype
  if ($editor -Match '^n?vim?$') {
    & "$editor" -c 'setlocal filetype=git' $tmpfile.FullName
  } else {
    & "$editor" $tmpfile.FullName
  }
}

switch ($expected_key) {
  'ctrl-o' { git show @hashes }
  'ctrl-e' { open_editor }
  # Default action: print the selected commit sha(s)
  default  { Write-Output @hashes }
}
