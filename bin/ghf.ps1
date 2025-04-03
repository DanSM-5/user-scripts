#!/usr/bin/env pwsh

if (!(Get-Command -Name 'gh' -All -ErrorAction SilentlyContinue)) {
  exit 1
}

$pwsh = if ($PSVersionTable.PSVersion -gt 7) { 'pwsh' } else { 'powershell' }
$pwsh = "$pwsh -NoLogo -NonInteractive -NoProfile -Command"
$preview = '
  $OG_GH_FORCE_TTY = $env:GH_FORCE_TTY
  try {
    $env:GH_FORCE_TTY = $env:FZF_PREVIEW_COLUMNS
    gh pr view {1}
  } finally {
    $env:GH_FORCE_TTY = $OG_GH_FORCE_TTY
  }
'
$commond_options = @(
  '--bind', 'alt-c:clear-query',
  '--bind', 'ctrl-l:change-preview-window(down|hidden|)',
  '--bind', 'ctrl-/:change-preview-window(down|hidden|)',
  '--bind', 'alt-up:preview-page-up,alt-down:preview-page-down',
  '--bind', 'shift-up:preview-up,shift-down:preview-down',
  '--bind', 'ctrl-^:toggle-preview',
  '--bind', 'ctrl-s:toggle-sort',
  '--bind', 'alt-f:first',
  '--bind', 'alt-l:last',
  '--bind', 'alt-a:select-all',
  '--bind', 'alt-d:deselect-all',
  '--cycle',
  '--ansi',
  '--input-border',
  '--no-multi',
  '--with-shell', $pwsh,
  '--accept-nth', '{1}'
)

$filters = @(
  '0 Assigned to me',
  '1 Created by me',
  '2 Needs my review',
  '3 Draft PRs only',
  '4 Ready PRs only',
  '5 Merged PRs',
  '6 Closed PRs'
)
$filter_cmds = @(
  '--assigned @me',
  '--author @me',
  "--search 'review-requested:@me'",
  '--draft',
  "--search 'draft:false'",
  '--state merged',
  '--state closed'
)
$prompt_cmds = @(
  'Assigned PRs> ',
  'Author PRs> ',
  'Need Review> ',
  'Draft PRs> ',
  'Ready PRs> ',
  'Merged PRs> ',
  'Closed PRs> '
)

function select_filter () {
  $filter = $filters | fzf `
    --no-multi `
    --input-border `
    --cycle `
    --with-nth '2..' `
    @commond_options

  if ($filter) {
    $cmd = "gh pr list " + $filter_cmds[$filter]
    return show_prs $cmd $prompt_cmds[$filter]
  }

  show_prs
}

function show_prs (
  [string] $Cmd = 'gh pr list',
  [string] $Prompt = 'Github PRs> '
) {
  $OG_GH_FORCE_TTY = $env:GH_FORCE_TTY
  try {
    $env:GH_FORCE_TTY = '100%'
    [string[]] $selected = fzf `
      --bind "start:reload:$cmd" `
      --bind 'ctrl-o:execute-silent:gh pr view {1} --web' `
      --header 'ctrl-f: Filter PRs | ctrl-o: Open in browser | ctrl-s: Checkout to PR | ctrl-d: Display PR' `
      --expect='ctrl-f,ctrl-s,ctrl-d' `
      --header-lines '4' `
      --prompt "$Prompt" `
      --preview "$preview" `
      --preview-window '50%' `
      @commond_options

    if ($selected.Length -eq 0) {
      exit
    }

    switch ($selected[0]) {
      'ctrl-f' { return gh pr checkout $selected[1] }
      'ctrl-s' { return select_filter }
      'ctrl-d' { return gh pr view $selected[1] }
      default { return $selected[1] }
    }
  } finally {
    $env:GH_FORCE_TTY = $OG_GH_FORCE_TTY
  }
}

show_prs
