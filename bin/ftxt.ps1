#!/usr/bin/env pwsh

<#
.SYNOPSIS
  Open text files for read or edit.

.DESCRIPTION
  List of files in the text directory for selection or search.

.INPUTS
  None

.OUTPUTS
  None

.EXAMPLE
  ftxt

.EXAMPLE
  ftxt filename.md

.NOTES
  Cross platform script (windows powershell and pwsh).
  Use `PREFERRED_EDITOR` or `EDITOR` environment variable to configure the text editor to use.
  Use `TXT_LOCATION` to configure the path to the txt directory that will store the text files.
  Use it in conjunction with `ntxt` command to create or open text files.

#>

# Called with arguments
$Query = if ($args) { @('--query', "$args") } else { @() }
# Detect native path separator
$dirsep = if ($IsWindows -or ($env:OS -eq 'Windows_NT')) { '\' } else { '/' }
# Defaults to vim
$editor = if ($env:PREFERRED_EDITOR) { $env:PREFERRED_EDITOR } elseif ($env:EDITOR) { $env:EDITOR } else { 'vim' }
# Defaults to $HOME/prj/txt
$txt = if ($env:TXT_LOCATION) { $env:TXT_LOCATION } else { "${HOME}${dirsep}prj${dirsep}txt" }
# Powershell command
$pwsh_cmd = if ($PSVersionTable.PSVersion -gt [version]'7.0.0') { 'pwsh' } else { 'powershell' }
$pwsh_cmd = "$pwsh_cmd -NoLogo -NonInteractive -NoProfile -Command"

if (-not (Test-Path -PathType Container -Path "$txt" -ErrorAction SilentlyContinue)) {
  Write-Output "No $txt directory, creating..."
  New-Item -Type Directory -Path "$txt" -ErrorAction SilentlyContinue
  return
}

# Find files command
$find_files_cmd = 'fd --color=always --type file .'
# Grep command
$grep_command = 'rg --no-heading --smart-case --with-filename --line-number --color=always {q}'

if ($IsWindows -or ($env:OS -eq 'Windows_NT')) {
  $sleepCmd = ''
} else {
  $sleepCmd = 'sleep 0.1;'
}

$editorOptions = if ($env:EDITOR_OPTS) { $env:EDITOR_OPTS } else { '' }

# Preview window command
$preview_cmd = "
  `$FILE = {1}
  `$LINE = {2}
  `$NUMBER = if (-Not (`$LINE.Trim())) { '0' } else { `$LINE }

  # set preview command
  if (Get-Command -All -Name 'bat' -ErrorAction SilentlyContinue) {
    bat --style='numbers' --color=always --pager=never --highlight-line=`$NUMBER -- `$FILE
  } else {
    Get-Content `$FILE
  }
"

function open_vim ([string[]] $selections) {
  if ($selections.Length -eq 1) {
    $items = $selections -Split ':'
    $file = $items[0]
    $line = $items[1]

    if ($line) {
      "$editor $script:editorOptions $file +$line" | Invoke-Expression
    } else {
      "$editor $script:editorOptions $file" | Invoke-Expression
    }
  } else {
    $temp_qf = New-TemporaryFile

    try {
      foreach ($selection in $selections) {
        $items = $selection -Split ':'
        if ($items[1]) {
          $selection >> $temp_qf.FullName
        } else {
          $items[0] + ':1:  -' >> $temp_qf.FullName
        }
      }

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
    $items = $selection -Split ':'
    $file = $items[0]
    $line = $items[1]
    if ($line) {
      "$editor $script:editorOptions --goto '${file}:${line}'" | Invoke-Expression
    } else {
      "$editor $script:editorOptions '$file'" | Invoke-Expression
    }
  }
}

function open_nano ([string[]]$selections) {
  if ($selections.Length -eq 1) {
    $items = $selections[0] -Split ':'
    $file = $items[0]
    $line = $items[1]
    if ($line) {
      "$editor $script:editorOptions +$line '$file'" | Invoke-Expression
    } else {
      "$editor $script:editorOptions '$file'" | Invoke-Expression
    }
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

try {
  # Push into directory to avoid long file names
  Push-Location -LiteralPath "$txt" *> $null

  # Search files
  [string[]]$selections = $find_files_cmd | Invoke-Expression |
    fzf --height 80% --min-height 20 --border `
      --ansi --cycle --multi `
      --bind 'alt-a:select-all' `
      --bind 'alt-c:clear-query' `
      --bind 'alt-d:deselect-all' `
      --bind 'alt-f:first' `
      --bind 'alt-l:last' `
      --bind 'alt-up:preview-page-up,alt-down:preview-page-down' `
      --bind 'ctrl-/:change-preview-window(down|hidden|)' `
      --bind 'ctrl-^:toggle-preview' `
      --bind 'ctrl-f:unbind(change,ctrl-f)+change-prompt(Narrow> )+enable-search+clear-query+rebind(ctrl-r,alt-r)' `
      --bind 'ctrl-s:toggle-sort' `
      --bind 'shift-up:preview-up,shift-down:preview-down' `
      --bind 'start:unbind(change)' `
      --bind "alt-r:unbind(change,ctrl-f,alt-r)+change-prompt(Files> )+enable-search+clear-query+rebind(ctrl-r)+reload($find_files_cmd)" `
      --bind "change:reload:$sleepCmd $grep_command" `
      --bind "ctrl-r:unbind(ctrl-r)+change-prompt(Search> )+disable-search+reload($grep_command)+rebind(change,ctrl-f,alt-r)" `
      --bind "start:unbind(change,ctrl-f,alt-r)" `
      --delimiter : `
      --header 'ctrl-f: File selection (reload alt-r) | ctrl-r: Search mode' `
      --input-border `
      --preview-window '+{2}-/2,wrap' `
      --preview "$preview_cmd" `
      --prompt 'Files> ' `
      --with-shell "$pwsh_cmd" `
      @Query
 
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
} finally {
  # Recover location
  Pop-Location *> $null
}

