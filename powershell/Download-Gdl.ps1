
<#
.SYNOPSIS
  Wrapper script for gallery-dl to list links for download.

.DESCRIPTION
  Wrapper script that will allow passing multiple urls to gallery-dl.
  The order of priority is pipeline > argument array > argument file > clipboard.
  All ways of passing urls can be used. Priority only affects order of download.
  If no urls are provided, a temporal buffer will open to add the urls.
  All urls will remove empty lines or lines starting with "#".
  It accepts encoded urls.

.PARAMETER DownloadParallel
  Allow splitting the download per domain to download simultaneously.

.PARAMETER FilePath
  Specify path to file with links to download

.PARAMETER EditorName
  Name of the editor to open. It needs to be available in $env:PATH

.PARAMETER ClipBoard
  Get the content of the clipboard to feed gallery-dl. It used Get-ClipBoard cmdlet.

.PARAMETER UrlsToDownload
  Array of strings to be process by the script instead of opening a file to add them manually.

.PARAMETER StringUrl
  String obtain from a pipeline. All strings will be stored and processed at the end.

.PARAMETER VerifyUrls
  Make a HEAD request to test each url. If the request fails, the url will be removed.
  This could remove valid urls if the server blocks the HEAD request for the specific domain.
  Use it with caution.

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
  Download-Gld -EditorName vim

.EXAMPLE
  Download-Gld -DownloadParallel -FilePath $HOME/links-to-download.txt

.EXAMPLE
  @("$url1", "$url2", "$url3") | Download-Gld

.EXAMPLE
  Download-Gld -GalleryDlArgs @('-q', '--sleep', '20') -ClipBoard

.EXAMPLE
  Download-Gld -UrlsToDownload @("$url1", "$url2") -DownloadParallel

.NOTES
  Script respects the EDITOR environment variable. If not present if defaults to notepad.exe.
  If the -Help flag is present, it will be prioritized over the other arguments and script with exit.

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
  [AllowNull()]
  [String] $FilePath = $null,

  # Get the urls from the clipboard
  [Switch] $ClipBoard,

  # Arguments for gallery-dl
  [AllowNull()]
  [String[]] $GalleryDlArgs = @(),

  # Verify each url by doing a HEAD request
  [Switch] $VerifyUrls
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

        -ClipBoard [switch]          > Use the content of the clipboard to get the urls.

        -UrlsToDownload [string[]]   > Print this message.

        -StringUrl [string]          > Url string from pipeline (pipe only).

        -GalleryDlArgs [string[]]    > Arguments passed to gallery-dl.

        -VerifyUrls [switch]         > Make a HEAD request to test the urls before handing
                                       them over to gallery-dl and remove the failing ones.
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

  if ($VerifyUrls) {
    Write-Host -ForegroundColor Yellow "
      WARNING: Verify the urls may be useful to filter out text that is not a valid url
      however valid urls could be filter out if the backend service blocks the HEAD method.
    "
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

    $linesRaw = @()

    if ($stringsFromPipe) {
      foreach ($line in $stringsFromPipe) {
        $linesRaw += $line
      }
    } 

    if ($fileToDownload) {
      foreach ($line in Get-Content $fileToDownload) {
        $linesRaw += $line
      }
    }

    if ($stringsFromArgs) {
      foreach ($line in $stringsFromArgs) {
        $linesRaw += $line
      }
    }

    if ($ClipBoard) {
      foreach ($line in Get-ClipBoard) {
        $linesRaw += $line
      }
    }

    # If no urls where provided, open a buffer
    if (-not $linesRaw) {
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

      if (-not $VerifyUrls) {
        return "$url"
      }

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

