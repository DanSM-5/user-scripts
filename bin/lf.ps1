# Run lf in the context of MINGW

# Important to use @args and no $args when sending arguments to this script

# Find path location of binaries env and bash so they can be located
# in arbitrary path locations for custom installations. 
$gitenv = $(where.exe env | grep 'Git\\usr\\bin\\env')
$gitbash = $(where.exe bash | grep 'Git\\usr\\bin\\bash')

# Environment variables for starting git process from env
$GITBASH_ENVIRONMENT = @(
  # Enable MINGW work as running gitbash directly
  "MSYS='enable_pcon'"
  "MSYSTEM='MINGW64'"
  "enable_pcon='1'"
  "SHELL=/usr/bin/bash"
  #
  # Avoid POSIX to WINDOWS path conversions
  # "MSYS_NO_PATHCONV='1'"
  # "MSYS2_ARG_CONV_EXCL='*'"
  #
  # Concept idea. Use $gitbash -c 'printf "$PATH"'
  # to get the path in git bash format and add it here
  #
  # Bash binary location in Git bash environment and command flag
  "/usr/bin/bash"
  "-c"
)

# Escaped variables to be added before executable in the -c argument
$APPENDED_ENVIRONMENT = @(
  # Using export for path
  # "export PATH=`"/usr/bin:`$PATH`";"
  # If using & to call the command
  # "PATH=`"/usr/bin:`$PATH`""
  # If using Start-Process
  "`"PATH=\`"/mingw64/bin:/usr/local/bin:/usr/bin:/bin:`$PATH\`""
)

# Start command args with empty array
$COMMAND_ARGS = @()

if ($args.length) {
  # Create new array with updated size
  $COMMAND_ARGS = 1..$args.length
}

for ($i = 0; $i -lt $args.length; $i++) {
  $arg_value = $args[$i]

  # Use gitbash printf to escape all arguments to lf using printf
  $arg_value = & "$gitbash" -c "printf '%q' '$arg_value'"
  # Then lets wrap all arguments in single quotes
  $COMMAND_ARGS[$i] = "'$arg_value'"
}

# Call a prepared shell command. It adds MINGW64 environment variables,
# adds /usr/bin to the start of the path and forward all escaped command arguments 
# & "$gitenv" $GITBASH_ENVIRONMENT /usr/bin/bash -c "$APPENDED_ENVIRONMENT lf.exe $COMMAND_ARGS"
# Debug command
# Write-Host "&" "$gitenv" "$GITBASH_ENVIRONMENT" /usr/bin/bash -c "$APPENDED_ENVIRONMENT lf.exe $COMMAND_ARGS"

# Original test with Start-Process
# $test = Start-Process -FilePath "C:\Program Files\Git\usr\bin\env.exe" -ArgumentList @("MSYS=enable_pcon", "MSYSTEM=MINGW64", "enable_pcon=1", "SHELL=/usr/bin/bash", "/usr/bin/bash", "-c", "`"PATH=\`"/usr/bin:`$PATH\`" lf.exe`"") -NoNewWindow -PassThru; $test.WaitForExit(); $test.WaitForExit()

# Use Start-Process to execute the command
$proc = Start-Process -FilePath "$gitenv" -ArgumentList @(
  $GITBASH_ENVIRONMENT
  "$APPENDED_ENVIRONMENT lf.exe $COMMAND_ARGS"
) -NoNewWindow -PassThru

# Wait for lf to exit
$proc.WaitForExit()

# Clean process reference
$proc = $null

