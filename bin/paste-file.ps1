#!/usr/bin/env pwsh

# Cross platform "paste file(s) from clipboard" helper.
#
# The inverse of copy-file.ps1: it reads the FILE OBJECT(S) currently on the
# system clipboard and writes them to disk. Files and directories are supported.
#
# Destination (optional, from the first positional argument or from the pipeline):
#   - none / a directory : files are written into that directory (default: CWD),
#                          keeping their original names.
#   - a filename whose parent directory exists : the single clipboard file is
#                          written under that name.
#   - a target that already exists : you are warned and asked to confirm before
#                          overwriting (use -Force to skip the prompt).
#
# Usage:
#   paste-file.ps1                 # paste into the current directory
#   paste-file.ps1 C:\Users\me\Downloads
#   paste-file.ps1 .\renamed.txt   # paste the single clipboard file under a new name
#   'C:\Users\me\Downloads' | paste-file.ps1
#
# Platforms & native utilities used:
#   Windows : [System.Windows.Forms.Clipboard]::GetFileDropList() (STA runspace)
#   macOS   : osascript (NSPasteboard file URLs)
#   Linux   : wl-paste / xclip (x-special/gnome-copied-files or text/uri-list)
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
  $PipeInput = @(),
  [switch]
  $Force
)

Begin {
  $piped = New-Object System.Collections.Generic.List[string]
}

Process {
  foreach ($p in $PipeInput) {
    if ($p) { $piped.Add($p) }
  }
}

End {
  $RunningOnWindows = $IsWindows -or ($env:OS -eq 'Windows_NT') -or ($env:IS_WINDOWS -eq 'true')

  # --- clipboard readers: each returns an array of local, absolute paths -------

  function Get-WindowsClipboardFiles {
    # GetFileDropList requires STA; PowerShell 7 defaults to MTA, so run it in
    # a dedicated STA runspace (same pattern as copy-file.ps1).
    $rs = [runspacefactory]::CreateRunspace()
    $rs.ApartmentState = 'STA'
    $rs.ThreadOptions = 'ReuseThread'
    $rs.Open()
    $worker = [powershell]::Create()
    $worker.Runspace = $rs
    [void]$worker.AddScript({
        Add-Type -AssemblyName System.Windows.Forms
        $list = [System.Windows.Forms.Clipboard]::GetFileDropList()
        $out = @()
        foreach ($f in $list) { $out += $f }
        , $out
      })
    try {
      return @($worker.Invoke() | ForEach-Object { $_ })
    } finally {
      $worker.Dispose()
      $rs.Close()
    }
  }

  function Get-MacClipboardFiles {
    $jxa = @'
ObjC.import('AppKit');
var pb = $.NSPasteboard.generalPasteboard;
var urls = pb.readObjectsForClassesOptions($.NSArray.arrayWithObject($.NSURL), $());
var out = [];
if (urls && urls.count > 0) {
  for (var i = 0; i < urls.count; i++) {
    var u = urls.objectAtIndex(i);
    if (u.isFileURL) { out.push(ObjC.unwrap(u.path)); }
  }
}
out.join("\n");
'@
    return @($jxa | osascript -l JavaScript 2>$null | Where-Object { $_ })
  }

  function Get-LinuxClipboardFiles {
    $payload = $null
    if ($env:WAYLAND_DISPLAY -and (Get-Command wl-paste -ErrorAction SilentlyContinue)) {
      $types = & wl-paste --list-types 2>$null
      if ($types -contains 'x-special/gnome-copied-files') {
        $payload = & wl-paste --no-newline --type x-special/gnome-copied-files 2>$null
      } elseif ($types -contains 'text/uri-list') {
        $payload = & wl-paste --no-newline --type text/uri-list 2>$null
      }
    } elseif ($env:DISPLAY -and (Get-Command xclip -ErrorAction SilentlyContinue)) {
      $targets = & xclip -selection clipboard -o -t TARGETS 2>$null
      if ($targets -contains 'x-special/gnome-copied-files') {
        $payload = & xclip -selection clipboard -o -t x-special/gnome-copied-files 2>$null
      } elseif ($targets -contains 'text/uri-list') {
        $payload = & xclip -selection clipboard -o -t text/uri-list 2>$null
      }
    }

    $files = @()
    foreach ($line in ($payload -split "`n")) {
      $line = $line.TrimEnd("`r")
      if (-not $line.StartsWith('file://')) { continue }
      $path = $line.Substring('file://'.Length)
      if (-not $path.StartsWith('/')) { $path = '/' + $path.Substring($path.IndexOf('/') + 1) }
      # Percent-decode (byte-wise so UTF-8 sequences reassemble correctly).
      $bytes = New-Object System.Collections.Generic.List[byte]
      for ($i = 0; $i -lt $path.Length; $i++) {
        if ($path[$i] -eq '%' -and $i + 2 -lt $path.Length + 1) {
          $bytes.Add([Convert]::ToByte($path.Substring($i + 1, 2), 16))
          $i += 2
        } else {
          $bytes.Add([byte][char]$path[$i])
        }
      }
      $files += [System.Text.Encoding]::UTF8.GetString($bytes.ToArray())
    }
    return $files
  }

  if ($RunningOnWindows) {
    $sources = @(Get-WindowsClipboardFiles)
  } elseif ($IsMacOS -or ($env:OSTYPE -like 'darwin*')) {
    $sources = @(Get-MacClipboardFiles)
  } elseif ($IsLinux -or ($env:OSTYPE -like 'linux*')) {
    $sources = @(Get-LinuxClipboardFiles)
  } else {
    Write-Error "paste-file: unsupported platform"
    exit 1
  }

  $sources = @($sources | Where-Object { $_ })
  if ($sources.Count -eq 0) {
    Write-Error "paste-file: no files on the clipboard"
    exit 1
  }

  # --- resolve destination -----------------------------------------------------

  # First positional argument, else first piped value, else the current dir.
  $dest = ($RegularInput | Where-Object { $_ } | Select-Object -First 1)
  if (-not $dest) { $dest = ($piped | Where-Object { $_ } | Select-Object -First 1) }
  if (-not $dest) { $dest = (Get-Location).Path }

  if (Test-Path -LiteralPath $dest -PathType Container) {
    $mode = 'dir'
  } else {
    $parent = [System.IO.Path]::GetDirectoryName($dest)
    if (-not $parent) { $parent = '.' }
    if (Test-Path -LiteralPath $parent -PathType Container) {
      $mode = 'file'
    } else {
      Write-Error "paste-file: destination directory does not exist: $parent"
      exit 1
    }
  }

  if ($mode -eq 'file' -and $sources.Count -gt 1) {
    Write-Error "paste-file: clipboard holds $($sources.Count) files but a single filename destination was given: $dest. Pass a directory instead."
    exit 1
  }

  # --- copy --------------------------------------------------------------------

  $exitCode = 0
  foreach ($src in $sources) {
    if (-not (Test-Path -LiteralPath $src)) {
      Write-Error "paste-file: clipboard source no longer exists: $src"
      $exitCode = 1
      continue
    }

    if ($mode -eq 'dir') {
      $target = Join-Path $dest ([System.IO.Path]::GetFileName($src))
    } else {
      $target = $dest
    }

    $srcFull = (Resolve-Path -LiteralPath $src).ProviderPath
    $targetFull = if (Test-Path -LiteralPath $target) { (Resolve-Path -LiteralPath $target).ProviderPath } else { $target }
    if ($srcFull -eq $targetFull) {
      Write-Warning "paste-file: source and destination are the same file, skipping: $target"
      continue
    }

    if (Test-Path -LiteralPath $target) {
      if (-not $Force) {
        # Coerce to a string: Read-Host returns $null at EOF / non-interactive,
        # and "$null -notmatch ..." is itself $null (falsy), which would fall
        # through to an overwrite. Default to "no" unless an explicit yes.
        $ans = "$(Read-Host "paste-file: `"$target`" already exists. Overwrite? [y/N]")".Trim()
        if ($ans -notmatch '^(y|yes)$') {
          Write-Warning "paste-file: skipped $target"
          continue
        }
      }
      if (Test-Path -LiteralPath $target -PathType Container) {
        Remove-Item -LiteralPath $target -Recurse -Force
      }
    }

    try {
      if (Test-Path -LiteralPath $src -PathType Container) {
        Copy-Item -LiteralPath $src -Destination $target -Recurse -Force
      } else {
        Copy-Item -LiteralPath $src -Destination $target -Force
      }
    } catch {
      Write-Error "paste-file: failed to copy ${src}: $_"
      $exitCode = 1
    }
  }

  exit $exitCode
}
