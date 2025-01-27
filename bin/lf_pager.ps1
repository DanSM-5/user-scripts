#!/usr/bin/env pwsh

$user_conf_path = if ($env:user_conf_path) {
  $env:user_conf_path
} else {
  "$HOME/.usr_conf"
}

# NOTE:
# less uses the below variable to print unicode characters instead
# of displaying the sequence. Needed to bat with paging=always flag.
# Ref: https://github.com/sharkdp/bat/issues/2578#issuecomment-1598332705
$env:LESSUTFCHARDEF = 'E000-F8FF:p,F0000-FFFFD:p,100000-10FFFD:p'

& "$user_conf_path/utils/fzf-preview.ps1" $args | bat --style=plain --color=always --paging=always
# & "$user_conf_path/utils/fzf-preview.ps1" $args | less -R

# Write-Host -NoNewLine 'Press any key to continue...';
# $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');

