#!/usr/bin/env pwsh

# Call bash from gitbash to run a bash script
# without having to call bash.exe with -l or -i flags

# Find env.exe but do not rely on default location in C:\Program Files
$gitenv = "$(where.exe env | Select-String 'Git\\usr\\bin\\env')"

# Create new valid path. By default bash launch this way won't include
# important entries like /usr/bin etc. This builds the path from current inherited path
# to gitbash format and include required entries for gitbash to find unix utilities.
#
# This approach is slightly slower and it is more complex
# but it is less trouble with escaping characters. So it is the preferred
#
$sb = [System.Text.StringBuilder]::new()
[void]$sb.Append('/mingw64/bin:/usr/local/bin:/usr/bin:/bin')
foreach ($entry in ($env:PATH.Replace('\', '/').Split(';'))) {
  [void]$sb.Append(':/') # Separator and root
  [void]$sb.Append($entry[0].ToString().ToLower()) # Lowercase Drive letter
  [void]$sb.Append($entry.Substring(2)) # Rest without colon ':'
}
$newPath = $sb.ToString()
& "$gitenv" MSYS=enable_pcon MSYSTEM=MINGW64 enable_pcon=1 SHELL=bash "PATH=$newPath" /usr/bin/bash -c "$args"

# Other option to build the command without the need of building a path
# $append_path = "export PATH=`"/mingw64/bin:/usr/local/bin:/usr/bin:/bin:`$PATH`";"
# & "$gitenv" MSYS=enable_pcon MSYSTEM=MINGW64 enable_pcon=1 SHELL=bash /usr/bin/bash -c "$append_path $args"

# Examples:
# & "$script:__gitenv__" $script:GITBASH_ENVIRONMENT /usr/bin/bash -c "$script:__append_path__ $script:fgt_command"
# & "C:\Program Files\Git\usr\bin\env.exe" MSYS=enable_pcon MSYSTEM=MINGW64 enable_pcon=1 /usr/bin/bash -c 'export PATH=/usr/bin:$PATH; COMMAND'

