# pwsh wrapper for ytfzf (yfd)

# Navigate to script directory
Push-Location "$PSScriptRoot"

# Find gitbash and no a wsl bash
$__gitbash__ = $(where.exe bash | grep 'Git\\usr\\bin\\bash')

# Run yfd command
& $__gitbash__ --norc -ilc "ytfzf-wrapper.sh yfd $args"

Pop-Location

