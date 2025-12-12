#!/usr/bin/env pwsh

if ($env:debug) {
  Set-PSDebug -Trace 2
}

try {
  
$directory_in = if ($args[0]) { $args[0] } else { '.' }
$user_conf_path = if ($env:user_conf_path) { $env:user_conf_path } else { "$HOME/.usr_conf" }
$prj_files = "$user_conf_path/prj"
$dirs = "$prj_files/directories"
$SHOME = $HOME -Replace '\\', '/'

function end_script ([string] $msg) {
  Write-Error $msg
  exit 1
}

function get_shebang {
  Write-Output "#!/usr/bin/env bash`n"
}

function add_entry ([string] $entry, [string] $replace) {
  $new_entry = $entry -Replace '\\', '/'
  $new_entry = $new_entry -Replace "$SHOME", '$HOME'

  Write-Output "Adding: $new_entry"
  $new_entry >> "$dirs"
}

# Ensure dir exists
New-Item -ItemType 'Directory' -Path "$prj_files" -Force *> $null

# Create file file if doesn't already
if (!(Test-Path -LiteralPath "$dirs" -PathType Leaf -ErrorAction SilentlyContinue)) {
  get_shebang > "$dirs" || end_script "Erro creating '$dirs'"
}

# Prepare to add directory
$directory = Resolve-Path -LiteralPath "$directory_in"

# If file, get its directory
if (test-path -literalpath "$directory" -pathtype leaf -erroraction silentlycontinue) {
  $directory = [system.io.path]::getdirectoryname($directory)
}

# Final check for directory
if (!(Test-Path -LiteralPath "$directory" -PathType Container -ErrorAction SilentlyContinue)) {
  end_script "Cannot add directory: $directory"
}

# Adding new entry in directories file
add_entry "$directory" '$HOME'

if ($env:debug) {
  Get-Content "$dirs"
}

# Sort entries
& {
  get_shebang
  Get-Content "$dirs" | Select-Object -Skip 2 | Sort-Object -Unique
} | sponge "$dirs"

} finally {
  if ($env:debug) {
    Set-PSDebug -Trace 0
  }
}
