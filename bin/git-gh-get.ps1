#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Download files from GitHub without cloning.
.DESCRIPTION
  Downloads individual files or entire directories from GitHub repositories
  without needing to clone them.

  Backends (in priority order): gh CLI, curl, wget, Invoke-WebRequest.

  Supports GitHub URLs (github.com/blob/tree), raw URLs
  (raw.githubusercontent.com), and the short form "username/repo/path".
.PARAMETER Source
  GitHub path in one of these forms:
    username/repo/path/to/file.txt
    https://github.com/user/repo/blob/main/path/to/file.txt
    https://raw.githubusercontent.com/user/repo/main/path/to/file.txt
.PARAMETER Dest
  Optional output path. Trailing slash forces directory mode.
  If omitted, downloads to the current directory using the original filename.
.PARAMETER Container
  Download a directory recursively instead of a single file.
.PARAMETER Help
  Show this help message and exit.
.EXAMPLE
  git gh-get username/repo/src/main.js
.EXAMPLE
  git gh-get https://github.com/user/repo/blob/main/README.md ./docs/
.EXAMPLE
  git gh-get username/repo/src/ ./local-src/ -Container
.EXAMPLE
  git gh-get -c https://github.com/user/repo/tree/main/cli/src/bin ./bin/
.NOTES
  Set the GITHUB_TOKEN environment variable for private repositories.
#>

$PROG       = 'git-gh-get'
$GithubApi  = 'https://api.github.com'
$GhOwner    = ''; $GhRepo = ''; $GhRef = ''; $GhPath = ''
$UseGh      = $true  # set to $false via --no-gh / -NoGh to skip gh CLI

# ── Helpers ───────────────────────────────────────────────────────────────────

function Write-Info { param([string]$msg); [Console]::Error.WriteLine("${PROG}: $msg") }
function Die        { param([string]$msg); Write-Info $msg; exit 1 }

function Show-Help {
  @'
Usage: git gh-get <source> [dest] [options]

Download a file or directory from GitHub without cloning.

Arguments:
  source   GitHub source, one of:
             username/repo/path/to/file.txt
             https://github.com/user/repo/blob/main/path/to/file.txt
             https://raw.githubusercontent.com/user/repo/main/path/to/file.txt
  dest     Output path (default: current directory).
             Trailing slash  -> save inside directory, preserve original name.
             Existing dir    -> save inside directory, preserve original name.
             Non-existing    -> use as the output filename (parent dirs created).

Options:
  -c, -Container, --container   Download directory recursively
  --gh, -Gh                     Use gh CLI if available (default)
  --no-gh, -NoGh                Skip gh CLI; use curl/wget/Invoke-WebRequest
  -h, -Help, --help             Show this help

Environment:
  GITHUB_TOKEN   Personal access token for private repos

Examples:
  git gh-get username/repo/src/main.js
  git gh-get https://github.com/user/repo/blob/main/README.md ./docs/
  git gh-get -Container username/repo/src/ ./local-src/
'@
}

# ── Arg parsing ───────────────────────────────────────────────────────────────

$Positional = [System.Collections.Generic.List[string]]::new()
$Container  = $false
$Help       = $false

foreach ($a in $args) {
  # Normalize --flag to -flag (PowerShell may or may not pass double-dash through)
  $key = $a -replace '^--', '-'
  if     ($key -in '-h', '-help' -or $a -eq 'help') { $Help      = $true }
  elseif ($key -in '-c', '-container')               { $Container = $true }
  elseif ($key -in '-gh')                            { $UseGh     = $true }
  elseif ($key -in '-no-gh', '-nogh')                { $UseGh     = $false }
  elseif ($key.StartsWith('-'))                      { Die "Unknown option: $a" }
  else                                               { $Positional.Add($a) }
}

if ($Help) { Show-Help; exit 0 }
if ($Positional.Count -eq 0) { Show-Help; exit 1 }

$SourceArg = $Positional[0]
$DestArg   = if ($Positional.Count -gt 1) { $Positional[1] } else { '' }

# ── Input parsing ─────────────────────────────────────────────────────────────

# Resolve an ambiguous "ref[/with/slashes]/path/to/file" string using GitHub's
# matching-refs API.  Requires $GhOwner and $GhRepo to already be set.
function Resolve-RefPath {
  param([string]$Remaining)
  $Remaining = $Remaining.TrimEnd('/')
  $rparts = $Remaining -split '/'

  if ($rparts.Count -eq 0 -or $Remaining -eq '') {
    $script:GhRef = ''; $script:GhPath = ''; return
  }
  if ($rparts.Count -eq 1) {
    $script:GhRef = $rparts[0]; $script:GhPath = ''; return
  }

  # SHA fingerprint: 7-40 hex chars → first segment is the complete ref
  if ($rparts[0] -match '^[0-9a-f]{7,40}$') {
    $script:GhRef  = $rparts[0]
    $script:GhPath = ($rparts[1..($rparts.Count-1)] -join '/').TrimEnd('/')
    return
  }

  $first    = $rparts[0]
  $token    = $env:GITHUB_TOKEN
  $headers  = @{}
  if ($token) { $headers['Authorization'] = "Bearer $token" }

  $foundRef  = ''
  $foundPath = ''

  foreach ($refType in 'heads','tags') {
    $refs = $null
    try {
      if (Get-HasGh) {
        $refs = (gh api "repos/$GhOwner/$GhRepo/git/matching-refs/$refType/$first") | ConvertFrom-Json
      } else {
        $refs = Invoke-RestMethod `
          -Uri "$GithubApi/repos/$GhOwner/$GhRepo/git/matching-refs/$refType/$first" `
          -Headers $headers -ErrorAction Stop
      }
    } catch { $refs = @() }

    foreach ($item in $refs) {
      $strip   = "refs/$refType/"
      $refName = if ($item.ref.StartsWith($strip)) { $item.ref.Substring($strip.Length) } else { $item.ref }

      if ($Remaining -eq $refName) {
        $foundRef = $refName; $foundPath = ''; break
      } elseif ($Remaining.StartsWith("$refName/") -and $refName.Length -gt $foundRef.Length) {
        $foundRef  = $refName
        $foundPath = $Remaining.Substring($refName.Length + 1)
      }
    }

    if ($foundRef) { break }
  }

  if ($foundRef) {
    $script:GhRef  = $foundRef
    $script:GhPath = $foundPath.TrimEnd('/')
  } else {
    # Fallback: first segment is ref, rest is path
    $script:GhRef  = $rparts[0]
    $script:GhPath = ($rparts[1..($rparts.Count-1)] -join '/').TrimEnd('/')
  }
}

function Parse-GithubUrl {
  param([string]$Url)
  $u = $Url.TrimEnd('/')
  $u = $u -replace '^https?://github\.com/', ''
  $u = $u -replace '^github\.com/', ''

  $parts = $u -split '/'
  $script:GhOwner = $parts[0]
  $script:GhRepo  = $parts[1]
  $seg            = if ($parts.Count -gt 2) { $parts[2] } else { '' }

  if ($seg -in 'blob','tree','raw') {
    $remaining = if ($parts.Count -gt 3) { $parts[3..($parts.Count-1)] -join '/' } else { '' }
    Resolve-RefPath $remaining
  } else {
    $script:GhRef  = ''
    $script:GhPath = ($parts[2..($parts.Count-1)] -join '/').TrimEnd('/')
  }
}

function Parse-RawUrl {
  param([string]$Url)
  $u = $Url.TrimEnd('/')
  $u = $u -replace '^https?://raw\.githubusercontent\.com/', ''

  $parts = $u -split '/'
  $script:GhOwner = $parts[0]
  $script:GhRepo  = $parts[1]
  $script:GhRef   = $parts[2]
  $script:GhPath  = ($parts[3..($parts.Count-1)] -join '/').TrimEnd('/')
}

function Parse-ShortForm {
  param([string]$Input)
  $s = $Input -replace '^\.[\\/]', '' -replace '^[\\/]', '' -replace '\.git$', '' -replace '[\\/]$', ''
  $parts = $s -split '[\\/]'

  if ($parts.Count -lt 2) { Die "Invalid source: expected username/repo/... format" }

  $script:GhOwner = $parts[0]
  $script:GhRepo  = $parts[1]

  $seg = if ($parts.Count -gt 2) { $parts[2] } else { '' }
  if ($seg -in 'blob','tree','raw') {
    # GitHub URL path without domain: owner/repo/blob/ref/path
    $remaining = if ($parts.Count -gt 3) { $parts[3..($parts.Count-1)] -join '/' } else { '' }
    Resolve-RefPath $remaining
  } elseif ($parts.Count -gt 2) {
    $script:GhRef  = ''
    $script:GhPath = ($parts[2..($parts.Count-1)] -join '/')
  } else {
    $script:GhRef  = ''
    $script:GhPath = ''
  }
}

function Parse-Source {
  param([string]$s)
  if ($s -match '^https?://raw\.githubusercontent\.com/') {
    Parse-RawUrl $s
  } elseif ($s -match '^https?://github\.com/' -or $s -match '^github\.com/') {
    Parse-GithubUrl $s
  } else {
    Parse-ShortForm $s
  }
}

# ── HTTP client detection ─────────────────────────────────────────────────────

function Get-HasGh {
  $UseGh -and ($null -ne (Get-Command gh -ErrorAction SilentlyContinue))
}

function Get-HasCurl {
  $cmd = Get-Command curl -ErrorAction SilentlyContinue
  # Exclude PowerShell's curl alias (maps to Invoke-WebRequest)
  $null -ne $cmd -and $cmd.CommandType -eq 'Application'
}

function Get-HasWget {
  $cmd = Get-Command wget -ErrorAction SilentlyContinue
  $null -ne $cmd -and $cmd.CommandType -eq 'Application'
}

function Get-AuthHeaders {
  $h = @{}
  if ($env:GITHUB_TOKEN) { $h['Authorization'] = "Bearer $env:GITHUB_TOKEN" }
  return $h
}

# ── GitHub API ────────────────────────────────────────────────────────────────

function Invoke-ApiJson {
  param([string]$Endpoint)
  if (Get-HasGh) {
    return (gh api $Endpoint) | ConvertFrom-Json
  }
  $headers = Get-AuthHeaders
  try {
    return Invoke-RestMethod -Uri "$GithubApi/$Endpoint" -Headers $headers -ErrorAction Stop
  } catch {
    Die "API request failed: $_"
  }
}

function Get-DefaultBranch {
  $data = Invoke-ApiJson "repos/$GhOwner/$GhRepo"
  if (-not $data.default_branch) { Die "Could not determine default branch for $GhOwner/$GhRepo" }
  return $data.default_branch
}

# ── Output path resolution ────────────────────────────────────────────────────

function Resolve-FileOutput {
  param([string]$Dest, [string]$Filename)
  if (-not $Dest) {
    return ".\$Filename"
  }
  if ($Dest -match '[\\/]$') {
    New-Item -ItemType Directory -Force -Path $Dest | Out-Null
    return Join-Path $Dest $Filename
  }
  if (Test-Path $Dest -PathType Container) {
    return Join-Path $Dest $Filename
  }
  $parent = Split-Path $Dest -Parent
  if ($parent -and $parent -ne '.') {
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
  }
  return $Dest
}

function Resolve-DirOutput {
  param([string]$Dest, [string]$DirName)
  if (-not $Dest) {
    return ".\$DirName"
  }
  if ($Dest -match '[\\/]$') {
    return Join-Path $Dest $DirName
  }
  if (Test-Path $Dest -PathType Container) {
    return Join-Path $Dest $DirName
  }
  return $Dest
}

# ── Download ──────────────────────────────────────────────────────────────────

function Download-File {
  param([string]$Path, [string]$Output)
  $token = $env:GITHUB_TOKEN

  if (Get-HasGh) {
    $apiPath = "repos/$GhOwner/$GhRepo/contents/$Path`?ref=$GhRef"
    gh api $apiPath -H 'Accept: application/vnd.github.raw+json' --output $Output
    if ($LASTEXITCODE -ne 0) { Die "gh download failed for: $Path" }
    return
  }

  $url = "https://raw.githubusercontent.com/$GhOwner/$GhRepo/$GhRef/$Path"
  $headers = Get-AuthHeaders

  if (Get-HasCurl) {
    $curlArgs = @('-fsSL', $url, '-o', $Output)
    if ($token) { $curlArgs += @('-H', "Authorization: Bearer $token") }
    & curl @curlArgs
    if ($LASTEXITCODE -ne 0) { Die "curl download failed for: $Path" }
    return
  }

  if (Get-HasWget) {
    $wgetArgs = @('-qO', $Output, $url)
    if ($token) { $wgetArgs += @("--header=Authorization: Bearer $token") }
    & wget @wgetArgs
    if ($LASTEXITCODE -ne 0) { Die "wget download failed for: $Path" }
    return
  }

  try {
    Invoke-WebRequest -Uri $url -Headers $headers -OutFile $Output -ErrorAction Stop
  } catch {
    Die "Download failed for ${Path}: $_"
  }
}

function Download-Container {
  param([string]$OutputDir)
  $path = $GhPath.TrimEnd('/')

  Write-Info "Fetching repository tree ($GhOwner/$GhRepo @ $GhRef)..."
  $tree = Invoke-ApiJson "repos/$GhOwner/$GhRepo/git/trees/$GhRef`?recursive=1"

  if ($tree.truncated) {
    Write-Info "Warning: tree is truncated — large repo, some files may be missing"
  }

  $blobs = $tree.tree | Where-Object {
    $_.type -eq 'blob' -and (
      -not $path -or $_.path -eq $path -or $_.path.StartsWith("$path/")
    )
  }

  if (-not $blobs) {
    Die "No files found at '$path' — check the path or use the full GitHub URL"
  }

  $count = 0
  foreach ($blob in $blobs) {
    $rel = if ($path) { $blob.path.Substring([Math]::Min($blob.path.Length, $path.Length + 1)) } else { $blob.path }
    if (-not $rel) { $rel = Split-Path $blob.path -Leaf }

    $out    = Join-Path $OutputDir $rel
    $outDir = Split-Path $out -Parent
    if ($outDir) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }

    Write-Info "v $rel"
    Download-File $blob.path $out
    $count++
  }

  Write-Info "Downloaded $count file(s) to $OutputDir"
}

# ── Main ──────────────────────────────────────────────────────────────────────

Parse-Source $SourceArg

if (-not $GhOwner) { Die "Could not parse owner from: $SourceArg" }
if (-not $GhRepo)  { Die "Could not parse repo from: $SourceArg" }

if (-not $GhRef) {
  Write-Info "Resolving default branch..."
  $GhRef = Get-DefaultBranch
}

if ($Container) {
  $dirName = if ($GhPath) { Split-Path $GhPath.TrimEnd('/') -Leaf } else { $GhRepo }
  if (-not $dirName -or $dirName -eq '.') { $dirName = $GhRepo }

  $outDir = Resolve-DirOutput $DestArg $dirName
  New-Item -ItemType Directory -Force -Path $outDir | Out-Null
  Download-Container $outDir
} else {
  if (-not $GhPath) {
    Die "No file path in source — use -Container to download a directory"
  }
  $filename = Split-Path $GhPath -Leaf
  if (-not $filename -or $filename -eq '.') {
    Die "Could not determine filename from: $GhPath"
  }
  $output = Resolve-FileOutput $DestArg $filename
  Download-File $GhPath $output
  Write-Info "Downloaded to $output"
}
