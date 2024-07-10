#!/usr/bin/env pwsh

# Re-write script of
# https://github.com/Debian/wcurl/blob/main/wcurl
# to make it powershell compatible.
# Added -CurlCmd to point to a compatible version of curl if needed

[CmdletBinding()]
Param(
  [Switch] $DryRun,
  [Switch] $Version,
  [Switch] $Help,
  [String[]] $CurlOptions = @(),
  [String] $CurlCmd = 'curl',
  [Parameter(ValueFromRemainingArguments = $true, position = 0)]
  [String[]] $Urls = @()
)

$VERSION_SCRIPT = "2024.07.07+dev"

$PROGRAM_NAME = $MyInvocation.MyCommand.Name

# Display the version.
function print_version () {
  Write-Output @"
${VERSION_SCRIPT}
"@
}

# Display the program usage.
function usage () {
  Write-Output @"
${PROGRAM_NAME} -- a simple wrapper around curl to easily download files for powershell.

Usage: ${PROGRAM_NAME} [-CurlOptions <CURL_OPTION>, <CURL_OPTION>,...] [-DryRun] <URL>...
       ${PROGRAM_NAME} -Help
       ${PROGRAM_NAME} -Version

Options:

  -CurlOptions <CURL_OPTIONS>: Specify extra options to be
                                 passed when invoking curl. May be
                                 specified more than once.

  -DryRun: Don't actually execute curl, just print what would be
             invoked.

  -Version: Print version information.

  -Help: Print this usage message.

  -CurlCmd: Use a specific curl binary.

  <URL>: The URL to be downloaded.  May be specified more than once.
"@
}

# Display an error message and bail out.
function error () {
  Write-Error $args
  exit 1
}


# Extra curl options provided by the user.
# This will be set per-URL for every URL provided.
# Some options are global, but we are erroring on the side of needlesly setting
# them multiple times instead of causing issues with parameters that needs to
# be set per-URL.
# $CURL_OPTIONS = $()

# The URLs to be downloaded.
$DOWNLOAD_URLS = [System.Collections.Generic.List[string]]::new()

# The parameters that will be passed per-URL to curl.
[String[]] $PER_URL_PARAMETERS = @(
  '--globoff',
  '--location',
  '--no-clobber',
  '--proto-default', 'https',
  '--remote-name-all',
  '--remote-time',
  '--retry', '10',
  '--retry-max-time', '10'
)

# Whether to invoke curl or not.
$DRY_RUN = $false

# Sanitize parameters.
function sanitize () {
  if (!$DOWNLOAD_URLS.Count) {
    error "You must provide at least one URL to download."
  }
}

# Execute curl with the list of URLs provided by the user.
function exec_curl() {
  $CMD = [System.Collections.Generic.List[string]]::new()
  # $CMD.Add('curl')

  if ($script:DOWNLOAD_URLS.Count -gt 1 ) {
    $CMD.Add('--parallel')
  }

  # set -- ${CMD} ${CURL_PARALLEL}
  # $command = "$CMD $CURL_PARALLEL"

  $NEXT_PARAMETER = $false
  foreach ($url in $DOWNLOAD_URLS) {
    if ($NEXT_PARAMETER) {
      $CMD.Add('--next')
    }
    $CMD.AddRange($PER_URL_PARAMETERS)
    $CMD.AddRange($CurlOptions)
    $CMD.Add($url)
    $NEXT_PARAMETER = $true
  }

  if (!$DryRun) {
    & $CurlCmd @CMD
  } else {
    Write-Output "$CurlCmd $CMD"
  }
}

if ($Help) {
  usage
  exit 0
}

if ($Version) {
  print_version
  exit 0
}

foreach ($url in $Urls) {
  # Encode whitespaces into %20, since wget supports those URLs.
  $DOWNLOAD_URLS.Add(($url -Replace ' ', '%20'))
}

sanitize
exec_curl

