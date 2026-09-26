#!/usr/bin/env pwsh

# Cross platform clipboard-copy helper
#
# Dependencies
# Windows: `Win32Yank` or `pasteboard` package
# Linux: `xsel`. Install xsel from your package manager e.g. `sudo apt install xsel`

# About variables: See detection script

[CmdletBinding()]
Param(
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
  $InitialCodePage = ''
  $InitialOutputEncoding = $OutputEnconding
  $InitialConsoleEnconding = [Console]::OutputEncoding
  $RunningOnWindows = $IsWindows -or ($env:IS_WINDOWS -eq 'true')
  if ($RunningOnWindows) {
    $InitialCodePage = ((chcp) -Split ':')[1].Trim()
    # Set Code page for windows
    chcp 65001 > $null
  }

  # Set UTF-8 formatting when setting text with special characters
  $OutputEncoding = [Console]::OutputEncoding = New-Object System.Text.Utf8Encoding
  $to_clipboard_list = [System.Collections.Generic.List[string]]::new()
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
  try {
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
    #
    # This could use Set-Clipboard cmdlet but let's align to native behavior
    # on each platform. `Set-Clipboard` is always a fallback or can be used directly
    # instead of this utility.

    if ($IsWindows -or ($env:OS -eq 'Windows_NT')) {
      if (Get-Command -Name 'win32yank' -ErrorAction SilentlyContinue) {
        $to_clipboard_list | win32yank -i
        <# Action to perform if the condition is true #>
      } elseif (Get-Command -Name 'pbcopy' -ErrorAction SilentlyContinue) {
        $to_clipboard_list | pbcopy
      } else {
        Set-Clipboard -Value $to_clipboard_list
      }
    } elseif ("${env:IS_TERMUX}" -eq 'true' ) {
      # WARN: If this ever happens... cry ToT
      termux-clipboard-set @to_clipboard_list
    } elseif ($IsMacos) {
      try {
        $to_clipboard_list | pbpcopy
      } catch {
        # Can this happen?
        Set-Clipboard -Value $to_clipboard_list
      }
    } elseif ($IsLinux) {
      if ("$WAYLAND_DISPLAY") {
        $to_clipboard_list | wl-copy --foreground --type text/plain
      } elseif (("$DISPLAY") -and (Get-Command -Name 'xsel' -ErrorAction SilentlyContinue)) {
        $to_clipboard_list | xsel -i -b
      } elseif (("$DISPLAY") -and (Get-Command -Name 'xclip' -ErrorAction SilentlyContinue)) {
        $to_clipboard_list | xclip -i -selection clipboard
      } else {
        Set-Clipboard -Value $to_clipboard_list
      }
    } else {
      Set-Clipboard -Value $to_clipboard_list
    }
  } finally {
    # Recover console encoding on exit
    $OutputEncoding = $InitialOutputEncoding
    [Console]::OutputEncoding = $InitialConsoleEnconding
    if ($RunningOnWindows) {
      chcp.com $InitialCodePage > $null
    }
  }
}
