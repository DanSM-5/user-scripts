#!/usr/bin/env pwsh

<#
.SYNOPSIS
  Temporary note buffer

.DESCRIPTION
  Open a scratch buffer in the temporary directory of the operative system
  Buffer is meant to be transient, so if you want to save the content
  save the buffer with the command
  :save /path/to/save
  Or better to use `ntxt` instead

.INPUTS
  Command accepts no inputs

.OUTPUTS
  Command produces no outputs

.EXAMPLE
  ntmp

.NOTES
  Consider usage of ntxt and ftxt

#>

$is_windows = $IsWindows -or ($env:OS -eq 'Windows_NT')
$dirsep = if ($is_windows) { '\' } else { '/' }

$temporary = if ($is_windows) { "$env:TEMP\scratch" } else { '/tmp/scratch' }

$editor = if ($env:PREFERRED_EDITOR) { $env:PREFERRED_EDITOR }
  elseif ($env:EDITOR) { $env:EDITOR }
  else { vim }

& $editor "$temporary${dirsep}tmp-$(New-Guid).md"

