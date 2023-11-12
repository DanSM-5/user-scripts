# NOTE Do not use. Prefer lfrc.win that uses bash for windows
# as a wrapper for lf to set sh as the shell

# Set powershell as current shell
set shell powershell

# Open file in nvim
map e $nvim $Env:f

# Use bat as pager
map i $bat $Env:f

# Open new shell
map w $pwsh

# Open docs in bat
cmd doc $lf -doc | bat --language man -p

# Add icons when starting lf
set icons

