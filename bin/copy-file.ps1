#!/usr/bin/env pwsh

# Cross platform "copy file(s) to clipboard" helper.
#
# Unlike clip-copy.ps1 (which copies text content), this copies the FILE OBJECT
# itself onto the system clipboard so it can be pasted into a file manager
# (Explorer, Finder, Nautilus, Dolphin, ...). Directories are supported too.
#
# Usage:
#   copy-file.ps1 C:\path\to\file
#   copy-file.ps1 C:\path\to\directory
#   'C:\path\to\file' | copy-file.ps1
#
# Platforms & native utilities used:
#   Windows : Set-Clipboard -LiteralPath (CF_HDROP)
#   macOS   : osascript "set the clipboard to POSIX file"
#   Linux   : wl-copy / xclip (text/uri-list or x-special/gnome-copied-files)
#
# About the IS_* variables: see the `detection` script.

[CmdletBinding()]
Param(
  [Parameter(ValueFromRemainingArguments = $true, Position = 0)]
  [String[]]
  $RegularInput = @(),
  [Parameter(
    ValueFromPipeline = $true,
    ValueFromPipelineByPropertyName = $true
  )]
  [String[]]
  $PipeInput = @()
)

Begin {
  $paths = New-Object System.Collections.Generic.List[string]
}

Process {
  # Accept paths from the pipeline (stdin).
  foreach ($p in $PipeInput) {
    if ($p) { $paths.Add($p) }
  }
}

End {
  # ...and from positional arguments.
  foreach ($p in $RegularInput) {
    if ($p) { $paths.Add($p) }
  }

  if ($paths.Count -eq 0) {
    Write-Error "copy-file: no path provided"
    exit 1
  }

  # 1. Validate and resolve every input to an absolute path (files or dirs).
  $resolved = New-Object System.Collections.Generic.List[string]
  foreach ($p in $paths) {
    if (-not (Test-Path -LiteralPath $p)) {
      Write-Error "copy-file: no such file or directory: $p"
      exit 1
    }
    $resolved.Add((Resolve-Path -LiteralPath $p).ProviderPath)
  }

  $RunningOnWindows = $IsWindows -or ($env:OS -eq 'Windows_NT') -or ($env:IS_WINDOWS -eq 'true')

  # 2. Dispatch to the native utility for the detected platform.
  if ($RunningOnWindows) {
    # Put the file object(s) on the clipboard as a file drop list (CF_HDROP),
    # paste-able in Explorer. PowerShell 7's Set-Clipboard only handles text,
    # so use the WinForms clipboard API. SetFileDropList requires an STA
    # thread, which PowerShell 7 is not by default, so run it in an STA
    # runspace. (Windows PowerShell 5.1's `Set-Clipboard -LiteralPath` also
    # works and is what the bash sibling shells out to.)
    $rs = [runspacefactory]::CreateRunspace()
    $rs.ApartmentState = 'STA'
    $rs.ThreadOptions = 'ReuseThread'
    $rs.Open()
    $worker = [powershell]::Create()
    $worker.Runspace = $rs
    [void]$worker.AddScript({
        param($files)
        Add-Type -AssemblyName System.Windows.Forms
        $col = New-Object System.Collections.Specialized.StringCollection
        foreach ($f in $files) { [void]$col.Add($f) }
        [System.Windows.Forms.Clipboard]::SetFileDropList($col)
      }).AddArgument($resolved.ToArray())
    try {
      $worker.Invoke()
    } finally {
      $worker.Dispose()
      $rs.Close()
    }

  } elseif ($IsMacOS -or ($env:OSTYPE -like 'darwin*')) {
    # AppleScript can hold a list of POSIX files on the clipboard.
    $items = ($resolved | ForEach-Object {
        $esc = $_ -replace '\\', '\\' -replace '"', '\"'
        "POSIX file `"$esc`""
      }) -join ', '
    $script = if ($resolved.Count -gt 1) { "set the clipboard to {$items}" } else { "set the clipboard to $items" }
    osascript -e $script

  } elseif ($IsLinux -or ($env:OSTYPE -like 'linux*')) {
    # Build a file:// URI list. GNOME-family file managers read
    # x-special/gnome-copied-files; everything else gets text/uri-list.
    $uris = $resolved | ForEach-Object {
      $bytes = [System.Text.Encoding]::UTF8.GetBytes($_)
      $sb = New-Object System.Text.StringBuilder
      foreach ($b in $bytes) {
        $ch = [char]$b
        if ($ch -match '[a-zA-Z0-9/._~-]') { [void]$sb.Append($ch) }
        else { [void]$sb.AppendFormat('%{0:X2}', $b) }
      }
      "file://$($sb.ToString())"
    }

    $desktop = "$env:XDG_CURRENT_DESKTOP"
    if ($desktop -match 'GNOME|Unity|Cinnamon|MATE|Pantheon|Budgie') {
      $target = 'x-special/gnome-copied-files'
      $payload = "copy`n" + ($uris -join "`n")
    } else {
      $target = 'text/uri-list'
      $payload = ($uris -join "`n")
    }

    if ($env:WAYLAND_DISPLAY -and (Get-Command wl-copy -ErrorAction SilentlyContinue)) {
      $payload | wl-copy --type $target
    } elseif ($env:DISPLAY -and (Get-Command xclip -ErrorAction SilentlyContinue)) {
      $payload | xclip -i -selection clipboard -t $target
    } else {
      Write-Error "copy-file: need wl-copy (Wayland) or xclip (X11) to copy files on Linux"
      exit 1
    }

  } else {
    Write-Error "copy-file: unsupported platform"
    exit 1
  }
}
