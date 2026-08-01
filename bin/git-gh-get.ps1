#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Download files from GitHub without cloning.
.DESCRIPTION
  Downloads individual files or entire directories from GitHub repositories
  without needing to clone them.

  Backends (in priority order): gh CLI, curl, wget, Invoke-WebRequest.

  Supports GitHub URLs, raw URLs (raw.githubusercontent.com), and the short
  form "username/repo/path". GitHub's blob/tree/raw path components are
  optional; a leading branch or tag is detected when possible.
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
.PARAMETER Gh
  Use the gh CLI when it is available. This is the default.
.PARAMETER NoGh
  Skip the gh CLI and use curl, wget, or Invoke-WebRequest.
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
             username/repo/main/path/to/file.txt
             username/repo/blob/main/path/to/file.txt
             https://github.com/user/repo/blob/main/path/to/file.txt
             https://github.com/user/repo/main/path/to/file.txt
             https://raw.githubusercontent.com/user/repo/main/path/to/file.txt
           blob/tree/raw are optional. Without one, a matching branch or tag
           prefix is used; otherwise the path is read from the default branch.
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

Ambiguities:
  A matching branch/tag prefix wins over a same-named default-branch path.
  Use blob/<default-ref>/path to force default-branch path interpretation.
  If ref lookup is unavailable, markerless input uses the default branch; an
  explicit ref containing "/" may be split after its first component.
  A leading 7-40 character hexadecimal component is treated as a commit SHA.
  When a branch and tag share a name, the branch is preferred.

Examples:
  git gh-get username/repo/src/main.js
  git gh-get username/repo/main/src/main.js
  git gh-get https://github.com/user/repo/blob/main/README.md ./docs/
  git gh-get https://github.com/user/repo/main/README.md ./docs/
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
# matching-refs API. If AssumeRef is true, an unresolved value falls back to
# treating its first component as the ref. Otherwise, an unresolved value is a
# path on the repository's default branch. Requires $GhOwner and $GhRepo.
function Resolve-RefPath {
  param(
    [string]$Remaining,
    [bool]$AssumeRef = $true
  )
  $Remaining = $Remaining.TrimEnd('/')

  if (-not $Remaining) {
    $script:GhRef = ''; $script:GhPath = ''; return
  }

  $rparts = @($Remaining -split '/')

  if ($AssumeRef -and $rparts.Count -eq 1) {
    $script:GhRef = $rparts[0]; $script:GhPath = ''; return
  }

  # SHA fingerprint: 7-40 hex chars → first segment is the complete ref
  if ($rparts[0] -match '^[0-9a-f]{7,40}$') {
    $script:GhRef  = $rparts[0]
    $script:GhPath = if ($rparts.Count -gt 1) {
      ($rparts[1..($rparts.Count-1)] -join '/').TrimEnd('/')
    } else { '' }
    return
  }

  $first    = $rparts[0]
  $token    = $env:GITHUB_TOKEN
  $headers  = @{}
  if ($token) { $headers['Authorization'] = "Bearer $token" }

  $foundRef  = ''
  $foundPath = ''

  # Keep the longest match across both namespaces. Branches win a tie because
  # they are visited first.
  foreach ($refType in 'heads','tags') {
    $refs = $null
    try {
      if (Get-HasGh) {
        $rawRefs = gh api "repos/$GhOwner/$GhRepo/git/matching-refs/$refType/$first" 2>$null
        if ($LASTEXITCODE -eq 0 -and $rawRefs) {
          $refs = ($rawRefs -join "`n") | ConvertFrom-Json
        } else {
          $refs = @()
        }
      } else {
        $refs = Invoke-RestMethod `
          -Uri "$GithubApi/repos/$GhOwner/$GhRepo/git/matching-refs/$refType/$first" `
          -Headers $headers -ErrorAction Stop
      }
    } catch { $refs = @() }

    foreach ($item in @($refs)) {
      if (-not $item.ref) { continue }
      $strip   = "refs/$refType/"
      $refName = if ($item.ref.StartsWith($strip)) { $item.ref.Substring($strip.Length) } else { $item.ref }

      if ($Remaining -ceq $refName -and $refName.Length -gt $foundRef.Length) {
        $foundRef = $refName; $foundPath = ''; break
      } elseif (
        $Remaining.StartsWith("$refName/", [System.StringComparison]::Ordinal) -and
        $refName.Length -gt $foundRef.Length
      ) {
        $foundRef  = $refName
        $foundPath = $Remaining.Substring($refName.Length + 1)
      }
    }
  }

  if ($foundRef) {
    $script:GhRef  = $foundRef
    $script:GhPath = $foundPath.TrimEnd('/')
  } elseif ($AssumeRef) {
    # An explicit tree/blob/raw component (or the raw-content host) tells us
    # that a ref is present even when lookup is unavailable.
    $script:GhRef  = $rparts[0]
    $script:GhPath = if ($rparts.Count -gt 1) {
      ($rparts[1..($rparts.Count-1)] -join '/').TrimEnd('/')
    } else { '' }
  } else {
    $script:GhRef  = ''
    $script:GhPath = $Remaining
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

  if ($parts.Count -gt 3 -and $seg -in 'blob','tree','raw') {
    $remaining = if ($parts.Count -gt 3) { $parts[3..($parts.Count-1)] -join '/' } else { '' }
    Resolve-RefPath $remaining $true
  } elseif ($parts.Count -gt 2) {
    $remaining = $parts[2..($parts.Count-1)] -join '/'
    Resolve-RefPath $remaining $false
  } else {
    $script:GhRef  = ''
    $script:GhPath = ''
  }
}

function Parse-RawUrl {
  param([string]$Url)
  $u = $Url.TrimEnd('/')
  $u = $u -replace '^https?://raw\.githubusercontent\.com/', ''

  $parts = $u -split '/'
  $script:GhOwner = if ($parts.Count -gt 0) { $parts[0] } else { '' }
  $script:GhRepo  = if ($parts.Count -gt 1) { $parts[1] } else { '' }
  $remaining      = if ($parts.Count -gt 2) { $parts[2..($parts.Count-1)] -join '/' } else { '' }
  Resolve-RefPath $remaining $true
}

function Parse-ShortForm {
  param([string]$Source)
  $s = $Source -replace '^\.[\\/]', '' -replace '^[\\/]', '' -replace '\.git$', '' -replace '[\\/]$', ''
  $parts = $s -split '[\\/]'

  if ($parts.Count -lt 2) { Die "Invalid source: expected username/repo/... format" }

  $script:GhOwner = $parts[0]
  $script:GhRepo  = $parts[1]

  $seg = if ($parts.Count -gt 2) { $parts[2] } else { '' }
  if ($parts.Count -gt 3 -and $seg -in 'blob','tree','raw') {
    # GitHub URL path without domain: owner/repo/blob/ref/path
    $remaining = if ($parts.Count -gt 3) { $parts[3..($parts.Count-1)] -join '/' } else { '' }
    Resolve-RefPath $remaining $true
  } elseif ($parts.Count -gt 2) {
    $remaining = $parts[2..($parts.Count-1)] -join '/'
    Resolve-RefPath $remaining $false
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

function Invoke-GhApiToFile {
  param(
    [string]$Endpoint,
    [string]$Output
  )

  # gh api has no output-file option. Stream native stdout directly to disk so
  # binary files are not decoded and re-encoded by the PowerShell pipeline.
  $ghCommand = Get-Command gh -CommandType Application -ErrorAction SilentlyContinue
  if (-not $ghCommand) { Die 'gh CLI is not available' }

  $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
  $startInfo.FileName = $ghCommand.Source
  $startInfo.UseShellExecute = $false
  $startInfo.RedirectStandardOutput = $true
  foreach ($argument in @('api', $Endpoint, '-H', 'Accept: application/vnd.github.raw+json')) {
    $startInfo.ArgumentList.Add($argument)
  }

  $process = [System.Diagnostics.Process]::new()
  $process.StartInfo = $startInfo
  $outputStream = $null
  $failure = ''
  $exitCode = -1

  try {
    $outputStream = [System.IO.File]::Create($Output)
    if (-not $process.Start()) { throw 'Could not start gh CLI' }
    $process.StandardOutput.BaseStream.CopyTo($outputStream)
    $process.WaitForExit()
    $exitCode = $process.ExitCode
  } catch {
    $failure = $_.Exception.Message
  } finally {
    if ($outputStream) { $outputStream.Dispose() }
    $process.Dispose()
  }

  if ($failure) { Die "gh download failed: $failure" }
  if ($exitCode -ne 0) { Die "gh download failed with exit code $exitCode" }
}

function Download-File {
  param([string]$Path, [string]$Output)
  $token = $env:GITHUB_TOKEN

  if (Get-HasGh) {
    $encodedRef = [System.Uri]::EscapeDataString($GhRef)
    $apiPath = "repos/$GhOwner/$GhRepo/contents/$Path`?ref=$encodedRef"
    Invoke-GhApiToFile $apiPath $Output
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
  $encodedRef = [System.Uri]::EscapeDataString($GhRef)
  $tree = Invoke-ApiJson "repos/$GhOwner/$GhRepo/git/trees/$encodedRef`?recursive=1"

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
