# Run lf in the context of MINGW

# Important to use @args and no $args when sending arguments to this script

$__gitenv__ = $(where.exe env | grep 'Git\\usr\\bin\\env')
$__gitbash__ = $(where.exe bash | grep 'Git\\usr\\bin\\bash')

$__apend_path__ = "export PATH=`"/usr/bin:`$PATH`";"
$APPENDED_ENVIRONMENT = @(
  "PATH=`"/usr/bin:`$PATH`""
)

$GITBASH_ENVIRONMENT = @(
  # Enable MINGW work as running gitbash directly
  "MSYS='enable_pcon'"
  "MSYSTEM='MINGW64'"
  "enable_pcon='1'"
  "SHELL=/usr/bin/bash"
  # Avoid POSIX to WINDOWS path conversions
  # "MSYS_NO_PATHCONV='1'"
  # "MSYS2_ARG_CONV_EXCL='*'"
)

$COMMAND_ARGS = 1..$args.length

for ( $i = 0; $i -lt $args.length; $i++ ) {
  $arg_value = $args[$i]

  # Use gitbash printf to escape all arguments to lf in bash context
  $arg_value = "$(& "$__gitbash__" -c "printf '%q' '$arg_value'")"
  # Then lets wrap all arguments in single quotes
  $COMMAND_ARGS[$i] = "'$arg_value'"
}

# Call a prepared shell command. It adds MINGW64 environment variables,
# adds /usr/bin to the start of the path and forward all escaped command arguments 
& "$__gitenv__" $GITBASH_ENVIRONMENT /usr/bin/bash -c "$APPENDED_ENVIRONMENT lf.exe $COMMAND_ARGS"
# Write-Host "&" "$__gitenv__" "$GITBASH_ENVIRONMENT" /usr/bin/bash -c "$APPENDED_ENVIRONMENT lf.exe $COMMAND_ARGS"

