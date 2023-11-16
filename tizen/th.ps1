# PS1 wrapper for powershell

function parse_winpaths ([string] $in_path) {
  $parsed_path = "$($in_path -replace '\\', '/')"
  # Parse the drive letter from absolute paths in windows
  $parsed_path = if ($parsed_path -match ':') { '/' + $parsed_path.substring(0, 1).toLower() + $parsed_path.substring(2) } else { $parsed_path }
  return $parsed_path
}

# Fix path variables before passing them to bash
$args_array = 1..$args.count
for ( $i = 0; $i -lt $args.count; $i++ ) {
  $script_arg = $args[$i]
  $args_array[$i] = parse_winpaths "$script_arg"
}

# Script location
$th_location = parse_winpaths ($MyInvocation.MyCommand.Path | Split-Path -Parent)
$th_location = "$th_location/tizen-help"

# Verify if tizen-help is located in the same directory. If not default to the command if it is available in the path.
$th_location = if (Test-Path -Path "$th_location" -ErrorAction SilentlyContinue) { "$th_location" } else { 'tizen-help' }

# Find env in git installation directly
$__gitenv__ = $(where.exe env | grep 'Git\\usr\\bin\\env')
# $__gitbash__ = $(where.exe bash | grep 'Git\\usr\\bin\\bash')

$CHROMIUM = if ($env:CHROMIUM) { $env:CHROMIUM } else { "$HOME" + '/AppData/Local/Chromium/Application/chrome.exe' }
$CHROMIUM = parse_winpaths "$CHROMIUM"
$IP = $env:SAMSUNG_DEVICE_IP
$WEB_SECURITY = $env:DISABLE_WEB_SECURITY

# Environment variables to setup bash from git for windows
$GITBASH_ENVIRONMENT = @(
  # Enable MINGW work as running gitbash directly
  "MSYS='enable_pcon'"
  "MSYSTEM='MING64'"
  "enable_pcon='1'"
  # Avoid POSIX to WINDOWS path conversions
  # "MSYS_NO_PATHCONV='1'"
  # "MSYS2_ARG_CONV_EXCL='*'"
  # Add ENV variables for tizen-help
  "CHROMIUM='$CHROMIUM'"
  "SAMSUNG_DEVICE_IP='$IP'"
  "DISABLE_WEB_SECURITY='$DISABLE_WEB_SECURITY'"
)

# Required to add /usr/bin in the path for the hashbang in tizen-help script to work
& $__gitenv__ $GITBASH_ENVIRONMENT /usr/bin/bash -c "export PATH=`"/mingw64/bin:/usr/local/bin:/usr/bin:/bin:`$PATH`"; $th_location $args_array"
