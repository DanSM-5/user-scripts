#!/usr/bin/env pwsh

# Path to search files in
$location = if ($args[0]) { $args[0] } else { '.' }
# Query to pass to fzf
$query = $args[1..$args.length]
$pattern = '.'
$editor = if ($env:PREFERRED_EDITOR) { $env:PREFERRED_EDITOR }
  elseif ($env:EDITOR) { $env:EDITOR }
  else { 'vim' }
# env variable for user config location
$user_conf_path = if ($env:user_conf_path) {
  $env:user_conf_path
} else { "$HOME/.usr_conf" }

# Detect native path separator
$dirsep = if ($IsWindows -or ($env:OS -eq 'Windows_NT')) { '\' } else { '/' }
if ($PSVersionTable.PSVersion -gt [version]'7.0.0') {
  $pwsh_cmd = 'pwsh'
  $preview_window = '60%'
  $change_preview_window = 'down|hidden|'
} else {
  $pwsh_cmd = 'powershell'
  $preview_window = 'hidden,60%'
  $change_preview_window = 'right|down|'
}
$fzfPreviewScript = Join-Path -Path $user_conf_path -ChildPath 'utils/fzf-preview.ps1'
$fzf_preview_normal = "$fzfPreviewScript . {}"

$fzf_options = @(
  '--height', '80%',
  '--min-height', '20',
  '--border'
  '--input-border',
  '--bind', 'alt-f:first',
  '--bind', 'alt-l:last',
  '--bind', 'alt-c:clear-query',
  '--bind', 'ctrl-a:select-all',
  '--bind', 'ctrl-d:deselect-all',
  '--bind', "ctrl-/:change-preview-window($change_preview_window)",
  '--bind', 'ctrl-^:toggle-preview',
  '--bind', 'alt-up:preview-page-up,alt-down:preview-page-down',
  '--bind', 'ctrl-s:toggle-sort',
  '--ansi',
  '--cycle',
  '--multi',
  '--preview-window', $preview_window,
  '--with-shell', "$pwsh_cmd -NoLogo -NonInteractive -NoProfile -Command",
  '--preview', $fzf_preview_normal,
  '--header', "(ctrl-/) Search in: $location"
)

if ($query) {
  $fzf_options += @('--query', "$query")
}

$fd_show = "$user_conf_path${dirsep}fzf${dirsep}fd_show" 
$fd_exclude = "$user_conf_path${dirsep}fzf${dirsep}fd_exclude" 

if (Test-Path -Path $fd_show -PathType Leaf -ErrorAction SilentlyContinue) {
  $fd_show = Get-Content $fd_show
} else {
  $fd_show = @()
}

if (Test-Path -Path $fd_exclude -PathType Leaf -ErrorAction SilentlyContinue) {
  $fd_exclude = Get-Content $fd_exclude
} else {
  $fd_exclude = @()
}

# If location is not a directory
# set it as the pattern and search from the home directory
if ( -not (Test-Path -Path $location -PathType Container -ErrorAction SilentlyContinue) ) {
  $pattern = "$location"
  $location = "$HOME"
}

$location = if ($location -eq '~') { $HOME } else { $location }
if ("$location" -like '~*') {
  $location = $HOME + $location.Substring(1)
}

$selection = @($(
  fd `
    @fd_show `
    @fd_exclude `
    --path-separator '/' `
    --color=always `
    -tf `
    "$pattern" "$location" |
  fzf `
    @fzf_options
))

if (-not $selection) {
  return
}

& "$editor" $selection

