#!/usr/bin/env pwsh

$user_scripts_path = if ($env:user_scripts_path) { $env:user_scripts_path } else { "$HOME/user-scripts" }

$fd_exclude_file = "$user_scripts_path/fd/fd_exclude"
$fd_options_file = "$user_scripts_path/fd/fd_options"

# $fd_exclude = Get-Content $fd_exclude_file
$fd_options = Get-Content $fd_options_file

# Write-Output "Arguments read from fd_exclude_file: $fd_exclude"
# Write-Output "Arguments read from fd_options_file: $fd_options"

& fd $fd_options --ignore-file $fd_exclude_file @args

