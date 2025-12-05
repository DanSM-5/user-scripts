#!/usr/bin/env pwsh

if (!(Get-Command -Name 'age' -ErrorAction SilentlyContinue)) {
  Write-Error 'age command not found'
  exit 1
}

# prefix to separate different type of notes
$prefix = if ($args[0]) { $args[0] } elseif ($env:AGE_KEY_PREFIX) { $env:AGE_KEY_PREFIX } else { $null }

if (!$prefix) {
  Write-Error 'Prefix variable AGE_KEY_PREFIX not set and not provided and argument for prefix'
  exit 1
}

# Set prj folder
$prj = if ($prj) { $prj } elseif ($env:prj) { $env:prj } else { "$HOME/prj" }
$key = "$prj/keys/${prefix}_txt_files.txt".Replace('/', '\')
$ndir = "$prj/txt"
$tmp = if (($IsWindows) -or ($env:OS -eq 'Windows_NT')) { "$env:TEMP/notes/$prefix" } else { "/tmp/notes/$prefix" }
$notes = "$tmp/notes.tar.gz.age".Replace('\', '/')
function clean_dir ([string] $dir) {
  if (Test-Path -LiteralPath $dir -PathType Container -ErrorAction SilentlyContinue) {
    Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue
  }
}

if (!(Test-Path -LiteralPath "$key" -PathType Leaf -ErrorAction SilentlyContinue)) {
  Write-Error 'Key file not found'
  exit 1
}

try {
  # Clean previous if exist
  clean_dir "$tmp"
  New-Item -ItemType Directory -Path $tmp -Force -ErrorAction SilentlyContinue

  # Download encrypted file
  rclone -v -u -l copy "pwdb:notes/$prefix" "$tmp"

  if (!(Test-Path -Verbose -LiteralPath "$notes" -PathType Any -ErrorAction SilentlyContinue)) {
    Write-Error 'notes file could not be downloaded'
    exit 1
  }

  # If already a txt directory, move it from this location
  if (Test-Path -LiteralPath $ndir -ErrorAction SilentlyContinue) {
    Write-Warning 'txt directory exist, overriding with new'
    # $date = (Get-Date -Format 'o').Replace(':', '@')
    $date = (Get-Date).ToUniversalTime().ToString('o').Replace(':', '@')
    $backup = "${ndir}_${date}"
    Move-Item -LiteralPath "$ndir" -Destination "$backup" -ErrorAction Stop
    Write-Warning "backup: $backup"
  }

  # Create directory if it doesn't exist
  New-Item -ItemType Directory -Path "$ndir" -Force -ErrorAction SilentlyContinue

  # Decript files
  age --decrypt -i "$key" "$notes" | tar -xvz -C "$ndir"
} finally {
  clean_dir "$tmp"
}
