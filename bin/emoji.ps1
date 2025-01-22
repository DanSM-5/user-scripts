#!/usr/bin/env pwsh

param (
  [Switch]
  $Clean = $false
)

# Set utf-8 encoding. This helps windows.
$OutputEncoding = [Console]::OutputEncoding = New-Object System.Text.Utf8Encoding

$cache_dir = if ($env:user_config_cache) {
  $env:user_config_cache
} else {
  "$HOME/.cache/.user_config_cache"
}

$cache_dir = "$cache_dir/emojis"
$emoji_file = "$cache_dir/emoji"
$history_file = if ($env:FZF_HIST_DIR) { "$env:FZF_HIST_DIR/emoji" } else { "$HOME/.cache/fzf-history/emoji" }

if ($Clean) {
  Remove-Item -Path $emoji_file -Force -ErrorAction SilentlyContinue *> $null
}

# Fetch if no emoji file
if (!(Test-Path -Path $emoji_file -PathType Leaf -ErrorAction SilentlyContinue)) {
  New-Item $cache_dir -ItemType Directory -ErrorAction SilentlyContinue
  $emoji_src = 'https://gist.githubusercontent.com/DanSM-5/4a54709c02fa96ddf6abf39fdc2475f6/raw/36f242671cf92f798a3785777545ee4456ad2884/emoji.txt'
  Invoke-WebRequest -Uri $emoji_src -UseBasicParsing -Method Get -OutFile $emoji_file *> $null
}

$selected_emoji = @( Get-Content $emoji_file |
  fzf --multi --ansi `
    --height 80% --min-height 20 --border `
    --history "$history_file" `
    --info=inline `
    --input-border `
    --bind 'ctrl-/:change-preview-window(down|hidden|)' `
    --bind 'alt-up:preview-page-up,alt-down:preview-page-down' `
    --bind 'ctrl-s:toggle-sort' `
    --bind 'alt-f:first' `
    --bind 'alt-l:last' `
    --bind 'alt-c:clear-query' `
    --with-shell 'pwsh -nolo -nopro -nonin -c' `
    --bind "ctrl-y:execute-silent(Get-Content {+f} | % { (`$_ -Split ' ')[0] } | Set-Clipboard)" `
    --bind "ctrl-u:execute-silent(Get-Content {+f} | % { (`$_ -Split ' ')[1] } | Set-Clipboard)" `
    --bind "ctrl-t:execute-silent(Get-Content {+f} | Set-Clipboard)" `
    --header 'Copy emoji: ctrl-y | Copy desc: ctrl-u | Copy all: ctrl-t' | ForEach-Object {
      $line = $_ -Split ' '
      $line[0]
    }
)

$selected_emoji

