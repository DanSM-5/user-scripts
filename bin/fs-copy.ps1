#!/usr/bin/env pwsh

# Handle stdin
[CmdletBinding()]
Param (
  [Parameter(ValueFromRemainingArguments = $true, position = 0)]
  [String[]]
  $RegularInput = @(),
  [Parameter(
    ValueFromPipeline = $true,
    ValueFromPipelineByPropertyName = $true
  )]
  [String[]]
  $PipeInput = @()
)

# fs-clipboard
# Utility to copy content into a cache file
# It is useful to store information when working on a environment
# without a $DISPLAY variable (no xclip, xsel, wl-copy)

Begin {
  $CACHE_DIR = if ($env:FS_CLIPBOARD_CACHE_DIR) { $env:FS_CLIPBOARD_CACHE_DIR } else { "$HOME/.cache/fs-clipboard" }
  $CACHE_FILE = "clipboard"
  New-Item $CACHE_DIR -ItemType Directory -ErrorAction SilentlyContinue
  [System.Collections.Generic.List[string]] $to_clipboard = @()
}

Process {
  foreach ($il in $PipeInput) {
    $to_clipboard.Add($il)
  }
}

End {
  # All arguments are strings to store
  if ($RegularInput) {
    [System.IO.File]::WriteAllLines("$CACHE_DIR/$CACHE_FILE", $RegularInput, [System.Text.UTF8Encoding]($false))
    exit 0
  }

  # Assume stdin if no arguments
  [System.IO.File]::WriteAllLines("$CACHE_DIR/$CACHE_FILE", ($to_clipboard -Join "`n"), [System.Text.UTF8Encoding]($false))
}

