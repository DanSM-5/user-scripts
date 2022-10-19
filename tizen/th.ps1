# PS1 wrapper for pwsh

# Fix path variables before passing them to bash
$args_array = 0..$args.count
for ( $i = 0; $i -lt $args.count; $i++ ) {
  $args_array[$i] = "$($args[$i] -replace '\\', '/')"
}

# Find gitbash and no a wsl bash
$__gitbash__ = $(where.exe bash | grep 'Git\\usr\\bin\\bash')

& $__gitbash__ --norc -ilc "tizen-help $args_array"
