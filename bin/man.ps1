#!/usr/bin/env pwsh

# Script to open man pages in neovim
# In windows there are no man pages that come builtin
# You can use the script ./windows/download-man-pages.ps1
# to download man pages in the cache directory
#
# Dependencies:
#
# - fd
# - fzf
# - bat
# - mandoc
# - col
#
# Install with scoop:
#
# scoop bucket add extras
#
# scoop install fd
# scoop install fzf
# scoop install bat
# scoop install mandoc
# scoop install util-linux-ng
#
# Preview:
# Get-Content file | mandoc -man 2> `$null | col -bx | bat --color=always --style=plain --language man

$user_config_cache = if ($env:user_config_cache) { $env:user_config_cache } else { "$HOME/.cache/.user_config_cache" }
$manpages_dir = "$user_config_cache/manpages"

if (!(Test-Path -LiteralPath $manpages_dir -PathType Container -ErrorAction SilentlyContinue)) {
  Write-Error "No man pages directory '$manpages_dir'"
  exit 1
}

# $cwd = $PWD.Path
Push-Location -LiteralPath $manpages_dir *> $null

$selected = [string[]]@{}
$query = "$args"

if (!$query) {
  Write-Warning 'Provide the man page you want to see. E.g. > man [manpage]'
  exit 1
}

# tar -xgf $user_config_cache/manpages/usr_share_man/man1/bash.1.gz | mandoc -man 2> `$null | col -bx | bat --color=always --style=plain --language man

try {
  $preview = "
    `$file = @'
{}
'@
    `$file = `$file.Trim().Trim(`"'`").Trim('`"')
    `$full_path = `"$manpages_dir/`$file`"
    if ((Get-Item -LiteralPath `$full_path).Extension -eq '.gz') {
      function get_man_content () {
        7z -so e `$full_path
      }
    } else {
      function get_man_content () {
        Get-Content -LiteralPath `$full_path
      }
    }

    get_man_content |
      mandoc -man 2> `$null | col -bx |
      bat --color=always --style=plain --language man 2> `$null ||
    get_man_content | bat --color=always --style=plain
  "

  $selected = [string[]](fd --color=never `
      --follow `
      --type=file --path-separator '/' `
      --exclude '*.mk' `
      --exclude '*.sh' --exclude 'README*' `
      $query)

  if ($selected.Length -eq 0) {
    Write-Warning "No manual entry for $query"
    exit 1
  } elseif ($selected.Length -gt 1) {
    $selected = [string[]] ($selected | fzf --prompt='Man> ' --no-multi `
      --ansi --cycle `
      --input-border `
      --history="$env:FZF_HIST_DIR/man-vim" `
      --header 'Select man page' `
      --bind 'ctrl-s:toggle-sort' `
      --bind 'ctrl-/:change-preview-window(down|hidden|)' `
      --bind 'ctrl-^:toggle-preview' `
      --bind 'alt-up:preview-page-up' `
      --bind 'alt-down:preview-page-down' `
      --bind 'alt-a:select-all' `
      --bind 'alt-d:deselect-all' `
      --bind 'alt-f:first' `
      --bind 'alt-l:last' `
      --preview-window '65%,wrap' `
      --preview "$preview" `
      --with-shell 'pwsh -NoLogo -NonInteractive -NoProfile -Command' `
      --bind 'alt-c:clear-query')
  }

} finally {
  Pop-Location *> $null
}

if ($selected.Length -eq 0) {
  exit 0
}

$file = $selected[0]

# Man file
$file = "$manpages_dir/$file" -replace '\\', '/'

$tempFile = New-TemporaryFile

# Handle extract from gz file
if ((Get-Item -LiteralPath $file).Extension -eq '.gz') {
  # echo "7z -so e $file | mandoc -man 2> `$null | col -bx | bat --color=always --style plain --language man"
  function get_man_content () {
    7z -so e $file
  }
} else {
  function get_man_content () {
    Get-Content -LiteralPath $file
  }
}

# Build and display
try {
  get_man_content | mandoc -man 2> $null | col -bx > $tempFile.FullName
  bat --color=always --style=plain --language man $tempFile.FullName
} catch {
  get_man_content | bat --color=always --style=plain
} finally {
  if (Test-Path -LiteralPath $tempFile.FullName -PathType Leaf -ErrorAction SilentlyContinue) {
    Remove-Item -LiteralPath $tempFile.FullName -ErrorAction SilentlyContinue
  }
}

