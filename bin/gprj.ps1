#!/usr/bin/env pwsh

# Print results
$edit_selected = $args[0] -eq '-e'

# Setup
$dirsep = if ($IsWindows -or ($env:OS = 'Windows_NT')) { '\' } else { '/' }
$user_conf_path = if ($env:user_conf_path) { $env:user_conf_path } else { "${HOME}${dirsep}.usr_conf" }
$user_scripts_path = if ($env:user_scripts_path) { $env:user_scripts_path } else { "${HOME}${dirsep}user-scripts" }
$fzf_preview_normal = "$user_conf_path/utils/fzf-preview.ps1 {}"
$GPRJ_FZF_ARGS = if ($env:GPRJ_FZF_ARGS) { $env:GPRJ_FZF_ARGS } else { '' }
$fzf_history = if ($env:FZF_HIST_DIR) { $env:FZF_HIST_DIR } else {
  "$($HOME.Replace('\', '/'))/.cache/fzf-history"
}
$editor = if ($env:PREFERRED_EDITOR) { $env:PREFERRED_EDITOR }
  elseif ($env:EDITOR) { $env:EDITOR }
  else { 'vim' }
if ($PSVersionTable.PSVersion -gt [version]'7.0.0') {
  $pwsh_cmd = 'pwsh'
} else {
  $pwsh_cmd = 'powershell'
}
New-Item -Path $fzf_history -ItemType Directory -ErrorAction SilentlyContinue

# Check if separated by null character "`0"
$split_char = ' '
# if ($GPRJ_FZF_ARGS.Contains("`0")) {
#   $split_char = "`0"
# }

$fzf_args = [System.Collections.Generic.List[string]]::new()
foreach ($farg in ($GPRJ_FZF_ARGS -Split ' ')) {
  if ($farg.Trim()) {
    $fzf_args.Add($farg.Trim())
  }
}

# Commands for fzf
$fd_command = "fds --color=always --type file . {}"
$load_command = "${env:user_conf_path}${dirsep}utils${dirsep}getprojects.ps1"

# Fzf selection
$selection = & $load_command |
  fzf `
    --history="$fzf_history/cprj" `
    --ansi --cycle `
    --bind 'alt-a:select-all' `
    --bind 'alt-c:clear-query' `
    --bind 'alt-d:deselect-all' `
    --bind 'alt-f:first' `
    --bind 'alt-l:last' `
    --bind 'alt-up:preview-page-up,alt-down:preview-page-down' `
    --bind 'ctrl-/:change-preview-window(down|hidden|)' `
    --bind 'ctrl-^:toggle-preview' `
    --bind 'ctrl-s:toggle-sort' `
    --bind "ctrl-f:change-prompt(Files> )+reload($fd_command)+clear-query+change-multi+unbind(ctrl-f)" `
    --bind "ctrl-o:execute-silent(Start-Process {})+abort" `
    --bind "ctrl-r:change-prompt(Projs> )+reload($load_command)+rebind(ctrl-f)+clear-query+change-multi(0)" `
    --bind "ctrl-y:execute-silent(${env:user_conf_path}${dirsep}utils${dirsep}copy-helper.ps1 {+f})+abort" `
    --header 'ctrl-r: Projects | ctrl-f: Files | ctrl-o: Open | ctrl-y: Copy' `
    --height 80% --min-height 20 --border `
    --input-border `
    --no-multi `
    --preview-window '60%' `
    --preview "$fzf_preview_normal" `
    --with-shell "$pwsh_cmd -NoLogo -NonInteractive -NoProfile -Command" `
    --prompt 'Projs> ' `
    @fzf_args

# Exit if no selection
if (!$selection) { return }

# Edit selected files
if ($edit_selected -and (Test-Path -PathType Leaf -Path $selection[0] -ErrorAction 0)) {
  & "$editor" @selection
  exit
}

# Return selected
$selection

