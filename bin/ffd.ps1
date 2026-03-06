#!/usr/bin/env pwsh

# (f)zf (f)d
# Program to search for files interactively with fd and fzf

$user_conf_path = if ($env:user_conf_path) { $env:user_conf_path } else { "$HOME/.usr_conf" }
$preview_cmd = ""
$pwsh = 'powershell'

if (Get-Command -Name 'pwsh') {
  $pwsh = 'pwsh'
}

if (Test-Path -LiteralPath "$user_conf_path/utils/fzf-preview.sh" -PathType Leaf -ErrorAction SilentlyContinue) {
  $preview_cmd = "& $user_conf_path/utils/fzf-preview.ps1 {}"
} else {
  # Fallback preview
  $preview_cmd = '
    $focused = {}
    if (Test-Path -LiteralPath "$focused" -PathType Leaf -ErrorAction SilentlyContinue) {
      bat --color=always --style="numbers,header,changes" "$focused" 2> /dev/null ||
        Write-Output "Cannot preview file" 
    } elseif ( -f "$focused" ) {
      # Detect if on git reposiry. If so, print last commit information
      Push-Location -LiteralPath "$focused" *> /dev/null
      git log --color=always -1 2> $null
      $addspace = $?
      if ($addspace) { Write-Output "" }
      Pop-Location *> /dev/null

      erd --layout inverted --color force --level 3 --suppress-size -I -- "$focused" 2> /dev/null ||
        eza -A --tree --level=3 --color=always --icons=always --dereference "$focused" 2> /dev/null ||
        ls -AFL --color=always "$focused" 2> /dev/null ||
        Write-Output "Cannot preview directory"
    } else {
      Write-Output "Unknown item: $focused"
    }
  '
}

$FFD_FZF_ARGS = if ($env:FFD_FZF_ARGS) { $env:FFD_FZF_ARGS } else { '' }
$FFD_FD_ARGS = if ($env:FFD_FD_ARGS) { $env:FFD_FD_ARGS } else { '' }
$FD_PREFIX = if ($env:FFD_PREFIX_COMMAND) { $env:FFD_PREFIX_COMMAND } else { 'fd --hidden --no-ignore --exclude .git --exclude node_modules --color=always' }
$FD_PREFIX = "$FD_PREFIX $FFD_FD_ARGS "
$win = $IsWindows -or ($env:OS -eq 'Windows_NT')
$true_cmd = if ($win) { 'cd .' } else { 'true' }
$RELOAD = "reload:$FD_PREFIX {q} || $true_cmd"

$fzf_args = [System.Collections.Generic.List[string]]::new()

$fzf_args.AddRange([string[]]@(
  '--header', '╱ CTRL-R (fd mode) ╱ CTRL-F (fzf mode) ╱',
  '--disabled', '--ansi', '--multi',
  '--cycle',
  '--input-border',
  '--bind', 'alt-up:preview-page-up,alt-down:preview-page-down',
  '--bind', 'ctrl-s:toggle-sort',
  '--bind', 'alt-f:first',
  '--bind', 'alt-l:last',
  '--bind', 'alt-c:clear-query',
  '--bind', 'alt-a:select-all',
  '--bind', 'alt-d:deselect-all',
  '--bind', "ctrl-^:toggle-preview",
  '--bind', "ctrl-l:toggle-preview",
  '--bind', 'ctrl-/:change-preview-window(down|hidden|)',
  '--bind', "start:$RELOAD",
  '--bind', "change:$RELOAD",
  '--bind', "ctrl-r:unbind(ctrl-r)+change-prompt(1. 🔎 fd> )+disable-search+reload($FD_PREFIX {q} || :)+rebind(change,ctrl-f)",
  '--bind', "ctrl-f:unbind(change,ctrl-f)+change-prompt(2. ✅ fzf> )+enable-search+clear-query+rebind(ctrl-r)",
  '--prompt', '1. 🔎 fd> ',
  '--delimiter', ':' ,
  '--preview', "$preview_cmd",
  '--preview-window', '+{2}-/2,right,60%,wrap-word',
  '--with-shell', "$pwsh -NoLogo -NonInteractive -NoProfile -ExecutionPolicy Bypass -Command"
))

foreach ($farg in ($FFD_FZF_ARGS -Split ' ')) {
  if ($farg.Trim()) {
    $fzf_args.Add($farg.Trim())
  }
}

if ($args) {
  $fzf_args.Add('--query')
  $fzf_args.Add("$args")
}

if ($win) {
  With-UTF8 {
    fzf `
      @fzf_args
  }
} else {
  fzf `
    @fzf_args
}
