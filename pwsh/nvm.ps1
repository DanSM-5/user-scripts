#!/usr/bin/env pwsh

if ($IsWindows) {
  # Check if there the only argument is use or install
  # Otherwise, forward arguments to real nvm for windows
  if (($args[0] -eq 'use' -or $args[0] -eq 'install') -and ($null -eq $args[1])) {
    $nvm_version = Get-Content "$PWD/.nvmrc"
    & "$env:NVM_HOME\nvm.exe" $args[0] $nvm_version
  } else {
    & "$env:NVM_HOME\nvm.exe" $args
  }
} else {
  Write-Output "Not yet implemented"
}

