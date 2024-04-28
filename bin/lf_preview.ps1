# NOTICE:
# For some unknown reason, even though lf is launched in gitbash
# and the 'set shell zsh/bash' is called. The previewer will only
# find lf_preview.bat file 😅
# Fortunatelly there is fzf-preview.ps1 for powershell, so it is easier
# to use that one instead.
#
# This is the price for getting a nicer preview...

# Set UTF8 encoding to handle names with weird characters
$OutputEncoding = [Console]::OutputEncoding = New-Object System.Text.Utf8Encoding

# Expand '~' and normalize paths to use forward slash
$path_arg = "$args".Replace('~', $HOME).Replace('\', '/').Trim()
$location = $PWD.ProviderPath.Replace('\', '/')

# Feed it to the fzf-preview script
& "$env:user_conf_path/utils/fzf-preview.ps1" $location $path_arg

