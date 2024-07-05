
<#
.SYNOPSIS
  Wrapper script for yt-dlp to list links for download.

.DESCRIPTION
  Wrapper script that will allow passing multiple urls to yt-dlp.
  The order of priority is pipeline > argument array > argument file > clipboard.
  All ways of passing urls can be used. Priority only affects order of download.
  If no urls are provided, a temporal buffer will open to add the urls.
  All urls will remove empty lines or lines starting with "#".
  It accepts encoded urls.

.PARAMETER ParallelDownload
  Allow splitting the download per domain to download simultaneously.

.PARAMETER FilePath
  Specify path to file with links to download

.PARAMETER EditorName
  Name of the editor to open. If not a fullpath, it needs to be available in $env:PATH

.PARAMETER ClipBoard
  Get the content of the clipboard to feed yt-dlp. It uses Get-ClipBoard cmdlet.

.PARAMETER UrlsToDownload
  Array of strings to be process by the script instead of opening a file to add them manually.

.PARAMETER StringUrl
  String obtain from a pipeline. All pipeline strings will be stored. Download process will happen at the end on End block.

.PARAMETER VerifyUrls
  Make a HEAD request to test each url. If the request fails, the url will be removed.
  This could remove valid urls if the server blocks the HEAD request for the specific domain.
  Use it with caution.

.PARAMETER ArgsForCmd
  Arguments to be passes to yt-dlp.
  Note: On multy thread downlaods the arguments will be passed to each invokation of yt-dlp.
  Note: The argument '-a' or '--batch-file' is always used internally and if included, both will be passed to yt-dlp.

.PARAMETER DownloadCommand
  Command used internally for the download action. By default this script assumes 'yt-dlp' command
  but this can be overriden for system specific needs

.PARAMETER Help
  Prints help message on screen. If this argument is passed, execution will end after the help message is print
  and any other argument will be ignored.

.INPUTS
  String object from pipeline.

.OUTPUTS
  Script does not produce any output. It is meant to be used as last element in pipeline.

.EXAMPLE
  Download-Yld

.EXAMPLE
  Download-Yld -EditorName vim

.EXAMPLE
  Download-Yld -ParallelDownload -FilePath $HOME/links-to-download.txt

.EXAMPLE
  @("$url1", "$url2", "$url3") | Download-Ydl

.EXAMPLE
  Download-Yld -ArgsForCmd @('-q', '--sleep', '20') -ClipBoard

.EXAMPLE
  Download-Yld -UrlsToDownload @("$url1", "$url2") -ParallelDownload

.NOTES
  Script respects the EDITOR environment variable. If not present if defaults to notepad.exe.
  If the -Help flag is present, it will be prioritized over the other arguments and script with exit.

#>

[CmdletBinding()]
Param (
  # Allow parallel download per domain
  [Switch] $ParallelDownload,

  # Display help message
  [Switch] $Help,

  # String url from pipe
  [Parameter(ValueFromPipeline = $true)]
  [System.Object] $StringUrl,

  # Editor to use when opening temporal buffer
  [AllowNull()]
  [String] $EditorName = $null,

  # Array of strings to download
  [AllowNull()]
  [String[]] $UrlsToDownload = $null,

  # Path to file to download
  [AllowNull()]
  [String] $FilePath = $null,

  # Get the urls from the clipboard
  [Switch] $ClipBoard,

  # Arguments for yt-dlp
  [AllowNull()]
  [String[]] $ArgsForCmd = @(),

  # Name of command to use
  [String] $DownloadCommand = 'yt-dlp',

  # Verify each url by doing a HEAD request
  [Switch] $VerifyUrls,

  # Remaining args will be consider independent urls
  [Parameter(ValueFromRemainingArguments = $true)]
  [String[]]
  $RemainingArgs = @()
)

Begin {
  function showHelp () {
    Write-Host "
      Wrapper scritp for yt-dlp

      Open a temporary buffer to list all the urls. Once closed,
      the script will feed the urls to yt-dlp to download them.

      Flags:

        -Help [switch]               > Print this message.

        -ParallelDownload [switch]   > Allow parallel downloads per domain.

        -FilePath [string]           > Path to input file.

        -EditorName [string]         > Name of the editor to open the temporal buffer.

        -ClipBoard [switch]          > Use the content of the clipboard to get the urls.

        -UrlsToDownload [string[]]   > Print this message.

        -StringUrl [string]          > Url string from pipeline (pipe only).

        -ArgsForCmd [string[]]       > Arguments passed to yt-dlp.

        -DownloadCommand             > Command name or path for yt-dlp. Default is yt-dlp.

        -VerifyUrls [switch]         > Make a HEAD request to test the urls before handing
                                       them over to yt-dlp and remove the failing ones.
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

  if (-not (Get-Command "$DownloadCommand" -errorAction SilentlyContinue)) {
    Write-Host -ForegroundColor Red "Download command '$DownloadCommand' not found. Please install it and add it to your path to continue."
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
  $comments = @( '#', '//', ';', ']' )
  $is_comment_regex = "^(" + ($comments -join '|') + ")"
}

Process {
  if ( $StringUrl -is [String] ) {
    $stringsFromPipe += $StringUrl
  }
}

End {

  # TODO: Verify is sqlite could have issues with parallel downloads
  # Snipped from https://github.com/github-account1111
  # in thread https://github.com/mikf/yt-dlp/issues/31

  function downloadParallel ([String[]] $links) {
    $links | % {
      $link = New-Object System.Uri $_
      $link.Host
    } | Select-Object -Unique | % {
      $hostName = $_
      $links -match $_ | Start-ThreadJob {
        $perDomainInput = New-TemporaryFile
        $downloadFileName = $perDomainInput.FullName
        try {
          $input | Out-File "$downloadFileName" -Encoding ascii
          # --batch-file or -a
          & $DownloadCommand $ArgsForCmd --batch-file "$downloadFileName"
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
    $downloadFileName = $downloadFile.FullName

    try {
      $links | Out-File $downloadFileName -Encoding ascii

      & $DownloadCommand $ArgsForCmd --batch-file "$downloadFileName"
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

    $linesRaw = [System.Collections.Generic.List[string]]::new()

    if ($stringsFromPipe) {
      foreach ($line in $stringsFromPipe) {
        $linesRaw.Add($line)
      }
    }

    if ($fileToDownload) {
      foreach ($line in Get-Content $fileToDownload) {
        $linesRaw.Add($line)
      }
    }

    if ($stringsFromArgs) {
      foreach ($line in $stringsFromArgs) {
        $linesRaw.Add($line)
      }
    }

    if ($ClipBoard) {
      foreach ($line in Get-ClipBoard) {
        $linesRaw.Add($line)
      }
    }

    if ($RemainingArgs) {
      foreach ($line in $RemainingArgs) {
        $linesRaw.Add($line)
      }
    }

    # If no urls where provided, open a buffer
    if (-not $linesRaw) {
      # Open buffer to get strings
      Write-Output "Opening temporary file... Waiting for file to be closed!"

      $tempFile = New-TemporaryFile
      $instructions >> $tempFile
      $editorArgs += $tempFile.FullName

      if ($editor -match '[gn]?vi[m]?') {
        $editorArgs += '+'
      }

      $proc = Start-Process $editor -NoNewWindow -PassThru -ArgumentList $editorArgs
      $proc.WaitForExit()

      $proc = $null

      $linesRaw = Get-Content $tempFile.FullName
    }

    Write-Output "Start processing with $DownloadCommand..."

    $lines = $linesRaw | Where {
      # Get rid of spaces
      $url = $_.Trim()

      # Omit empty lines
      if (-Not $url) {
        return
      }

      # Omit comments
      if ($url -Match "$is_comment_regex") {
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

    if ($ParallelDownload) {
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

