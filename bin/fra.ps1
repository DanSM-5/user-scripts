#!/usr/bin/env pwsh

# Interactive search files with rga

if (!(Get-Command -Name 'rga' -All -ErrorAction SilentlyContinue)) {
  exit
}

$RG_PREFIX = 'rga --files-with-matches'
[string[]]$selected = [string[]]@()
$OG_FZF_DEFAULT_COMMAND = ''
$query = $args[0]
$pwsh = if (Get-Command -Name 'pwsh' -All -ErrorAction SilentlyContinue) { 'pwsh' } else { 'powershell' }

$preview_cmd = if (!($env:NO_DELTA) -and (Get-Command 'delta' -ErrorAction SilentlyContinue)) {
  'rga --json --pretty --context 5 {q} {} | delta'
} else {
  'rga --pretty --context 5 {q} {}'
}
$preview = "
# Ensure filename won't break syntax
`$file = @'
{}
'@
`$file = `$file.Trim().Trim('`"').Trim(`"'`")
if (`$file) {
  $preview_cmd
}
"

try {
  $OG_FZF_DEFAULT_COMMAND = $env:FZF_DEFAULT_COMMAND
  $env:FZF_DEFAULT_COMMAND = "$RG_PREFIX '$query'"
  $selected = fzf --sort `
    --with-shell "$pwsh -NoLogo -NonInteractive -NoProfile -Command" `
    --preview $preview `
    --phony -q "$query" `
    --input-border `
    --multi --ansi --border `
    --bind "change:reload:$RG_PREFIX {q}" `
    --bind 'alt-a:select-all' `
    --bind 'alt-d:deselect-all' `
    --bind 'alt-f:first' `
    --bind 'alt-l:last' `
    --bind 'alt-c:clear-query' `
    --bind 'ctrl-^:toggle-preview' `
    --bind 'ctrl-/:change-preview-window(down|hidden|),alt-up:preview-page-up,alt-down:preview-page-down,ctrl-s:toggle-sort' `
    --preview-window="70%:wrap"
} finally {
  $env:FZF_DEFAULT_COMMAND = $OG_FZF_DEFAULT_COMMAND
}

foreach ($item in $selected) {
  if (!$item) {
    continue
  }
  Write-Output "Opening: $item"
  Start-Process "$item"
}

