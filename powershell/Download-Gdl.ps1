
<#
.SYNOPSIS
  Wrapper script for gallery-dl to list links for download.

.DESCRIPTION
  Wrapper script that will allow passing multiple urls to gallery-dl.
  It accepts strings from a pipeline, an array of strings or it will open a temporal buffer
  in which all links can be listed and it will process the urls when the buffer closes.
  The order of priority is pipeline > argument > temporal buffer.

.PARAMETER DownloadParallel
  Allow splitting the download per domain to download simultaneously.

.PARAMETER FilePath
  Specify path to file with links to download

.PARAMETER EditorName
  Name of the editor to open. It needs to be available in $env:PATH

.PARAMETER UrlsToDownload
  Array of strings to be process by the script instead of opening a file to add them manually.

.PARAMETER StringUrl
  String obtain from a pipeline. All strings will be stored and processed at the end.

.PARAMETER GalleryDlArgs
  Arguments to be passes to gallery-dl.
  Note: On multy thread downlaods the arguments will be passed to each invokation of gallery-dl.
  Note: The argument '-i' is always used internally and if included, both will be passed to gallery-dl.

.INPUTS
  String object from pipeline.

.OUTPUTS
  Script does not produce any output. It is meant to be used as last element in pipeline.

.EXAMPLE
  Download-Gld

.EXAMPLE
  Download-Gld -DownloadParallel -FilePath $HOME/links-to-download.txt

.EXAMPLE
  @("$url1", "$url2", "$url3") | Download-Gld

.EXAMPLE
  Download-Gld -GalleryDlArgs @('-q', '--sleep', '20')

.EXAMPLE
  Download-Gld -UrlsToDownload @("$url1", "$url2") -DownloadParallel

.NOTES
  Script respects the EDITOR environment variable. If not present if defaults to notepad.exe.
  If the -Help flag is present, it will be prioritized over the other arguments.

#>

Param (
  # Allow parallel download per domain
  [Switch] $DownloadParallel,

  # Display help message
  [Switch] $Help,

  # Editor to use when opening temporal buffer
  [String] $EditorName,

  # String url from pipe
  [Parameter(ValueFromPipeline = $true)]
  [System.Object] $StringUrl,

  # Array of strings to download
  [AllowNull()]
  [String[]] $UrlsToDownload,

  # Path to file to download
  [String] $FilePath = '',

  # Arguments for gallery-dl
  [AllowNull()]
  [String[]] $GalleryDlArgs = @()
)

Begin {
  function showHelp () {
    Write-Host "
      Wrapper scritp for gallery-dl

      Open a temporal buffer to list all the urls. Once closed,
      the script will feed the urls to gallery-dl to download them.

      Flags:

        -Help [switch]               > Print this message.

        -DownloadParallel [switch]   > Allow parallel downloads per domain.

        -FilePath [string]           > Path to input file.

        -EditorName [string]         > Name of the editor to open the temporal buffer.

        -UrlsToDownload [string[]]   > Print this message.

        -StringUrl [string]          > Url string from pipeline (pipe only).

        -GalleryDlArgs [string[]]    > Arguments passed to gallery-dl.
    "
  }

  if ($Help) {
    showHelp
    exit 0
  }

  if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host -ForegroundColor Red "This script only works on powershell 7 or above."
    exit 1
  }

  if (-not (Get-Command 'gallery-dl' -errorAction SilentlyContinue)) {
    Write-Host -ForegroundColor Red "gallery-dl not found. Please install it and add it to your path to continue."
    exit 1
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
  $stringsFromPipe = @()
  $stringsFromArgs = if ($UrlsToDownload) { $UrlsToDownload } else { @() }
  $fileToDownload = if ("$FilePath" -and (Test-Path -Path "$FilePath")) { "$FilePath" } else { $null }
}

Process {
  if ( $StringUrl -is [String] ) {
    $stringsFromPipe += $StringUrl
  }
}

End {

  # TODO: Verify is sqlite could have issues with parallel downloads
  # Snipped from https://github.com/github-account1111
  # in thread https://github.com/mikf/gallery-dl/issues/31

  function downloadParallel ([String[]] $links) {
    $links | % {
      $link = New-Object System.Uri $_
      $link.Host
    } | Select-Object -Unique | % {
      $hostName = $_
      $links -match $_ | Start-ThreadJob {
        $perDomainInput = New-TemporaryFile
        $downloadFileName = "$($perDomainInput.FullName)"
        try {
          $input | Out-File "$downloadFileName" -Encoding ascii
          gallery-dl $GalleryDlArgs -i "$downloadFileName"
        } catch {
          Write-Host "An error occurred with a parallel download $hostName"
          Write-Host -ForegroundColor Red $Error[0]
        } finally {
          if (Test-Path -Path $downloadFileName) {
            Remove-Item $downloadFileName -Force
          }
        }
      }
    } | Receive-Job -Wait -AutoRemoveJob
  }

  function downloadNormal ([String[]] $links) {
    $downloadFile = New-TemporaryFile
    $downloadFileName = "$($downloadFile.FullName)"

    try {
      $links | Out-File $downloadFileName -Encoding ascii

      gallery-dl $GalleryDlArgs -i "$downloadFileName"
    } catch {
      Write-Host "An error occurred with the regular download"
      Write-Host -ForegroundColor Red $Error[0]
    } finally {
      # Ensure cleaning file
      if (Test-Path -Path $downloadFileName) {
        Remove-Item $downloadFileName -Force
      }
    }
  }

  try {

    if ($stringsFromPipe) {
      $linesRaw = $stringsFromPipe
    } elseif ($fileToDownload) {
      $linesRaw = Get-Content "$fileToDownload"
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

    if ($DownloadParallel) {
      downloadParallel $lines
    } else {
      downloadNormal $lines
    }

    Write-Host "`nDownload process has finished!"
  } catch {
    Write-Host "Script has ended unexpectedly...`n"
    Write-Host -ForegroundColor Red $Error[0]
  } finally {
    if (Test-Path -Path $tempFile.FullName) {
      Write-Output "`nDisposing temporal file"
      Remove-Item $tempFile.FullName
    }

    Write-Host "Done..."
  }
}

