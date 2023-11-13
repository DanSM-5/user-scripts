# Run lf in the context of MINGW

# Important to use @args and no $args when sending arguments to this script

$__apend_path__ = "export PATH=`"/usr/bin:`$PATH`";"
$APPENDED_ENVIRONMENT = @(
  "PATH=`"/usr/bin:`$PATH`""
  "NEW=test"
)

$__gitenv__ = $(where.exe env | grep 'Git\\usr\\bin\\env')
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

& "$__gitenv__" $GITBASH_ENVIRONMENT /usr/bin/bash -c "$APPENDED_ENVIRONMENT lf.exe $args"

