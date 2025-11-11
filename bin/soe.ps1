#!/usr/bin/env pwsh

[CmdletBinding()]
Param(
  # String from pipe
  [Parameter(ValueFromPipeline = $true)]
  [string] $Content
)


Begin {
  $lines = [System.Collections.Generic.List[string]]::new()
  $temp = ''

  try {
    $temp = (New-TemporaryFile).FullName
  } catch {
    $temp = [System.IO.Path]::GetTempFilename()
  }
}

Process {
  if ( $Content -is [String] ) {
    $lines.Add($Content)
  }
}

End {
  try {
    if ($lines.Length -eq 0) {
      exit
    }

    $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllLines($temp, $lines, $Utf8NoBomEncoding)

    nvim $temp

    Get-Content -LiteralPath $temp -Encoding utf8NoBOM -ErrorAction SilentlyContinue
  } finally {
    if (Test-Path -LiteralPath $temp -PathType Leaf -ErrorAction SilentlyContinue) {
      Remove-Item -LiteralPath $temp -ErrorAction SilentlyContinue
    }
  }
}
