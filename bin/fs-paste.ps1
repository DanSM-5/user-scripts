#!/usr/bin/env pwsh

# fs-clipboard
# Utility to paste content from a cache file
# It is useful to store information when working on a environment
# without a $DISPLAY variable (no xclip, xsel, wl-paste)

$CACHE_DIR = if ($env:FS_CLIPBOARD_CACHE_DIR) { $env:FS_CLIPBOARD_CACHE_DIR } else { "$HOME/.cache/fs-clipboard" }
$CACHE_FILE = "clipboard"
New-Item $CACHE_DIR -ItemType Directory -ErrorAction SilentlyContinue

# Empty clipboard (no file currently exists)
if (!(Test-Path -Path "$CACHE_DIR/$CACHE_FILE" -PathType Leaf -ErrorAction SilentlyContinue)) {
  Write-Output ""
  exit 0
}

# Get content from cache file
Get-Content "$CACHE_DIR/$CACHE_FILE"

