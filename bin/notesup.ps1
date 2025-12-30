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
$key = "$prj/keys/${prefix}_txt_files.txt"
$ndir = "$prj/txt"
$tmp = if (($IsWindows) -or ($env:OS -eq 'Windows_NT')) { "$env:TEMP/notes/$prefix" } else { "/tmp/notes/$prefix" }
$notes = "$tmp/notes.tar.gz.age"
function clean_dir ([string] $dir) {
  if (Test-Path -LiteralPath $dir -PathType Container -ErrorAction SilentlyContinue) {
    Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue
  }
}

if (!(Test-Path -LiteralPath $key -PathType Leaf -ErrorAction SilentlyContinue)) {
  Write-Error 'Key file not found'
  exit 1
}

 $public_key = Get-Content -LiteralPath "$key" | Select-Object -Index 1 | ForEach-Object { $_.Split(': ')[1] }

if (!$public_key) {
  Write-Error 'Could not extract public key'
  exit 1
}

try {
  # Clean previous if exist
  clean_dir $tmp

  # Create directory if it doesn't exist
  New-Item -ItemType Directory -Path $tmp -Force -ErrorAction SilentlyContinue

  # tar Create, Verbose, gZip
  tar -cvz --directory "$ndir" . | age -r "$public_key" -o "$notes"

  # Upload files
  rclone -v -u -l copy "$notes" "pwdb:notes/$prefix"
} finally {
  # Clean temporary files
  clean_dir $tmp
}

