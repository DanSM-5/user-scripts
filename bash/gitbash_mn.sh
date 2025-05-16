#!/usr/bin/env bash

[[ -v debug ]] && set -x

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

user_config_cache="${user_config_cache:-"$HOME/.cache/.user_config_cache"}"
manpages_dir="$user_config_cache/manpages"

if ! [ -d "$manpages_dir" ]; then
  printf 'No man pages directory: %s\n' "$manpages_dir" >&2
  exit 1
fi

pushd "$manpages_dir" &> /dev/null || exit 1

preview="
  file={}
  full_path=\"$manpages_dir/\$file\"
  if [[ \$full_path =~ .gz$ ]]; then
    get_man_content () {
      7z -so e \"\$full_path\"
    }
  else
    get_man_content () {
      cat \"\$full_path\"
    }
  fi

  get_man_content |
    mandoc -man 2>/dev/null | col -bx |
    bat --color=always --style=plain --language man 2>/dev/null ||
  get_man_content | bat --color=always --style=plain
"

mapfile -t selected < <(fd --color=always \
    --follow \
    --type=file \
    --exclude '*.mk' \
    --exclude '*.sh' --exclude 'README*' |
  fzf --prompt='Man> ' --no-multi \
    --ansi --cycle \
    --input-border \
    --history="$FZF_HIST_DIR/man-vim" \
    --header 'Select man page' \
    --bind 'ctrl-s:toggle-sort' \
    --bind 'ctrl-/:change-preview-window(down|hidden|)' \
    --bind 'ctrl-^:toggle-preview' \
    --bind 'alt-up:preview-page-up' \
    --bind 'alt-down:preview-page-down' \
    --bind 'alt-a:select-all' \
    --bind 'alt-d:deselect-all' \
    --bind 'alt-f:first' \
    --bind 'alt-l:last' \
    --preview-window '65%,wrap' \
    --preview "$preview" \
    --with-shell 'bash -c' \
    --bind 'alt-c:clear-query' \
)

pushd &>/dev/null || exit

if [ -z "$selected" ]; then
  exit 0
fi

# Man file
file="$manpages_dir/${selected[0]}"
tempFile="$(mktemp)"

cleanup () {
  if [ -f "$tempFile" ]; then
    rm "$tempFile"
  fi
}

trap cleanup exit

# Handle extract from gz file
if [[ $file =~ .gz$ ]]; then
  get_man_content () {
    7z -so e "$file"
  }
else
  get_man_content () {
    cat "$file"
  }
fi

# Build and display
if get_man_content | mandoc -man 2>/dev/null | col -bx | bat --color=always --style=plain --language man > "$tempFile"; then
  nvim "+silent Man!" "$tempFile"
fi
