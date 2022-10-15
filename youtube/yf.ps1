# pwsh wrapper for ytfzf (yf)

# Navigate to script directory
Push-Location "$PSScriptRoot"

# Find gitbash and no a wsl bash
$__gitbash__ = $(where.exe bash | grep 'Git\\usr\\bin\\bash')

# Run yf command
& $__gitbash__ --norc -ilc "ytfzf-wrapper.sh yf $args"

Pop-Location

