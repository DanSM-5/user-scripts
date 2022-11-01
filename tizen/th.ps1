# PS1 wrapper for pwsh

# Fix path variables before passing them to bash
$args_array = 0..$args.count
for ( $i = 0; $i -lt $args.count; $i++ ) {
  $args_array[$i] = "$($args[$i] -replace '\\', '/')"
}

# Find gitbash and no a wsl bash
$__gitbash__ = $(where.exe bash | grep 'Git\\usr\\bin\\bash')

$CHROMIUM = if ($env:CHROMIUM) { $env:CHROMIUM -replace '\\', '/' } else { $($HOME -replace '\\', '/') + '/AppData/Local/Chromium/Application/chrome.exe' }
$CHROMIUM = if ($CHROMIUM -match ':') { "/c" + $CHROMIUM.substring(2) } else { $CHROMIUM }
$IP = $env:SAMSUNG_DEVICE_IP
$WEB_SECURITY = $env:DISABLE_WEB_SECURITY

& $__gitbash__ --norc -ilc "CHROMIUM='$CHROMIUM' SAMSUNG_DEVICE_IP='$IP' DISABLE_WEB_SECURITY='$WEB_SECURITY' tizen-help $args_array"

