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

if ($Clean) {
  Remove-Item -Path $emoji_file -Force -ErrorAction SilentlyContinue *> $null
}

# Fetch if no emoji file
if (!(Test-Path -Path $emoji_file -PathType Leaf -ErrorAction SilentlyContinue)) {
  New-Item $cache_dir -ItemType Directory -ErrorAction SilentlyContinue
  Invoke-WebRequest -Uri 'https://git.io/JXXO7' -UseBasicParsing -Method Get -OutFile $emoji_file *> $null
}

$selected_emoji = @( Get-Content $emoji_file |
  fzf --multi --ansi `
    --height 80% --min-height 20 --border `
    --info=inline `
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
    --header 'Copy emoji: ctrl-y | Copy desc: ctrl-u | Copy all: ctrl-t' | % {
      $line = $_ -Split ' '
      $line[0]
    }
)

$selected_emoji

