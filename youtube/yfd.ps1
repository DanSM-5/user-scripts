# pwsh wrapper for ytfzf (yfd)

# Navigate to script directory
Push-Location "$PSScriptRoot"

# Find gitbash and no a wsl bash
# $__gitbash__ = $(where.exe bash | grep 'Git\\usr\\bin\\bash')

# Run yfd command
# & $__gitbash__ --norc -ilc "ytfzf-wrapper.sh yfd $args"

# Find env in git installation directly
$__gitenv__ = $(where.exe env | grep 'Git\\usr\\bin\\env')

# Run yf command
# & $__gitbash__ --norc -ilc "ytfzf-wrapper.sh yf $args"

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
& $__gitenv__ $GITBASH_ENVIRONMENT /usr/bin/bash -c "export PATH=`"/usr/bin:/usr/local/bin:`$PATH`"; ytfzf-wrapper.sh yfd $args"

Pop-Location

