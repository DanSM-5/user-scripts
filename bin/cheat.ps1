#!/usr/bin/env pwsh

# Fuzzy find help pages using cheat.sh

Param(
  # Remove cached files
  [Switch]
  $Clean = $false,
  # Starting query for fzf
  [Parameter(ValueFromRemainingArguments = $true, position = 0 )]
  [String[]]
  $Query = ''
)

$key_dir = 'cheat'
$cache_dir = if ($env:user_config_cache) { "$env:user_config_cache/$key_dir" } else { "$HOME/.cache/.user_config_cache}/$key_dir" }
$list_file = "$cache_dir/cheat_sh_list"
$help_file = "$cache_dir/cheat_sh_help"
$single = $true

if ($Clean) {
   Remove-Item -Recurse -Force "$cache_dir" *> $null
}

New-Item -ItemType Directory -Path "$cache_dir" -ErrorAction SilentlyContinue

# Download and cache list of commands
if (!(Test-Path -Path "$list_file" -PathType Container -ErrorAction SilentlyContinue)) {
  curl -sL 'cheat.sh/:list' > "$list_file"
}

# Download and cache help
if (!(Test-Path -Path "$help_file" -PathType Leaf -ErrorAction SilentlyContinue)) {
  curl -sL cheat.sh/:help > "$help_file"
}

$RELOAD = "reload:Get-Content $list_file"
$PREVIEW = "
  `$cmd_name = {}
  `$cmd_file = `"$cache_dir/`$cmd_name`"

  # Download and cache program cheat page
  if (!(Test-Path -Path `"`$cmd_file`" -PathType Leaf -ErrorAction SilentlyContinue)) {
    curl -sL `"cheat.sh/`$cmd_name`" > `"`$cmd_file`" || Write-Output ' ' > `"`$cmd_file`"
  }

  # cheat.sh help
  Get-Content `"`$cmd_file`" 2> `$null;

  # Separator
  Write-Output ==============================
"

$selected = fzf `
  --preview="$PREVIEW" `
  --preview-window '70%' `
  --bind=ctrl-h:preview:"Get-Content $help_file" `
  --tiebreak=begin,chunk,length `
  --reverse `
  --cycle `
  --multi `
  --query "$Query" `
  --with-shell 'pwsh -NoLogo -NonInteractive -NoProfile -Command' `
  --bind 'ctrl-/:change-preview-window(down|hidden|)' `
  --bind 'alt-up:preview-page-up' `
  --bind 'alt-down:preview-page-down' `
  --bind 'ctrl-s:toggle-sort' `
  --bind 'alt-f:first' `
  --bind 'alt-l:last' `
  --bind 'alt-c:clear-query' `
  --bind 'alt-a:select-all' `
  --bind 'alt-d:deselect-all' `
  --bind 'ctrl-l:toggle-preview' `
  --bind "start:$RELOAD" `
  --bind "change:$RELOAD"

if (!$selected) {
  exit
}

foreach ($cmd in $selected) {
  if (!$single) {
    Write-Output "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  }

  Write-Output "• ${cmd}:"

  Get-Content "$cache_dir/$cmd"
  $single = $false
}

