#!/usr/bin/env pwsh

$user_config_cache = if ($env:user_config_cache) { $env:user_config_cache } else { "$HOME/.cache/.user_config_cache" }
$manpages_dir = "$user_config_cache/manpages"

function Prepare-Files () {
  if (Test-Path -LiteralPath $manpages_dir -PathType Container -ErrorAction SilentlyContinue) {
    Remove-Item -LiteralPath $manpages_dir -Recurse -Force
  }

  # Prepare files
  New-Item -Path $manpages_dir -ItemType Directory -Force
}

function Download-PagesTldp () {
  $base_url = 'https://tldp.org/manpages'
  $url = "$base_url/man.html"
  $tar_name = ''

  (Invoke-WebRequest -Uri $url).Links | ForEach-Object {
    if ($_.href -like 'http*.tar.gz') {
      # noop
    } elseif ($_.href -like '*.tar.gz') {
      $tar_name = $_.href
    }
  }

  if (!$tar_name) {
    Write-Error 'Could not fetch tar file'
    exit 1
  }

  $tar_url = "$base_url/$tar_name"
  $out_dir = [IO.Path]::GetFileNameWithoutExtension($tar_name)

  # Remove old if exists
  if (Test-Path -LiteralPath "$manpages_dir/$out_dir") {
    Remove-Item -Recurse -Force -LiteralPath "$manpages_dir/$out_dir"
  }
  if (Test-Path -LiteralPath "$manpages_dir/$tar_name") {
    Remove-Item -Recurse -Force -LiteralPath "$manpages_dir/$tar_name"
  }

  # Download tar
  Invoke-WebRequest -Uri $tar_url -OutFile "$manpages_dir/$tar_name"

  Push-Location $manpages_dir
  tar -xvzf "$manpages_dir/$tar_name"
  Pop-Location

  # Remove temporary file
  Remove-Item -LiteralPath "$manpages_dir/$tar_name" -Force
}

function Download-PagesLinux () {
  $repo_url = 'http://git.kernel.org/pub/scm/docs/man-pages/man-pages'
  $repo_dest = "$manpages_dir/man-pages"
  git clone --depth 1 --no-checkout $repo_url $repo_dest

  Push-Location -LiteralPath $repo_dest

  git sparse-checkout set --cone 'man'
  git checkout

  Pop-Location
}

Prepare-Files
Download-PagesTldp
Download-PagesLinux
