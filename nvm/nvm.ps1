#!/usr/bin/env pwsh

if ($IsWindows) {
  # Check if there is a single argument is use
  # Otherwise, forward arguments to real nvm
  $nvmrc_present = Test-Path "$PSD/.nvmrc" -ea 0
  $second_argument_null = $null -eq $args[1]

  if ($nvmrc_present -and $second_argument_null) {
    $subcommand = $args[0]
    switch ($subcommand) {
      'use' {
        $nvm_version = Get-Content "$PWD/.nvmrc"
        & "$env:NVM_HOME\nvm.exe" use $nvm_version
        exit
      }
      { $_ -in 'install', 'i' } {
        $nvm_version = Get-Content "$PWD/.nvmrc"
        & "$env:NVM_HOME\nvm.exe" install $nvm_version
        exit
      }
      Default {}
    }
  }

  & "$env:NVM_HOME\nvm.exe" $args
} else {
  $command = '
    export NVM_DIR="$HOME/.nvm";
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh";
    [ -s "$NVM_DIR/nvm.sh" ] && ' + "nvm $args"
  bash -c $command
}

