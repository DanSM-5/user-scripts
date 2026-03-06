#!/usr/bin/env pwsh

# (r)g (f)zf (v)im
# Script to search interactively with ripgrep using fzf as frontend
# Selected entries will be opened with a valid `EDITOR`. See below for
# available variables and order or precedence.
#
# Toggle fzf functionality for fuzzy match
# Toggle back to make a different query
#
# This module is taken from PSFzf
# Ref: https://github.com/kelleyma49/PSFzf/blob/master/PSFzf.Functions.ps1

$script:FzfLocation = 'fzf'
$script:OverrideFzfDefaults = $null
$script:editorOptions = if ($env:EDITOR_OPTS) { $env:EDITOR_OPTS } else { '' }
$editor = if ($env:PREFERRED_EDITOR) { $env:PREFERRED_EDITOR }
  elseif ($env:EDITOR) { $env:EDITOR }
  elseif ($env:VISUAL) { $env:VISUAL }
  else { 'vim' }

function FindFzf() {
	if ($script:IsWindows) {
		$AppNames = @('fzf-*-windows_*.exe','fzf.exe')
	} elseif ($IsMacOS) {
    $AppNames = @('fzf-*-darwin_*','fzf')
  } elseif ($IsLinux) {
    $AppNames = @('fzf-*-linux_*','fzf')
  } else {
    throw 'Unknown OS'
	}

  # find it in our path:
  $script:FzfLocation = $null
  $AppNames | ForEach-Object {
    if ($null -eq $script:FzfLocation) {
      $result = Get-Command $_ -ErrorAction Ignore
      $result | ForEach-Object {
        $script:FzfLocation = Resolve-Path $_.Source
      }
    }
  }

  if ($null -eq $script:FzfLocation) {
    throw 'Failed to find fzf binary in PATH.  You can download a binary from this page: https://github.com/junegunn/fzf/releases'
  }
}


function open_vim ([string[]] $selections) {
  if ($selections.Length -eq 1) {
    $file, $line, $ignore = $selections -Split ':'
    "$editor $script:editorOptions $file +$line" | Invoke-Expression
  } else {
    $temp_qf = New-TemporaryFile

    try {
      $selections | Out-File -LiteralPath $temp_qf.FullName -Encoding utf8

      ("$editor $script:editorOptions +cw -q " + $temp_qf.FullName) | Invoke-Expression
    } finally {
      Remove-Item -Force -LiteralPath $temp_qf.FullName -ErrorAction SilentlyContinue
    }
  }
}

function open_vscode ([string[]]$selections) {
  # HACK to check to see if we're running under Visual Studio Code.
  # If so, reuse Visual Studio Code currently open windows:
  if ($null -ne $env:VSCODE_PID) {
    $script:editorOptions += ' --reuse-window'
  }

  foreach ($selection in $selections) {
    $file, $line, $ignore = $selection -Split ':'
    "$editor $script:editorOptions --goto '${file}:${line}'" | Invoke-Expression
  }
}

function open_nano ([string[]]$selections) {
  if ($selections.Length -eq 1) {
    $file, $items, $ignore = $selections[0] -Split ':'
    "$editor $script:editorOptions +$line '$file'" | Invoke-Expression
  } else {
    $items = [System.Collections.Generic.List[string]]::new()

    foreach ($selection in $selections) {
      $file = ($selection -Split ':')[0]
      $null = $items.Add($file)
    }

    "$editor $script:editorOptions $items" | Invoke-Expression
  }
}

function open_generic ([string[]]$selections) {
  $items = [System.Collections.Generic.List[string]]::new()

  foreach ($selection in $selections) {
    $file = ($selection -Split ':')[0]
    $null = $items.Add($file)
  }

  "$editor $script:editorOptions $items" | Invoke-Expression
}

function Invoke-PsFzfRipgrep() {
  # TODO: Make $NoEditor work again
  # this function is adapted from https://github.com/junegunn/fzf/blob/master/ADVANCED.md#switching-between-ripgrep-mode-and-fzf-mode
  param([Parameter(Mandatory)]$SearchString, [switch]$NoEditor)

  if (!(Get-Command -Name 'fzf' -ErrorAction SilentlyContinue)) { FindFzf }

  $RFV_RG_ARGS = if ($env:RFV_RG_ARGS) { $env:RFV_RG_ARGS } else { '' }
  $RG_PREFIX = if ($env:RFV_PREFIX_COMMAND) {
    $env:RFV_PREFIX_COMMAND
  } else {
    # "rg --column --line-number --no-heading --color=always --smart-case "
    "rg --column --line-number --no-heading --color=always --smart-case --no-ignore --glob !.git --glob !node_modules --hidden"
  }
  $RG_PREFIX = "$RG_PREFIX $RFV_RG_ARGS "
  $INITIAL_QUERY = $SearchString
  $originalFzfDefaultCommand = $env:FZF_DEFAULT_COMMAND
  # $editor = if ($PREFERRED_EDITOR) { $PREFERRED_EDITOR } elseif ($EDITOR) { $EDITOR } else { nvim }

  try {
    if ($script:IsWindows) {
      $sleepCmd = ''
      $trueCmd = 'cd .'
      # $env:FZF_DEFAULT_COMMAND = "$RG_PREFIX ""$INITIAL_QUERY"""
      # $TEMP_FILE = '"{+f}"'
    }
    else {
      $sleepCmd = 'sleep 0.1;'
      $trueCmd = 'true'
      # $env:FZF_DEFAULT_COMMAND = '{0} $(printf %q "{1}")' -f $RG_PREFIX, $INITIAL_QUERY
      # $TEMP_FILE = '{+f}'
    }

    $RELOAD = "reload:$sleepCmd $RG_PREFIX {q} || $trueCmd"

    [string[]]$selections = & $script:FzfLocation --ansi `
      --header '╱ CTRL-R (Ripgrep mode) ╱ CTRL-F (fzf mode) ╱' `
      --disabled --ansi --multi `
      --cycle `
      --input-border `
      --with-shell 'pwsh -NoLogo -NonInteractive -NoProfile -Command' `
      --bind 'alt-up:preview-page-up,alt-down:preview-page-down' `
      --bind 'ctrl-s:toggle-sort' `
      --bind 'alt-f:first' `
      --bind 'alt-l:last' `
      --bind 'alt-c:clear-query' `
      --bind 'alt-a:select-all' `
      --bind 'alt-d:deselect-all' `
      --bind 'ctrl-^:toggle-preview' `
      --bind 'ctrl-l:toggle-preview' `
      --bind 'ctrl-/:toggle-preview' `
      --bind "start:$RELOAD" `
      --bind "change:$RELOAD" `
      --bind ("ctrl-r:unbind(ctrl-r)+change-prompt" + '(1. 🔎 ripgrep> )' + "+disable-search+reload($RG_PREFIX {q} || $trueCmd)+rebind(change,ctrl-f)") `
      --bind ("ctrl-f:unbind(change,ctrl-f)+change-prompt" + '(2. ✅ fzf> )' + "+enable-search+clear-query+rebind(ctrl-r)") `
      --prompt '1. 🔎 ripgrep> ' `
      --delimiter : `
      --preview 'bat --style=full --color=always --highlight-line {2} {1}' `
      --preview-window '~4,+{2}+4/3,<80(up),wrap-word' `
      --query "$INITIAL_QUERY"

    
    if ($selections.Length -eq 0) {
      exit
    } elseif ($editor -match '[gn]?vi[m]?') {
      open_vim -selections $selections
    } elseif ($editor -eq 'code' -or $editor -eq 'code-insiders' -or $editor -eq 'codium') {
      open_vscode -selections $selections
    } elseif ($editor -eq 'nano') {
      open_nano -selections $selections
    } else {
      open_generic -selections $selections
    }

    # & $script:FzfLocation --ansi `
    #     --color "hl:-1:underline,hl+:-1:underline:reverse" `
    #     --disabled --query "$INITIAL_QUERY" `
    #     --bind "change:reload:$sleepCmd $RG_PREFIX {q} || $trueCmd" `
    #     --bind ("ctrl-f:unbind(change,ctrl-f)+change-prompt" + '( +? fzf> )' + "+enable-search+clear-query+rebind(ctrl-r)") `
    #     --bind ("ctrl-r:unbind(ctrl-r)+change-prompt" + '(?? ripgrep> )' + "+disable-search+reload($RG_PREFIX {q} || $trueCmd)+rebind(change,ctrl-f)") `
    #     --prompt '?? ripgrep> ' `
    #     --delimiter : `
    #     --header '? CTRL-R (Ripgrep mode) ? CTRL-F (fzf mode) ?' `
    #     --preview 'bat --color=always {1} --highlight-line {2}' `
    #     --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' |
    #     ForEach-Object { $results += $_ }

    # # Cleanup the FZF_DEFAULT_COMMAND if no longer used
    # $env:FZF_DEFAULT_COMMAND = $originalFzfDefaultCommand

    # if (-not [string]::IsNullOrEmpty($results)) {
    #     # TODO: Upgrade to support multiple selections
    #     # foreach ($res in $results) {}
    #     $split = $results.Split(':')
    #     $fileList = $split[0]
    #     $lineNum = $split[1]
    #     if ($NoEditor) {
    #         Resolve-Path $fileList
    #     }
    #     else {
    #         $cmd = Get-EditorLaunch -FileList $fileList -LineNum $lineNum
    #         Write-Host "Executing '$cmd'..."
    #         Invoke-Expression -Command $cmd
    #     }
    # }
  } catch {
      Write-Error "Error occurred: $_"
  } finally {
    $env:FZF_DEFAULT_COMMAND = $originalFzfDefaultCommand
  }
}

Invoke-PsFzfRipgrep @args

