#!/usr/bin/env pwsh

$user_scripts_path = if ($env:user_scripts_path) { $env:user_scripts_path } else { "$HOME/user-scripts" }

$fd_exclude_file = "$user_scripts_path/fd/fd_exclude"
$fd_show_file = "$user_scripts_path/fd/fd_show"

$fd_exclude = Get-Content $fd_exclude_file
$fd_show = Get-Content $fd_show_file

# Write-Output "Arguments read from fd_exclude_file: $fd_exclude"
# Write-Output "Arguments read from fd_show_file: $fd_show"

& fd $fd_show $fd_exclude --color=always @args

