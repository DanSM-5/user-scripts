#!/usr/bin/pwsh

if ($IsWindows) {
  # Check if there the only argument is use
  # Otherwise, forward arguments to real nvm
  if (($args[0] -eq 'use') -and ($args[1] -eq $null) -and (Test-Path "$PSD/.nvmrc" -ea 0)) {
    $nvm_version = Get-Content "$PWD/.nvmrc"
    & "$env:NVM_HOME\nvm.exe" use $nvm_version
  } elseif (($args[0] -eq 'install') -and ($args[1] -eq $null) -and (Test-Path "$PSD/.nvmrc" -ea 0)) {
    $nvm_version = Get-Content "$PWD/.nvmrc"
    & "$env:NVM_HOME\nvm.exe" install $nvm_version
  } else {
    & "$env:NVM_HOME\nvm.exe" $args
  }
} else {
  Write-Output "Not yet implemented"
}

