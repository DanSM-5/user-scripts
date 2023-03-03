# PS1 wrapper for pwsh

# function parse-path ([string] $original) {
#   # Change \ for / in paths.
#   $parsed = "$($original -replace '\\', '/')"

#   # Update absolute paths with posix paths
#   if ($parsed -match ':') {
#     return '/' + $parsed.substring(0, 1).toLower() + $parsed.substring(2)
#   } else {
#     return $parsed
#   }
# }

# Fix path variables before passing them to bash
$args_array = 1..$args.count
for ( $i = 0; $i -lt $args.count; $i++ ) {
  $parsed = "$($args[$i] -replace '\\', '/')"
  $args_array[$i] = if ($parsed -match ':') { '/' + $parsed.substring(0, 1).toLower() + $parsed.substring(2) } else { $parsed }
}

# Find gitbash and no a wsl bash
$__gitbash__ = $(where.exe bash | grep 'Git\\usr\\bin\\bash')

$CHROMIUM = if ($env:CHROMIUM) { $env:CHROMIUM -replace '\\', '/' } else { $($HOME -replace '\\', '/') + '/AppData/Local/Chromium/Application/chrome.exe' }
$CHROMIUM = if ($CHROMIUM -match ':') { '/' + $CHROMIUM.substring(0, 1).toLower() + $CHROMIUM.substring(2) } else { $CHROMIUM }
$IP = $env:SAMSUNG_DEVICE_IP
$WEB_SECURITY = $env:DISABLE_WEB_SECURITY

& $__gitbash__ --norc -ilc "CHROMIUM='$CHROMIUM' SAMSUNG_DEVICE_IP='$IP' DISABLE_WEB_SECURITY='$WEB_SECURITY' tizen-help $args_array"

