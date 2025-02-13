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

function Get-LaunchCommand () {
  # Windows temporary file requires additional quotes around template for '+f'
  $TEMP_FILE = if ($IsWindows -or ($env:OS -eq 'Windows_NT')) { '"{+f}"' } else { '{+f}' }
  $editor = $null
  $editorOptions = ''

  # HACK to check to see if we're running under Visual Studio Code.
  # If so, reuse Visual Studio Code currently open windows:
  if ($null -ne $env:VSCODE_PID) {
    $editor = 'code'
    $editorOptions += ' --reuse-window'
  }
  else {
    $editor = if ($env:PREFERRED_EDITOR) { $env:PREFERRED_EDITOR }
      elseif ($env:VISUAL) { $env:VISUAL }
      elseif ($env:EDITOR) { $env:EDITOR }
      else { 'nvim' }
  }
  if (-not [string]::IsNullOrEmpty($env:PSFZF_EDITOR_OPTIONS)) {
    $editorOptions += ' ' + $env:PSFZF_EDITOR_OPTIONS
  }

  if ($editor -match '[gn]?vi[m]?') {
    return @"
      if (`$env:FZF_SELECT_COUNT -eq 0) {
        `$file = {1}
        `$line = {2}
        if (`$line) {
          $editor $editorOptions `$file +`$line     # No selection. Open the current line in Vim.
        } else {
          $editor $editorOptions `$file
        }
      } else {
        # Ensure all entries match the errorfile format of vim
        `$parsed_file = New-TemporaryFile
        Get-Content $TEMP_FILE | ForEach-Object {
          `$items = `$_ -Split ':'
          if (`$items[1]) {
            `$_
          } else {
            "`$_" + ':1:  -'
          }
        } | Out-File -Encoding ASCII `$parsed_file.FullName
        $editor $editorOptions +cw -q `$parsed_file.FullName  # Build quickfix list for the selected items.
      }
"@
  } elseif ($editor -eq 'code' -or $editor -eq 'code-insiders' -or $editor -eq 'codium') {
    return @"
      if (`$env:FZF_SELECT_COUNT -eq 0) {
        `$file = {1};
        `$line = {2};
        $editor $editorOptions --goto """`${file}:`${line}"""
      } else {
        # Not possible to open multiple files on a specific line
        # so call them one by one with --goto
        Get-Content $TEMP_FILE | ForEach-Object {
          `$file, `$line, `$ignore = `$_ -Split ':';
          $editor $editorOptions --goto """`${file}:`${line}"""
        }
      }
"@
  } elseif ($editor -eq 'nano') {
    return @"
      if (`$env:FZF_SELECT_COUNT -eq 0) {
        $editor $editorOptions +{2} {1}    # Lanunch nano on current line
      } else {
        `$FileList = Get-Content $TEMP_FILE | ForEach-Object {
          `$files = [System.Collections.Generic.List[string]]::new()
        } {
          `$file, `$ignore = `$_ -Split ':';
          [void]`$files.Add("""`$file""");
        } { `$files }
        $editor $editorOptions @FileList
      }
"@
  } else {
    # TODO: Handle case for nano
    return @"
      if (`$env:FZF_SELECT_COUNT -eq 0) {
        $editor $editorOptions {1}
      } else {
        `$FirstFile = Get-Content -TotalCount 1 $TEMP_FILE | ForEach-Object {
          `$file, `$ignore = `$_ -Split ':';
          """`$file"""
        }
        $editor $editorOptions "`$FirstFile"
      }
"@
  }
}

$OPENER = Get-LaunchCommand

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

try {
  # Push into directory to avoid long file names
  Push-Location -LiteralPath "$txt" *> $null

  # Search files
  $find_files_cmd | Invoke-Expression |
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
      --bind 'ctrl-f:unbind(change,ctrl-f)+change-prompt(Files> )+enable-search+clear-query+rebind(ctrl-r,alt-r)' `
      --bind 'ctrl-s:toggle-sort' `
      --bind 'shift-up:preview-up,shift-down:preview-down' `
      --bind 'start:unbind(change)' `
      --bind "alt-r:reload($find_files_cmd)" `
      --bind "change:reload:$sleepCmd $grep_command" `
      --bind "ctrl-o:execute:$OPENER" `
      --bind "enter:become:$OPENER" `
      --bind "ctrl-r:unbind(ctrl-r,alt-r)+change-prompt(Search> )+disable-search+reload($grep_command)+rebind(change,ctrl-f)" `
      --delimiter : `
      --header 'ctrl-f: File selection (reload alt-r) | ctrl-r: Search mode' `
      --input-border `
      --preview-window '+{2}-/2,wrap' `
      --preview "$preview_cmd" `
      --prompt 'Files> ' `
      --with-shell "$pwsh_cmd" `
      @Query
  
} finally {
  # Recover location
  Pop-Location *> $null
}

