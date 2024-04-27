#!/usr/bin/env pwsh

# Call bash from gitbash to run a bash script
# without having to call bash.exe with -l or -i flags

$gitenv = "$(where.exe env | Select-String 'Git\\usr\\bin\\env')"

# Create new valid path and appended to env.exe PATH=$newPath
# Howerver this approach is slower. It is faster to just export the needed entries
# with the risk of getting scaping issues
#
# $sb = [System.Text.StringBuilder]::new()
# [void]$sb.Append('/mingw64/bin:/usr/local/bin:/usr/bin:/bin')
# foreach ($entry in ($env:PATH.Split(';'))) {
#   [void]$sb.Append(':')
#   $cygpath = cygpath -au $entry
#   [void]$sb.Append($cygpath)
# }
# $newPath = $sb.ToString()
# $newPath.Split(':')
# & "$gitenv" MSYS=enable_pcon MSYSTEM=MINGW64 enable_pcon=1 SHELL=bash "PATH=$newPath" /usr/bin/bash -c "$args"

# $command = ('"export PATH=/mingw64/bin:/usr/local/bin:/usr/bin:/bin:\$PATH; ' + "$args" + '"')
$append_path = "export PATH=`"/mingw64/bin:/usr/local/bin:/usr/bin:/bin:`$PATH`";"
& "$gitenv" MSYS=enable_pcon MSYSTEM=MINGW64 enable_pcon=1 SHELL=bash /usr/bin/bash -c "$append_path $args"

# Examples:
# & "$script:__gitenv__" $script:GITBASH_ENVIRONMENT /usr/bin/bash -c "$script:__append_path__ $script:fgt_command"
# & "C:\Program Files\Git\usr\bin\env.exe" MSYS=enable_pcon MSYSTEM=MINGW64 enable_pcon=1 /usr/bin/bash -c 'export PATH=/usr/bin:$PATH; COMMAND'

