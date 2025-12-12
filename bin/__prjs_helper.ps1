#!/usr/bin/env pwsh

if ($env:debug) {
  Set-PSDebug -Trace 2
}

try {
  
$directory_in = if ($args[1]) { $args[1] } else { '.' }
$user_conf_path = if ($env:user_conf_path) { $env:user_conf_path } else { "$HOME/.usr_conf" }
$prj_files = "$user_conf_path/prj"
$SHOME = $HOME -Replace '\\', '/'

function end_script ([string] $msg) {
  Write-Error $msg
  exit 1
}

function get_shebang {
  Write-Output "#!/usr/bin/env bash`n"
}

switch ($args[0]) {
  "locations" {
    $script:out_file = "$prj_files/locations"
    break
  }
  "directories" {
    $script:out_file = "$prj_files/directories"
    break
  }
  Default {
    end_script "Unrecognized type '$1'"
  }
}

function add_entry ([string] $entry, [string] $replace) {
  $new_entry = $entry -Replace '\\', '/'
  $new_entry = $new_entry -Replace "$SHOME", '$HOME'

  Write-Output "Adding: $new_entry"
  $new_entry >> "$out_file"
}

# Ensure dir exists
New-Item -ItemType 'Directory' -Path "$prj_files" -Force *> $null

# Create file file if doesn't already
if (!(Test-Path -LiteralPath "$out_file" -PathType Leaf -ErrorAction SilentlyContinue)) {
  get_shebang > "$out_file" || end_script "Erro creating '$out_file'"
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
  Get-Content "$out_file"
}

# Sort entries
& {
  get_shebang
  Get-Content "$out_file" | Select-Object -Skip 2 | Sort-Object -Unique
} | sponge "$out_file"

} finally {
  if ($env:debug) {
    Set-PSDebug -Trace 0
  }
}

