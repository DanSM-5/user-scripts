#!/usr/bin/env pwsh

<#
.SYNOPSIS
  Browse the commit history of one line with fzf.

.DESCRIPTION
  Trace <line>:<path> with `git log -L <line>,+1:<path> -s`. When the input is
  omitted, select one code line through a live ripgrep-backed fzf picker.

.PARAMETER GitArgs
  Extra arguments passed to git log.

.PARAMETER Edit
  Open the selected commit patches in the preferred editor.

.PARAMETER Display
  Open fzf using the full terminal screen.

.PARAMETER Print
  Print the selected commit patches on exit.

.PARAMETER Help
  Show help.

.PARAMETER LinePath
  A positive line number and path separated by the first colon.

.OUTPUTS
  Selected commit hashes by default, or `git show` output with -Print/ctrl-o.

.EXAMPLE
  git-line-blame '45:path/to/file'

.EXAMPLE
  git-line-blame -GitArgs '--first-parent' '45:path/to/file'

.EXAMPLE
  git-line-blame
#>

[CmdletBinding()]
Param(
  [string[]] $GitArgs = @(),
  [Switch] $Edit = $false,
  [Switch] $Display = $false,
  [Switch] $Print = $false,
  [Switch] $Help = $false,
  [Parameter(ValueFromRemainingArguments = $true, Position = 0)]
  [String[]] $LinePath = @()
)

function showHelp {
  Write-Host "
    Show the commit history of one line

    Synopsis:
      > git-line-blame [flags] [<line>:<path>]

    Description:
      Trace one line through history with 'git log -L <line>,+1:<path> -s'
      and browse the matching commits with fzf. The default preview shows the
      selected commit's patch scoped to the same file.

      When <line>:<path> is omitted, a ripgrep-backed fzf picker selects a
      single line of code before opening its line history.

    Usage:
      git-line-blame '45:path/to/file'
      git-line-blame -GitArgs '--first-parent' '45:path/to/file'
      git-line-blame

    Dependencies:
      - git
      - fzf
      - rg
      - delta (optional)
      - bat   (optional)

    Flags:
      -Help [switch]               > Print this message.
      -GitArgs [string[]]          > Extra arguments passed to git log.
      -Edit [switch]               > Open selected patches in `$EDITOR.
      -Display [switch]            > Show fzf in full screen.
      -Print [switch]              > Print selected commit patches on exit.

    Environment:
      GLB_FZF_ARGS                 > Extra arguments passed to both fzf pickers.
      GLB_GIT_ARGS                 > Extra arguments passed to git log.
      GLB_RG_ARGS                  > Extra arguments passed to ripgrep.
      GLB_RG_PREFIX                > Override the ripgrep picker command.
      GLB_BAT_ARGS                 > Extra arguments passed to bat.
      FZF_HIST_DIR                 > Directory for fzf query history.
      PREFERRED_EDITOR/EDITOR/VISUAL > Editor used by -Edit and ctrl-e.

    Arguments:
      A positive line number and repository-relative file path, separated by
      the first colon. Quote the value when the path contains spaces.
  "
}

if ($Help) {
  showHelp
  exit
}

git rev-parse HEAD *> $null
if ($LASTEXITCODE -ne 0) {
  Write-Error 'Not a git repo!'
  exit 1
}

$originalLocation = (Get-Location).Path
$toplevel = (git rev-parse --show-toplevel).Trim()
$prefix = (git rev-parse --show-prefix).Trim()
Set-Location -LiteralPath $toplevel

$pwsh = if (Get-Command -Name 'pwsh' -All -ErrorAction SilentlyContinue) {
  'pwsh'
} else {
  'powershell'
}
$trueCmd = if ($IsWindows -or ($env:OS -eq 'Windows_NT')) { 'cd .' } else { 'true' }

$GLB_FZF_ARGS = if ($env:GLB_FZF_ARGS) { $env:GLB_FZF_ARGS } else { '' }
$GLB_GIT_ARGS = if ($env:GLB_GIT_ARGS) { $env:GLB_GIT_ARGS } else { '' }
$GLB_RG_ARGS = if ($env:GLB_RG_ARGS) { $env:GLB_RG_ARGS } else { '' }
$GLB_RG_PREFIX = if ($env:GLB_RG_PREFIX) {
  $env:GLB_RG_PREFIX
} else {
  "rg --column --line-number --no-heading --color=always --smart-case --no-ignore --glob '!.git' --glob '!node_modules' --hidden"
}
$GLB_BAT_ARGS = if ($env:GLB_BAT_ARGS) { $env:GLB_BAT_ARGS } else { '' }

$fzfArgs = [System.Collections.Generic.List[string]]::new()
if ($Display) {
  $fzfArgs.Add('--bind')
  $fzfArgs.Add('ctrl-/:change-preview-window(right|hidden|)')
  $fzfArgs.Add('--preview-window')
  $fzfArgs.Add('top,60%,wrap-word')

  if ($IsWindows -or ($env:OS -eq 'Windows_NT')) {
    # fzf does not consistently recognize ctrl-/ and ctrl-^ at exactly 100%.
    $fzfArgs.Add('--height')
    $fzfArgs.Add('99%')
  } else {
    $fzfArgs.Add('--height')
    $fzfArgs.Add('100%')
  }
} else {
  $fzfArgs.Add('--height')
  $fzfArgs.Add('80%')
  $fzfArgs.Add('--bind')
  $fzfArgs.Add('ctrl-/:change-preview-window(down|hidden|)')
  $fzfArgs.Add('--preview-window')
  $fzfArgs.Add('right,60%,wrap-word')
}

foreach ($farg in ($GLB_FZF_ARGS -Split ' ')) {
  if ($farg.Trim()) {
    $fzfArgs.Add($farg.Trim())
  }
}

$helpCatCmd = ''
if (Get-Command -Name 'bat' -All -ErrorAction SilentlyContinue) {
  $helpCatCmd = '| bat --color=always --language help --style=plain'
}

function Select-CodeLine {
  if (-not (Get-Command -Name 'rg' -All -ErrorAction SilentlyContinue)) {
    Write-Error 'git-line-blame requires rg for interactive line selection'
    return
  }

  $rgCommand = "$GLB_RG_PREFIX $GLB_RG_ARGS {q} || $trueCmd"
  $batStyle = if ($env:BAT_STYLE) { $env:BAT_STYLE } else { 'numbers' }
  $filePreview = @"
`$FILE = {1}
`$NUMBER = {2}
if (Get-Command -Name 'bat' -All -ErrorAction SilentlyContinue) {
  bat --style='$batStyle' --color=always --pager=never --highlight-line=`$NUMBER $GLB_BAT_ARGS -- `$FILE
} else {
  Get-Content -LiteralPath `$FILE
}
"@

  $commitsPreview = @'
$FILE = {1}
git log --color=always --oneline --decorate --follow -- $FILE
'@

  $lineHelp = @"
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
    ctrl-d: Preview selected line in file (default)
    ctrl-g: Preview commits that changed the file

  Search keys:
    ctrl-r: Live ripgrep search
    ctrl-f: Fuzzy filter current results
    alt-r: Reload ripgrep results

  Cursor keys:
    alt-f: Go first
    alt-l: Go last
    alt-c: Clear query
' $helpCatCmd
"@

  [string[]] $selection = fzf `
    --accept-nth '{2}:{1}' `
    --ansi --cycle --no-multi `
    --bind 'alt-c:clear-query' `
    --bind 'alt-f:first' `
    --bind 'alt-l:last' `
    --bind 'alt-up:preview-page-up,alt-down:preview-page-down' `
    --bind 'ctrl-^:toggle-preview' `
    --bind 'ctrl-s:toggle-sort' `
    --bind 'shift-up:preview-up,shift-down:preview-down' `
    --bind "start:reload($rgCommand)" `
    --bind "change:reload:$rgCommand" `
    --bind "alt-r:reload($rgCommand)" `
    --bind "ctrl-r:unbind(ctrl-r)+change-prompt(Ripgrep> )+disable-search+reload($rgCommand)+rebind(change,ctrl-f)" `
    --bind 'ctrl-f:unbind(change,ctrl-f)+change-prompt(FzfFilter> )+enable-search+clear-query+rebind(ctrl-r)' `
    --bind "ctrl-d:change-preview:$filePreview" `
    --bind "ctrl-g:change-preview:$commitsPreview" `
    --bind "alt-h:preview:$lineHelp" `
    --delimiter : `
    --disabled `
    --header 'ctrl-r: Ripgrep | ctrl-f: Fzf filter | alt-h: Help' `
    --input-border `
    --layout=reverse `
    --min-height 20 --border `
    --preview "$filePreview" `
    --prompt 'Ripgrep> ' `
    --with-shell "$pwsh -NoLogo -NonInteractive -NoProfile -Command" `
    @fzfArgs

  if ($selection.Count -gt 0) {
    return $selection[0]
  }
}

$selectedInteractively = $LinePath.Count -eq 0
if ($selectedInteractively) {
  if (-not (Get-Command -Name 'rg' -All -ErrorAction SilentlyContinue)) {
    Write-Error 'git-line-blame requires rg for interactive line selection'
    exit 1
  }
  $linePathValue = Select-CodeLine
} else {
  # As in git-file-history, the last positional value wins.
  $linePathValue = $LinePath[-1]
}

if (-not $linePathValue) {
  exit
}

if ($linePathValue -notmatch '^([1-9][0-9]*):(.*)$' -or -not $Matches[2]) {
  Write-Error "Invalid input '$linePathValue'. Expected a positive <line>:<path>"
  exit 1
}

$lineNumber = $Matches[1]
$pathInput = $Matches[2]

if (-not $selectedInteractively) {
  if ([IO.Path]::IsPathRooted($pathInput)) {
    $fullPath = [IO.Path]::GetFullPath($pathInput)
    $pathInput = [IO.Path]::GetRelativePath($toplevel, $fullPath).Replace('\', '/')
    if ($pathInput -eq '..' -or $pathInput.StartsWith('../')) {
      Write-Error "The file must be inside the repository: $fullPath"
      exit 1
    }
  } elseif ($prefix) {
    $pathInput = "$prefix$($pathInput -replace '^\.[\\/]', '')"
  }
}

$trackedFiles = @(
  git -c core.quotePath=false ls-files -- $pathInput |
    Where-Object { $_ }
)

if ($trackedFiles.Count -eq 0) {
  Write-Error "Cannot find a tracked file matching: $pathInput"
  exit 1
}

if ($trackedFiles.Count -ne 1) {
  Write-Error "The path must resolve to exactly one tracked file: $pathInput"
  exit 1
}

$filename = $trackedFiles[0]
git cat-file -e "HEAD:$filename" 2>$null
if ($LASTEXITCODE -ne 0) {
  Write-Error "The file does not exist at HEAD: $filename"
  exit 1
}

$editor = if ($env:PREFERRED_EDITOR) {
  $env:PREFERRED_EDITOR
} elseif ($env:EDITOR) {
  $env:EDITOR
} elseif ($env:VISUAL) {
  $env:VISUAL
} else {
  'vim'
}

$historyLocation = if ($env:FZF_HIST_DIR) {
  $env:FZF_HIST_DIR
} else {
  "$HOME/.cache/fzf-history"
}
$historyFile = "$historyLocation/git-line-blame" -Replace '\\', '/'
New-Item -Path $historyLocation -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

# Preview commands receive the path through the environment so spaces and
# shell metacharacters are not interpolated into executable source.
$env:GIT_LINE_BLAME_FILE = $filename
$env:GIT_LINE_BLAME_LINE = $lineNumber

$allGitArgs = @($GLB_GIT_ARGS, ($GitArgs -Join ' ')) |
  Where-Object { $_ -and $_.Trim() }
$gitArgText = $allGitArgs -Join ' '
$format = '%C(auto)%h%d %s %C(black)%C(bold)%cr %C(auto)%an'
$sourceCommand = "git log $gitArgText -L `"`$env:GIT_LINE_BLAME_LINE,+1:`$env:GIT_LINE_BLAME_FILE`" -s --color=always --format='$format'"

if (Get-Command -Name 'delta' -All -ErrorAction SilentlyContinue) {
  $previewCmd = 'git show --color=always {1} -- "$env:GIT_LINE_BLAME_FILE" | delta'
  $previewAll = 'git show --color=always {1} | delta'
} else {
  $previewCmd = 'git show --color=always {1} -- "$env:GIT_LINE_BLAME_FILE"'
  $previewAll = 'git show --color=always {1}'
}

$previewFile = 'git show --color=always {1}:"$env:GIT_LINE_BLAME_FILE"'
if (Get-Command -Name 'bat' -All -ErrorAction SilentlyContinue) {
  $batStyle = if ($env:BAT_STYLE) { $env:BAT_STYLE } else { 'numbers,header' }
  $previewFile += " | bat --color=always --style=$batStyle $GLB_BAT_ARGS --file-name `"`$env:GIT_LINE_BLAME_FILE`""
}
$previewGraph = 'git log --color=always --oneline --decorate --graph {1}'
$previewFileNames = 'git show --color=always --name-only {1}'

$commitHelp = @"
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
    ctrl-o: Exit and print selected hash(es) with git show
    ctrl-e: Exit and open selected hash(es) in editor
    alt-x: Remove selected hash(es) from result
    alt-r: Reload line history

  Cursor keys:
    alt-a: Select all
    alt-d: Deselect all
    alt-f: Go first
    alt-l: Go last
    alt-c: Clear query
' $helpCatCmd
"@

$copy = 'Get-Content {+f} | ForEach-Object { ($_ -Split "\s+")[0] } | Set-Clipboard'
$commits = [System.Collections.Generic.List[string]]::new()

$sourceCommand | Invoke-Expression | fzf `
  --accept-nth '{1}' `
  --ansi --cycle --multi --no-sort `
  --bind 'alt-a:select-all' `
  --bind 'alt-c:clear-query' `
  --bind 'alt-d:deselect-all' `
  --bind 'alt-f:first' `
  --bind 'alt-l:last' `
  --bind 'alt-up:preview-page-up,alt-down:preview-page-down' `
  --bind 'ctrl-^:toggle-preview' `
  --bind 'ctrl-s:toggle-sort' `
  --bind 'shift-up:preview-up,shift-down:preview-down' `
  --bind "ctrl-a:change-preview:$previewAll" `
  --bind "ctrl-d:change-preview:$previewCmd" `
  --bind "ctrl-f:change-preview:$previewFile" `
  --bind "ctrl-g:change-preview:$previewGraph" `
  --bind "alt-g:change-preview:$previewFileNames" `
  --bind "ctrl-y:execute-silent($copy)+bell" `
  --bind 'alt-x:exclude-multi' `
  --bind "alt-r:reload($sourceCommand)" `
  --bind "alt-h:preview:$commitHelp" `
  --expect 'ctrl-o,ctrl-e' `
  --header 'ctrl-a: Full patch | ctrl-d: File patch | alt-h: Help' `
  --footer="Line: $lineNumber | File: $filename" `
  --history="$historyFile" `
  --input-border `
  --layout=reverse `
  --min-height 20 --border `
  --preview "$previewCmd" `
  --prompt 'Line Blame> ' `
  --with-shell "$pwsh -NoLogo -NonInteractive -NoProfile -Command" `
  @fzfArgs | ForEach-Object {
    $commits.Add($_)
  }

# commits[0] is the --expect key (empty for enter); hashes follow.
if ($commits.Count -lt 2) {
  exit
}

$expectedKey = $commits[0]
$hashes = $commits.GetRange(1, $commits.Count - 1)

function Print-SelectedPatches {
  git show @hashes
}

function Open-CommitEditor {
  $tmpfile = New-TemporaryFile
  git show @hashes > $tmpfile.FullName

  if ($editor -Match '^n?vim?$') {
    & "$editor" -c 'setlocal filetype=git' $tmpfile.FullName
  } else {
    & "$editor" $tmpfile.FullName
  }
}

if ($expectedKey -eq 'ctrl-o') {
  Print-SelectedPatches
  exit
}

if ($expectedKey -eq 'ctrl-e') {
  Open-CommitEditor
  exit
}

if ($Print) {
  Print-SelectedPatches
  exit
}

if ($Edit) {
  Open-CommitEditor
  exit
}

Write-Output @hashes
