#!/usr/bin/env pwsh

<#
.SYNOPSIS
  Browse GitHub pull requests with fzf.

.PARAMETER Display
  Make fzf fill the current terminal. Windows uses 99 percent to avoid tcell
  input handling issues at exactly 100 percent.

.PARAMETER Expect
  Replace fzf expected keys and print the pressed key followed by the selected
  PR number. Also available through GHF_EXPECT.
#>
Param(
  [Switch] $Display,

  # Delegate expected-key behavior to the caller
  [AllowEmptyString()]
  [String] $Expect = $env:GHF_EXPECT,

  [Parameter(DontShow)]
  [Nullable[Int]] $FilesPreview
)

$files_preview_exit_code = 0

function show_pr_files ([Int] $Pr) {
  $original_gh_force_tty = $env:GH_FORCE_TTY

  try {
    Remove-Item Env:GH_FORCE_TTY -ErrorAction SilentlyContinue

    $pr_info_json = gh pr view $Pr --json id,url
    $gh_exit_code = $LASTEXITCODE
    if ($gh_exit_code -ne 0) {
      $script:files_preview_exit_code = $gh_exit_code
      return
    }

    $pr_info = $pr_info_json | ConvertFrom-Json
    $github_host = ([Uri] $pr_info.url).Host
    $query = 'query($id: ID!, $endCursor: String) { node(id: $id) { ... on PullRequest { files(first: 100, after: $endCursor) { nodes { path changeType } pageInfo { hasNextPage endCursor } } } } }'
    $responses = gh api graphql `
      --hostname $github_host `
      --paginate `
      --slurp `
      -F "id=$($pr_info.id)" `
      -f "query=$query"
    $gh_exit_code = $LASTEXITCODE
    if ($gh_exit_code -ne 0) {
      $script:files_preview_exit_code = $gh_exit_code
      return
    }

    $ansi_escape = [String][Char] 27
    $status_colors = @{
      ADDED = '32'
      MODIFIED = '33'
      REMOVED = '31'
      RENAMED = '36'
    }

    $responses |
      ConvertFrom-Json |
      ForEach-Object { $_.data.node.files.nodes } |
      ForEach-Object {
        $status = if ($_.changeType -eq 'DELETED') { 'REMOVED' } else { $_.changeType }
        $status_color = $status_colors[$status]
        if ($null -eq $status_color) {
          $status_color = '35'
        }
        $label = "[$status]".PadRight(10)
        Write-Output ($ansi_escape + '[' + $status_color + 'm' + $label + $ansi_escape + "[0m`t" + $_.path)
      }
  } finally {
    if ($null -eq $original_gh_force_tty) {
      Remove-Item Env:GH_FORCE_TTY -ErrorAction SilentlyContinue
    } else {
      $env:GH_FORCE_TTY = $original_gh_force_tty
    }
  }
}

$delegate_output = $PSBoundParameters.ContainsKey('Expect') -or (Test-Path Env:GHF_EXPECT)
$expect_keys = if ($delegate_output) {
  if ([String]::IsNullOrWhiteSpace($Expect)) { 'enter' } else { $Expect }
} else {
  'ctrl-s,ctrl-d'
}
$fzf_expect_keys = "ctrl-f,$expect_keys"

if (!(Get-Command -Name 'gh' -All -ErrorAction SilentlyContinue)) {
  exit 1
}

if ($null -ne $FilesPreview) {
  show_pr_files $FilesPreview
  exit $files_preview_exit_code
}

$pwsh = if ($PSVersionTable.PSEdition -eq 'Core') { 'pwsh' } else { 'powershell' }
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
$diff_preview = 'gh pr diff {1} --color=always'
if (Get-Command -Name 'delta' -All -ErrorAction SilentlyContinue) {
  $diff_preview = "$diff_preview | delta"
}
$escaped_script_path = $PSCommandPath.Replace("'", "''")
$files_preview = "& '$escaped_script_path' -FilesPreview {1}"

$help_cat_cmd = ''
if (Get-Command -Name 'bat' -All -ErrorAction SilentlyContinue) {
  $help_cat_cmd = '| bat --color=always --language help --style=plain'
}

$help_cmd = @"
Write-Output '
  Preview window keys:
    ctrl-^: Toggle preview
    ctrl-/: Toggle preview position
    shift-up: Preview up
    shift-down: Preview down
    alt-up: Preview page up
    alt-down: Preview page down

  Preview modes:
    alt-v: PR details (default)
    alt-d: PR code changes (delta when available)
    alt-g: Status and names of changed files

  PR actions:
    enter: Select PR
    ctrl-d: Display PR details
    ctrl-o: Open PR in browser
    ctrl-s: Checkout PR

  Navigation:
    ctrl-f: Filter PRs
    alt-n: Load next page
    alt-f: Go first
    alt-l: Go last
    alt-c: Clear query
' $help_cat_cmd
"@

$commond_options = @(
  '--bind', 'alt-c:clear-query',
  '--bind', 'ctrl-l:change-preview-window(down,wrap-word|hidden|)',
  '--bind', 'ctrl-/:change-preview-window(down,wrap-word|hidden|)',
  '--bind', 'alt-up:preview-page-up,alt-down:preview-page-down',
  '--bind', 'shift-up:preview-up,shift-down:preview-down',
  '--bind', 'ctrl-^:toggle-preview',
  '--bind', 'ctrl-s:toggle-sort',
  '--bind', 'alt-f:first',
  '--bind', 'alt-l:last',
  '--cycle',
  '--ansi',
  '--input-border=rounded',
  '--no-multi',
  '--with-shell', $pwsh,
  '--accept-nth', '{1}'
)

if ($Display) {
  $display_height = if ($IsWindows -or ($env:OS -eq 'Windows_NT')) { '99%' } else { '100%' }
  $commond_options += @('--height', $display_height)
}

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
    --header 'esc: No filter' `
    --no-multi `
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
    $page_size = 30
    $pipe_cmd = "$Cmd --limit $page_size | Where-Object { `$_.Trim() }"
    $next_page_cmd = "$Cmd --limit ([int]`$env:FZF_TOTAL_COUNT + $page_size) | Where-Object { `$_.Trim() }"
    $env:GH_FORCE_TTY = '100%'
    [string[]] $selected = fzf `
      --bind "start:reload:$pipe_cmd" `
      --bind "alt-n:reload-sync:$next_page_cmd" `
      --bind 'ctrl-o:execute-silent:gh pr view {1} --web' `
      --bind "alt-h:preview:$help_cmd" `
      --bind "alt-v:change-preview:$preview" `
      --bind "alt-d:change-preview:$diff_preview" `
      --bind "alt-g:change-preview:$files_preview" `
      --header 'alt-h: Help | alt-v: Details | alt-d: Diff | alt-g: Files | alt-n: Next page | ctrl-f: Filter' `
      --expect="$fzf_expect_keys" `
      --header-border 'rounded' `
      --header-lines '2' `
      --header-lines-border 'bottom' `
      --track `
      --id-nth '1' `
      --prompt "$Prompt" `
      --preview "$preview" `
      --preview-window '50%,wrap-word' `
      --preview-border 'rounded' `
      @commond_options

    if ($selected.Length -eq 0) {
      exit
    }

    if ($selected[0] -eq 'ctrl-f') {
      return select_filter
    }

    if ($delegate_output) {
      Write-Output @selected
      return
    }

    switch ($selected[0]) {
      'ctrl-s' { return gh pr checkout $selected[1] }
      'ctrl-d' { return gh pr view $selected[1] }
      default { return $selected[1] }
    }
  } finally {
    $env:GH_FORCE_TTY = $OG_GH_FORCE_TTY
  }
}

show_prs
