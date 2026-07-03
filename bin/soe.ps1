#!/usr/bin/env pwsh

[CmdletBinding()]
Param(
  [Parameter(ValueFromPipeline = $true)]
  [string] $Content
)

Begin {
  if (-not $MyInvocation.ExpectingInput) {
    exit
  }

  $temp = ''
  try {
    $temp = (New-TemporaryFile).FullName
  } catch {
    $temp = [System.IO.Path]::GetTempFilename()
  }

  $writer = [System.IO.StreamWriter]::new($temp, $false, [System.Text.UTF8Encoding]::new($false))
}

Process {
  if ($Content -is [String]) {
    $writer.WriteLine($Content)
  }
}

End {
  try {
    $writer.Close()
    $writer.Dispose()

    $editor = if ($env:PREFERRED_EDITOR) { $env:PREFERRED_EDITOR }
              elseif ($env:EDITOR) { $env:EDITOR }
              elseif ($env:VISUAL) { $env:VISUAL }
              else { 'vim' }

    & $editor $temp

    Get-Content -LiteralPath $temp -Encoding utf8NoBOM -ErrorAction SilentlyContinue
  } finally {
    if (Test-Path -LiteralPath $temp -PathType Leaf -ErrorAction SilentlyContinue) {
      Remove-Item -LiteralPath $temp -ErrorAction SilentlyContinue
    }
  }
}
