#!/usr/bin/env pwsh

[CmdletBinding()]
Param(
  # Start fullscreen
  [Switch] $Fullscreen = $false,
  # Query to search
  [Parameter(ValueFromRemainingArguments = $true, position = 0 )]
  [String[]] $QueryArgs = @()
)

$fzf_args = [System.Collections.Generic.List[string]]::new()

if ($Fullscreen) {
  $fzf_args.Add('--height')
  $fzf_args.Add('99%')
  $fzf_args.Add('--bind')
  $fzf_args.Add('ctrl-/:change-preview-window(right|hidden|)')
  $fzf_args.Add('--preview-window')
  $fzf_args.Add('+{2}-/2,top,60%,wrap')

  if ($IsWindows -or ($env:OS -eq 'Windows_NT')) {
    # Bug in fzf making fullscreen
    # not recognizing ctrl-/ or ctrl-^
    $fzf_args.Add('--height')
    $fzf_args.Add('99%')
  } else {
    $fzf_args.Add('--height')
    $fzf_args.Add('100%')
  }
} else {
  $fzf_args.Add('--height')
  $fzf_args.Add('80%')
  $fzf_args.Add('--bind')
  $fzf_args.Add('ctrl-/:change-preview-window(down|hidden|)')
  $fzf_args.Add('--preview-window')
  $fzf_args.Add('+{2}-/2,right,60%,wrap')
}

# Path to search files in
$location = if ($QueryArgs[0]) { $QueryArgs[0] } else { '.' }
# Query to pass to fzf
$query = $QueryArgs[1..$QueryArgs.length]
$pattern = '.'
$editor = if ($env:PREFERRED_EDITOR) { $env:PREFERRED_EDITOR }
  elseif ($env:EDITOR) { $env:EDITOR }
  else { 'vim' }
# env variable for user config location
# $user_conf_path = if ($env:user_conf_path) {
#   $env:user_conf_path
# } else { "$HOME/.usr_conf" }

# Detect native path separator
# $dirsep = if ($IsWindows -or ($env:OS -eq 'Windows_NT')) { '\' } else { '/' }
if ($PSVersionTable.PSVersion -gt [version]'7.0.0') {
  $pwsh_cmd = 'pwsh'
} else {
  $pwsh_cmd = 'powershell'
}

$history_location = if ($env:FZF_HIST_DIR) {
  $env:FZF_HIST_DIR
} else {
  "$HOME/.cache/fzf-history"
}
# For fzf --history we need to use forward slashes even on windows
$history_file = "$history_location/fuzzy-edit" -Replace '\\', '/'
# Ensure history location exists
New-Item -Path $history_location -ItemType Directory -ErrorAction SilentlyContinue

$FED_RG_ARGS = if ($env:FED_RG_ARGS) { $env:FED_RG_ARGS } else { '' }
$FED_FZF_ARGS = if ($env:FED_FZF_ARGS) { $env:FED_FZF_ARGS } else { '' }

# If location is not a directory
# set it as the pattern and search from the home directory
if (-not (Test-Path -LiteralPath $location -PathType Container -ErrorAction SilentlyContinue)) {
  $pattern = "$location"
  $location = "$HOME"
}

$location = if ($location -eq '~') { $HOME } else { $location }
if ("$location" -like '~*') {
  $location = $HOME + $location.Substring(1)
}

# files command assumes fd
$files_cmd = "fds --color=always --path-separator '/' -L -tf '$pattern'"

# Set grep command
if (Get-Command -Name 'rg' -All) {
  $grep_cmd = "rg --with-filename --line-number --color=always $FED_RG_ARGS {q}"
} else {
  # grep -h -n --color=always -R
  $grep_cmd = "grep --with-filename --line-number --color=always --dereference-recursive $FED_RG_ARGS {q}"
}

$bat_style = if ($env:BAT_STYLE) { $env:BAT_STYLE } else { 'numbers' }
# Preview window command
$preview_cmd = "
  `$FILE = {1}
  `$LINE = {2}
  `$NUMBER = if (-Not (`$LINE.Trim())) { '0' } else { `$LINE }

  # set preview command
  if (Get-Command -All -Name 'bat' -ErrorAction SilentlyContinue) {
    bat --style=$bat_style --color=always --pager=never --highlight-line=`$NUMBER -- `$FILE
  } else {
    Get-Content `$FILE
  }
"

$fzf_args.AddRange([string[]]@(
  '--ansi', '--cycle', '--multi',
  '--bind', 'alt-a:select-all',
  '--bind', 'alt-c:clear-query',
  '--bind', 'alt-d:deselect-all',
  '--bind', 'alt-f:first',
  '--bind', 'alt-l:last',
  '--bind', 'alt-up:preview-page-up,alt-down:preview-page-down',
  '--bind', 'ctrl-^:toggle-preview',
  '--bind', 'ctrl-s:toggle-sort',
  '--bind', 'ctrl-f:unbind(change,ctrl-f)+change-prompt(Select> )+enable-search+clear-query+rebind(ctrl-r,alt-r)',
  '--bind', 'shift-up:preview-up,shift-down:preview-down',
  '--bind', "start:unbind(change)",
  '--bind', "alt-r:reload($files_cmd)",
  '--bind', "change:reload:$grep_cmd",
  '--bind', "ctrl-r:unbind(ctrl-r,alt-r)+change-prompt(Search> )+disable-search+reload($grep_cmd)+rebind(change,ctrl-f)",
  '--delimiter', ':',
  '--header', "Search in: $location",
  "--history=$history_file",
  '--input-border',
  '--layout=reverse',
  '--min-height', '20', '--border',
  '--preview', $preview_cmd,
  '--prompt', 'Select> ',
  '--with-shell', "$pwsh_cmd -NoLogo -NonInteractive -NoProfile -Command"
))

if ($query) {
  $fzf_args.Add('--query')
  $fzf_args.Add("$query")
}

foreach ($farg in ($FED_FZF_ARGS -Split ' ')) {
  if ($farg.Trim()) {
    $fzf_args.Add($farg.Trim())
  }
}

$selection = $null

try {
  # NOTE: Windows workaround
  # Need to push location to force fd to use relative paths
  # Absolute paths break preview due to drive letter
  # containing a colon ':'.
  # Rather than creating a more robust preview, I'm pulling
  # of a hack here. Sorry whosoever looks at this.
  Push-Location -LiteralPath $location *> $null

  if (($IsWindows -or ($OS -eq 'Windows_NT')) -and (Get-Command -Name 'With-UTF8' -All -ErrorAction SilentlyContinue)) {
    # Wrap in With-UTF8 to fix file names
    $selection = With-UTF8 {
      # NOTE: `selection` here belongs to its own
      # scope and we need to return the value from it.
      $selection = $files_cmd | Invoke-Expression |
        fzf @fzf_args |
        ForEach-Object { ($_ -Split ':')[0] } |
        Sort-Object -Unique
      return $selection
    }
  } else {
    $selection = $files_cmd | Invoke-Expression |
      fzf @fzf_args |
      ForEach-Object { ($_ -Split ':')[0] } |
      Sort-Object -Unique
  }

  if (-not $selection) {
    return
  }

  & "$editor" $selection
} finally {
  Pop-Location *> $null
}

