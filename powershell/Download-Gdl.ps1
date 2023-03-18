
<#
.SYNOPSIS
  Wrapper script for gallery-dl to list links for download.

.DESCRIPTION
  Wrapper script that will allow passing multiple urls to gallery-dl.
  It accepts strings from a pipeline, an array of strings or it will open a temporal buffer
  in which all links can be listed and it will process the urls when the buffer closes.
  The order of priority is pipeline > argument > temporal buffer.

.PARAMETER ProgressBar
  Display a progress bar that updates a links are downloaded by gallery-dl.

.PARAMETER OmitUrl
  Omit printing the message 'Downloading' with the url on the terminal.

.PARAMETER EditorName
  Name of the editor to open. It needs to be available in $env:PATH

.PARAMETER UrlsToDownload
  Array of strings to be process by the script instead of opening a file to add them manually.

.PARAMETER StringUrl
  String obtain from a pipeline. All strings will be stored and processed at the end.

.INPUTS
  String object from pipeline.

.OUTPUTS
  Script does not produce any output. It is meant to be used as last element in pipeline.

.EXAMPLE
  Download-Gld

.EXAMPLE
  Download-Gld -ProgressBar

.EXAMPLE
  Download-Gld -OmitUrl

.EXAMPLE
  @('url1', '$url2') | Download-Gld

.EXAMPLE
  Download-Gld -UrlsToDownload @('url1', '$url2') -ProgressBar

.NOTES
  Script respects the EDITOR environment variable. If not present if defaults to notepad.exe.
  If the -Help flag is present, it will be prioritized over the other arguments.

#>

Param (
  # Add Progress Bar
  [Switch] $ProgressBar,

  # Do not print the download $url message in the console
  [Switch] $OmitUrl,

  # Display help message
  [Switch] $Help,

  # Editor to use when opening temporal buffer
  [String] $EditorName,

  # String url from pipe
  [Parameter(ValueFromPipeline = $true)]
  [System.Object] $StringUrl,

  # Array of strings to download
  [AllowNull()]
  [String[]] $UrlsToDownload
)

Begin {

  if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host -ForegroundColor Red "This script only works on powershell 7 or above."
      exit 1
  }

  if (-not (Get-Command 'gallery-dl' -errorAction SilentlyContinue)) {
    Write-Host -ForegroundColor Red "gallery-dl not found. Please install it and add it to your path to continue."
      exit 1
  }

  if ($Help) {
    Write-Host "
      Wrapper scritp for gallery-dl

      Open a temporal buffer to list all the urls. Once closed,
      the script will feed the urls to gallery-dl to download them.

      Flags:

      -ProgressBar           > Display a progress bar.

      -OmitUrl               > Do not print messages with the urls
                               in the terminal.

      -Help                  > Print this message.
      "
      exit 0
  }

  # Important declarations 
  $instructions = @'
# Paste your urls in this file, save it and close it.
# Empty lines or lines starting with '#' will be ignored.
# Only valid urls will be processed.

'@

  $editor = if ($EditorName) { $EditorName } elseif ($env:EDITOR) { $env:EDITOR } else { notepad.exe }
  $tempFile = [PSCustomObject] @{ FullName = '' }
  $editorArgs = @()
  $proc = $null
  $lines = $null
  $linesRaw = $null
  $total = 0
  $progress = 0
  $progressMessage = "Download progress..."
  $stringsFromPipe = @()
  $stringsFromArgs = if ($UrlsToDownload) { $UrlsToDownload } else { @() }
}

Process {
  if ( $StringUrl -is [String] ) {
    $stringsFromPipe += $StringUrl
  }
}

End {
  try {

    if ($stringsFromPipe) {
      $linesRaw = $stringsFromPipe
    } elseif ($stringsFromArgs) {
      $linesRaw = $stringsFromArgs
    } else {
      # Open buffer to get strings
      Write-Output "Opining temporal file... Waiting for file to be closed!"

      $tempFile = New-TemporaryFile
      $instructions >> $tempFile
      $editorArgs += $tempFile.FullName

      if ( $editor -Like '*vim' ) {
        $editorArgs += '+'
      }

      $proc = Start-Process $editor -NoNewWindow -PassThru -ArgumentList $editorArgs
      $proc.WaitForExit()

      $proc = $null

      $linesRaw = Get-Content $tempFile.FullName
    }

    Write-Output "Start processing with gallery-dl..."

    $lines = $linesRaw | Where {
      # Get rid of spaces
      $url = $_.Trim()

      # Omit empty lines
      if (-Not $url) {
        return
      }

      # Omit comments
      if ("$url" -Like '#*') {
        return
      }

      $url = [System.Web.HttpUtility]::UrlDecode($url)

      try	{
        $request = [System.Net.WebRequest]::Create($url)
        $request.Method = 'HEAD'
        $response = $request.GetResponse()
        $httpStatus = $response.StatusCode
        $urlIsValid = ($httpStatus -eq 'OK')
        # $tryError = $null
        $response.Close()

        return "$url"
      }	catch [System.Exception] {
        $httpStatus = $null
        # $tryError = $_.Exception
        $urlIsValid = $false;
        Write-Host -ForegroundColor Red "$url is not a valid url"
      }
    }

    $total = $lines.Length
    $progress = if ($total -eq 0) { 100 } else { 0 }
    $progressMessage = "Download progress..."

    $lines | % {
        $i = 0
          if ($ProgressBar) {
            Write-Progress -Activity "$progressMessage" -Status "$progress% Complete:" -PercentComplete $progress
              Write-Host ""
          }
    } {
      if (-Not $OmitUrl) {
        Write-Host "Downloading($progress%): $_"
      }

      try {
        gallery-dl "$_"
      } catch {} # Supress any error from gallery-dl

        $i++
        $progress = ($i * 100) / $total
        $progress = [Math]::Round($progress, 2)

        if ($ProgressBar) {
          Write-Progress -Activity "$progressMessage" -Status "$progress% Complete:" -PercentComplete $progress
            Start-Sleep -Milliseconds 250
        }

        Write-Host ""
      }

      if ($ProgressBar) {
        Write-Progress -Activity "$progressMessage" -Status "$progress% Complete:" -PercentComplete $progress
      }

      Write-Host "`nDownload process has finished!"

      if (Test-Path -Path $tempFile.FullName) {
        Write-Output "`nDisposing temporal file"
        Remove-Item $tempFile.FullName
      }

  } catch {
    Write-Host "Script has ended unexpectedly...`n"

    if (Test-Path -Path $tempFile.FullName) {
      Write-Host "Cleaning..."
      Remove-Item $tempFile.FullName
    }

    Write-Host "Done..."
  }
}

