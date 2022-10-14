# PS1 wrapper for pwsh

# Find gitbash and no a wsl bash
$__gitbash__ = $(where.exe bash | grep 'Git\\usr\\bin\\bash')

& $__gitbash__ --norc -ilc "tizen-help $args"
