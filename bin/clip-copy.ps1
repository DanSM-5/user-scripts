#!/usr/bin/env pwsh

[CmdletBinding()]
param(
  [Parameter(ValueFromRemainingArguments = $true, position = 0)]
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
  # Set UTF-8 formatting when setting text with special characters
  chcp 65001 > $null
  $to_clipboard_list = New-Object System.Collections.ArrayList
}

Process {
  Write-Verbose 'Pipe process'
  # Because we should be able to accept both pipe input and
  # regular input, then lets hold everthing in memory for second,
  # merge the inputs in the list, then pass it to the native binary command
  foreach ($strg in $PipeInput) {
    Write-Verbose "String from pipe: $strg" 
    $null = $to_clipboard_list.Add($strg)
  }
}

End {

  # $value = if ($PipeInput) { $PipeInput } else { $RegularInput }
  # $value = $PipeInput + $RegularInput

  foreach ($strg in $RegularInput) {
    $null = $to_clipboard_list.Add($strg)
  }

  if (-not $to_clipboard_list) {
    exit
  }

  # Cross platform clipboard-copy helper
  # NOTE: only windows from prowershell should ever land here
  # but let the whole structure in case running powershell somewhere else.

  # TODO: requires transformation to accept pipe input
  # This currently hangs

  # This could use Set-Clipboard cmdlet but since that
  # should be available out of the box, then use here a native binary

  if ($IsWindows) {
    With-UTF8 {
      $to_clipboard_list | pbcopy
    }
  } elseif ("${env:IS_TERMUX}" -eq 'true' ) {
    termux-clipboard-set @to_clipboard_list
  } elseif ($IsMacos) {
    pbpcopy @to_clipboard_list
  } elseif ($IsLinux) {
    xsel -ib @to_clipboard_list
  }
}
