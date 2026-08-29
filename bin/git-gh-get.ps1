#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Download files from Git forges without cloning.
.DESCRIPTION
  Downloads individual files or directories from GitHub and public GitLab,
  Forgejo, and Gitea repositories. Existing GitHub shortcuts are preserved.
.PARAMETER Source
  A native forge URL, or a hostless native path identified by -Forge.
.PARAMETER Dest
  Optional output path. A trailing slash forces directory mode.
.PARAMETER Container
  Download a directory recursively instead of a single file.
.PARAMETER Forge
  Forge hostname or name for a hostless source, for example codeberg.org.
.PARAMETER Gh
  Use gh for GitHub when available. This is a no-op for other forges.
.PARAMETER NoGh
  Skip gh for GitHub. This is a no-op for other forges.
.PARAMETER DryRun
  Print each resolved URL and destination without downloading.
.PARAMETER Color
  Select auto, always, or never for Gum-formatted dry-run output.
#>

. (Join-Path $PSScriptRoot 'lib/GitForge.ps1')

$PROG = 'git-gh-get'
$GithubApi = 'https://api.github.com'

$script:ForgeType = ''
$script:ForgeHost = ''
$script:ForgeOrigin = ''
$script:ForgeOption = ''
$script:OptionForgeType = ''
$script:OptionForgeHost = ''
$script:OptionForgeOrigin = ''
$script:RepositoryPath = ''
$script:SourceRef = ''
$script:SourceRefKind = ''
$script:SourceOid = ''
$script:SourcePath = ''
$script:RemoteUrl = ''
$script:UseGh = $true
$script:DryRun = $false
$script:ColorMode = 'auto'
$script:DryRunUrls = [System.Collections.Generic.List[string]]::new()
$script:DryRunDestinations = [System.Collections.Generic.List[string]]::new()
$script:DryRunWarningPaths = [System.Collections.Generic.List[string]]::new()

function Write-Info { param([string]$Message); [Console]::Error.WriteLine("${PROG}: $Message") }
function Die { param([string]$Message); Write-Info $Message; exit 1 }

function Show-Help {
  @'
Usage: git gh-get <source> [dest] [options]

Download a file or directory from GitHub or a public GitLab, Forgejo, or Gitea
repository without cloning it.

Arguments:
  source   A native forge URL, or a path whose forge is supplied by --forge.
           Existing GitHub shortcuts remain supported.

           GitHub:
             username/repo/path/to/file.txt
             https://github.com/user/repo/blob/main/path/to/file.txt
             https://raw.githubusercontent.com/user/repo/main/path/to/file.txt

           GitLab (nested groups are supported):
             https://gitlab.com/group/repo/-/blob/main/path/to/file.txt
             https://gitlab.com/group/subgroup/repo/-/tree/main/path
             --forge gitlab.com group/repo/-/raw/main/path/to/file.txt

           Forgejo/Gitea:
             https://codeberg.org/owner/repo/src/branch/main/path/to/file.txt
             https://gitea.com/owner/repo/src/tag/v1.0.0/path/to/file.txt
             --forge codeberg.org owner/repo/src/branch/main/path/to/file.txt

  dest     Output path (default: current directory).
             Trailing slash  -> save inside directory, preserve original name.
             Existing dir    -> save inside directory, preserve original name.
             Non-existing    -> use as the output filename (parent dirs created).

Options:
  -c, -Container, --container   Download a directory recursively
  --dry-run, -DryRun            Print resolved URLs and destinations
  --color=<mode>                Dry-run table mode: auto, always, or never.
                                auto uses gum on a TTY when available; always
                                uses gum when available even if redirected;
                                never emits parseable TSV.
  --forge, -Forge <host|name>   Identify the forge for a hostless source
  --gh, -Gh                     Use gh for GitHub if available (default)
  --no-gh, -NoGh                Skip gh for GitHub
                                (both gh options are no-ops off GitHub)
  -h, -Help, --help             Show this help

Environment:
  GITHUB_TOKEN   Personal access token for private GitHub repositories

Notes:
  Non-GitHub support currently targets public repositories. Native blob/raw/tree
  URL forms are supported; ambiguous markerless non-GitHub file shortcuts are not.
  A matching branch/tag prefix wins over a same-named default-branch path.
  A leading 7-40 character hexadecimal component is treated as a commit SHA.
  When a branch and tag share a name, the branch is preferred.

Examples:
  git gh-get username/repo/src/main.js
  git gh-get https://gitlab.com/group/repo/-/blob/main/README.md ./docs/
  git gh-get --forge codeberg.org owner/repo/src/branch/main/README.md
  git gh-get -c https://codeberg.org/owner/repo/src/branch/main/docs ./docs/
  git gh-get --dry-run https://gitlab.com/group/repo/-/raw/main/file.txt
'@
}

# ── Argument parsing ──────────────────────────────────────────────────────────

$Positionals = [System.Collections.Generic.List[string]]::new()
$Container = $false
$Help = $false
$InputArguments = @($args)

for ($index = 0; $index -lt $InputArguments.Count; $index++) {
  $argument = [string]$InputArguments[$index]
  $key = ($argument -replace '^--', '-').ToLowerInvariant()

  if ($argument -eq '--') {
    for ($rest = $index + 1; $rest -lt $InputArguments.Count; $rest++) {
      $Positionals.Add([string]$InputArguments[$rest])
    }
    break
  } elseif ($key -in @('-h', '-help') -or $argument -eq 'help') {
    $Help = $true
  } elseif ($key -in @('-c', '-container')) {
    $Container = $true
  } elseif ($key -in @('-dry-run', '-dryrun')) {
    $script:DryRun = $true
  } elseif ($key -eq '-color') {
    if ($index + 1 -ge $InputArguments.Count) { Die 'Missing value for --color' }
    $index++
    $script:ColorMode = ([string]$InputArguments[$index]).ToLowerInvariant()
  } elseif ($argument -match '^-{1,2}color=(.*)$') {
    $script:ColorMode = $Matches[1].ToLowerInvariant()
  } elseif ($key -eq '-gh') {
    $script:UseGh = $true
  } elseif ($key -in @('-no-gh', '-nogh')) {
    $script:UseGh = $false
  } elseif ($key -eq '-forge') {
    if ($index + 1 -ge $InputArguments.Count) { Die 'Missing value for --forge' }
    $index++
    $script:ForgeOption = [string]$InputArguments[$index]
  } elseif ($argument -match '^--forge=(.*)$') {
    $script:ForgeOption = $Matches[1]
  } elseif ($key.StartsWith('-')) {
    Die "Unknown option: $argument"
  } else {
    $Positionals.Add($argument)
  }
}

if ($Help) { Show-Help; exit 0 }
if ($script:ColorMode -notin @('auto', 'always', 'never')) {
  Die "Invalid --color value '$($script:ColorMode)' (expected auto, always, or never)"
}
if ($Positionals.Count -eq 0) { Show-Help; exit 1 }
if ($Positionals.Count -gt 2) { Die 'Too many positional arguments' }

$SourceArg = $Positionals[0]
$DestArg = if ($Positionals.Count -gt 1) { $Positionals[1] } else { '' }

# ── Client and forge helpers ──────────────────────────────────────────────────

function Get-HasGh {
  $script:ForgeType -eq 'github' -and $script:UseGh -and
    ($null -ne (Get-Command gh -CommandType Application -ErrorAction SilentlyContinue))
}

function Get-CurlCommand {
  Get-Command curl -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
}

function Get-WgetCommand {
  Get-Command wget -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
}

function Get-GithubHeaders {
  $headers = @{}
  if ($env:GITHUB_TOKEN) { $headers.Authorization = "Bearer $env:GITHUB_TOKEN" }
  return $headers
}

function Resolve-ForgeOption {
  if (-not $script:ForgeOption) { return }

  $specification = $script:ForgeOption.TrimEnd('/')
  $lookup = $specification
  $uri = $null
  if ([Uri]::TryCreate($specification, [UriKind]::Absolute, [ref]$uri) -and $uri.Scheme -in @('http', 'https')) {
    $lookup = $uri.Host
  }

  $resolver = Find-GitForgeNamedResolver $lookup
  if ($null -eq $resolver) {
    Die "Unknown forge '$($script:ForgeOption)' (use a known host or github/gitlab/forgejo/gitea)"
  }

  $script:OptionForgeType = ([string]$resolver.Forge).ToLowerInvariant()
  if ($null -ne $uri -and $uri.IsAbsoluteUri) {
    $script:OptionForgeOrigin = $uri.GetLeftPart([UriPartial]::Authority).TrimEnd('/')
    $script:OptionForgeHost = $uri.Host.ToLowerInvariant()
  } else {
    $script:OptionForgeOrigin = ([string]$resolver.WebOrigin).TrimEnd('/')
    $originUri = [Uri]$script:OptionForgeOrigin
    $script:OptionForgeHost = $originUri.Host.ToLowerInvariant()
  }
}

function Set-SourceForge {
  param([string]$HostName, [string]$Origin)

  $resolver = Find-GitForgeResolver $HostName
  if ($null -ne $resolver) {
    $detectedType = ([string]$resolver.Forge).ToLowerInvariant()
    $detectedOrigin = ([string]$resolver.WebOrigin).TrimEnd('/')
  } elseif ($script:OptionForgeType) {
    $detectedType = $script:OptionForgeType
    $detectedOrigin = ''
  } else {
    Die "Unsupported forge host '$HostName'; pass --forge with a supported forge type"
  }

  if ($script:OptionForgeType -and $detectedType -ne $script:OptionForgeType) {
    Die "Source host '$HostName' does not match --forge '$($script:ForgeOption)'"
  }

  $script:ForgeType = $detectedType
  $script:ForgeHost = $HostName.ToLowerInvariant()
  $script:ForgeOrigin = if ($Origin) { $Origin.TrimEnd('/') } else { $detectedOrigin }
}

function Join-UrlParts {
  param([object[]]$Parts, [int]$Start = 0, [int]$Count = -1)
  if ($Start -ge $Parts.Count) { return '' }
  if ($Count -lt 0 -or $Start + $Count -gt $Parts.Count) { $Count = $Parts.Count - $Start }
  if ($Count -le 0) { return '' }
  return @($Parts[$Start..($Start + $Count - 1)]) -join '/'
}

# ── Ref discovery ─────────────────────────────────────────────────────────────

function Get-GithubMatchingRecords {
  param([string]$First, [string]$OnlyKind = '')

  $owner = $script:RepositoryPath.Split('/')[0]
  $repository = $script:RepositoryPath.Split('/')[1]
  foreach ($refType in @('heads', 'tags')) {
    $kind = if ($refType -eq 'heads') { 'branch' } else { 'tag' }
    if ($OnlyKind -and $OnlyKind -ne $kind) { continue }
    $items = @()
    try {
      if (Get-HasGh) {
        $raw = @(& gh api "repos/$owner/$repository/git/matching-refs/$refType/$First" 2>$null) -join "`n"
        if ($LASTEXITCODE -eq 0 -and $raw) { $items = @(ConvertFrom-Json $raw) }
      } else {
        $items = @(Invoke-RestMethod `
          -Uri "$GithubApi/repos/$owner/$repository/git/matching-refs/$refType/$First" `
          -Headers (Get-GithubHeaders) -ErrorAction Stop)
      }
    } catch { $items = @() }

    foreach ($item in $items) {
      if (-not $item.ref) { continue }
      $prefix = "refs/$refType/"
      $name = if ($item.ref.StartsWith($prefix)) { $item.ref.Substring($prefix.Length) } else { $item.ref }
      [pscustomobject]@{ Kind = $kind; Name = $name; Oid = ''; Peeled = $false }
    }
  }
}

function Get-GitMatchingRecords {
  param([string]$First, [string]$OnlyKind = '')

  foreach ($refType in @('heads', 'tags')) {
    $kind = if ($refType -eq 'heads') { 'branch' } else { 'tag' }
    if ($OnlyKind -and $OnlyKind -ne $kind) { continue }

    $lines = @(& git ls-remote "--$refType" $script:RemoteUrl "refs/$refType/$First*" 2>$null)
    if ($LASTEXITCODE -ne 0) { continue }
    foreach ($line in $lines) {
      if ($line -notmatch '^(?<oid>\S+)\s+(?<ref>.+)$') { continue }
      $fullRef = $Matches.ref
      $peeled = $fullRef.EndsWith('^{}')
      if ($peeled) { $fullRef = $fullRef.Substring(0, $fullRef.Length - 3) }
      $prefix = "refs/$refType/"
      if (-not $fullRef.StartsWith($prefix)) { continue }
      [pscustomobject]@{
        Kind = $kind
        Name = $fullRef.Substring($prefix.Length)
        Oid = $Matches.oid
        Peeled = $peeled
      }
    }
  }
}

function Get-MatchingRefRecords {
  param([string]$First, [string]$OnlyKind = '')
  if ($script:ForgeType -eq 'github') {
    Get-GithubMatchingRecords $First $OnlyKind
  } else {
    Get-GitMatchingRecords $First $OnlyKind
  }
}

function Resolve-RefPath {
  param(
    [string]$Remaining,
    [bool]$AssumeRef = $true,
    [string]$OnlyKind = ''
  )

  $remainingValue = $Remaining.TrimEnd('/')
  $script:SourceRef = ''
  $script:SourceRefKind = ''
  $script:SourceOid = ''
  $script:SourcePath = ''
  if (-not $remainingValue) { return }

  $parts = @($remainingValue -split '/')
  $first = $parts[0]
  if ($first -match '^[0-9a-fA-F]{7,40}$') {
    $script:SourceRef = $first
    $script:SourceRefKind = 'commit'
    $script:SourceOid = $first
    $script:SourcePath = Join-UrlParts $parts 1
    return
  }

  if ($script:ForgeType -eq 'github' -and $AssumeRef -and $parts.Count -eq 1) {
    $script:SourceRef = $first
    $script:SourceRefKind = if ($OnlyKind) { $OnlyKind } else { 'ref' }
    return
  }

  $foundRef = ''
  $foundPath = ''
  $foundKind = ''
  $foundOid = ''
  foreach ($record in @(Get-MatchingRefRecords $first $OnlyKind)) {
    $candidatePath = $null
    if ($remainingValue -ceq $record.Name) {
      $candidatePath = ''
    } elseif ($remainingValue.StartsWith("$($record.Name)/", [StringComparison]::Ordinal)) {
      $candidatePath = $remainingValue.Substring($record.Name.Length + 1)
    } else {
      continue
    }

    if ($record.Name.Length -gt $foundRef.Length) {
      $foundRef = $record.Name
      $foundPath = $candidatePath
      $foundKind = $record.Kind
      $foundOid = $record.Oid
    } elseif ($record.Name -ceq $foundRef -and $record.Kind -eq $foundKind -and $record.Peeled) {
      $foundOid = $record.Oid
    }
  }

  if ($foundRef) {
    $script:SourceRef = $foundRef
    $script:SourceRefKind = $foundKind
    $script:SourceOid = $foundOid
    $script:SourcePath = $foundPath.TrimEnd('/')
  } elseif ($AssumeRef) {
    $script:SourceRef = $first
    $script:SourceRefKind = if ($OnlyKind) { $OnlyKind } else { 'ref' }
    $script:SourcePath = Join-UrlParts $parts 1
  } else {
    $script:SourcePath = $remainingValue
  }
}

# ── Native URL parsers ────────────────────────────────────────────────────────

function Parse-GithubPath {
  param([string]$Path, [bool]$RawHost = $false)
  $parts = @($Path.TrimStart('/') -split '/')
  if ($parts.Count -lt 2) { Die 'Invalid GitHub source: expected owner/repository' }
  $parts[1] = $parts[1] -replace '\.git$', ''
  $script:RepositoryPath = "$($parts[0])/$($parts[1])"
  $script:RemoteUrl = "$($script:ForgeOrigin)/$($script:RepositoryPath).git"

  if ($RawHost) {
    Resolve-RefPath (Join-UrlParts $parts 2) $true
  } elseif ($parts.Count -gt 3 -and $parts[2] -in @('blob', 'tree', 'raw')) {
    Resolve-RefPath (Join-UrlParts $parts 3) $true
  } elseif ($parts.Count -gt 2) {
    Resolve-RefPath (Join-UrlParts $parts 2) $false
  } else {
    $script:SourceRef = ''; $script:SourcePath = ''
  }
}

function Parse-GitlabPath {
  param([string]$Path)
  $value = $Path.TrimStart('/')
  if ($value -match '^(?<repository>.+)/-/(?:blob|raw|tree)/(?<remaining>.+)$') {
    $repository = $Matches.repository.TrimEnd('/') -replace '\.git$', ''
    if (@($repository -split '/').Count -lt 2) { Die 'Invalid GitLab source: expected namespace/repository before /-/' }
    $script:RepositoryPath = $repository
    $script:RemoteUrl = "$($script:ForgeOrigin)/$($script:RepositoryPath).git"
    Resolve-RefPath $Matches.remaining $true
  } else {
    $parts = @($value -split '/')
    if ($parts.Count -lt 2) { Die 'Invalid GitLab source: expected namespace/repository' }
    $script:RepositoryPath = $value.TrimEnd('/') -replace '\.git$', ''
    $script:RemoteUrl = "$($script:ForgeOrigin)/$($script:RepositoryPath).git"
    $script:SourceRef = ''; $script:SourcePath = ''
  }
}

function Parse-ForgejoPath {
  param([string]$Path)
  $value = $Path.TrimStart('/')
  if ($value -match '^(?<owner>[^/]+)/(?<repository>[^/]+?)(?:\.git)?/(?<marker>src|raw)/(?<kind>branch|tag|commit)/(?<remaining>.+)$') {
    $script:RepositoryPath = "$($Matches.owner)/$($Matches.repository)"
    $script:RemoteUrl = "$($script:ForgeOrigin)/$($script:RepositoryPath).git"
    if ($Matches.kind -eq 'commit') {
      $parts = @($Matches.remaining -split '/')
      $script:SourceRef = $parts[0]
      $script:SourceRefKind = 'commit'
      $script:SourceOid = $parts[0]
      $script:SourcePath = Join-UrlParts $parts 1
    } else {
      Resolve-RefPath $Matches.remaining $true $Matches.kind
    }
  } elseif ($value -match '^(?<owner>[^/]+)/(?<repository>[^/]+?)(?:\.git)?/?$') {
    $script:RepositoryPath = "$($Matches.owner)/$($Matches.repository)"
    $script:RemoteUrl = "$($script:ForgeOrigin)/$($script:RepositoryPath).git"
    $script:SourceRef = ''; $script:SourcePath = ''
  } else {
    Die 'Unsupported Forgejo/Gitea source; use /src/{branch|tag|commit}/ref/path or /raw/{branch|tag|commit}/ref/path'
  }
}

function Parse-Source {
  param([string]$Source)
  $inputValue = $Source -replace '[?#].*$', ''
  Resolve-ForgeOption

  if ($inputValue -match '^https?://raw\.githubusercontent\.com/') {
    $uri = [Uri]$inputValue
    Set-SourceForge 'github.com' "$($uri.Scheme)://github.com"
    Parse-GithubPath (ConvertFrom-GitForgeUrlPath $uri.AbsolutePath.TrimStart('/')) $true
    return
  }

  $uri = $null
  if ([Uri]::TryCreate($inputValue, [UriKind]::Absolute, [ref]$uri) -and $uri.Scheme -in @('http', 'https')) {
    Set-SourceForge $uri.Host $uri.GetLeftPart([UriPartial]::Authority)
    $path = ConvertFrom-GitForgeUrlPath $uri.AbsolutePath.TrimStart('/')
  } else {
    $normalized = $inputValue.Replace('\', '/').TrimStart('./').TrimStart('/')
    $first = @($normalized -split '/')[0]
    $resolver = if ($first.Contains('.')) { Find-GitForgeResolver $first } else { $null }
    if ($null -ne $resolver) {
      Set-SourceForge $first ([string]$resolver.WebOrigin)
      $path = $normalized.Substring([Math]::Min($normalized.Length, $first.Length + 1))
    } elseif ($script:OptionForgeType) {
      $script:ForgeType = $script:OptionForgeType
      $script:ForgeHost = $script:OptionForgeHost
      $script:ForgeOrigin = $script:OptionForgeOrigin
      $path = $normalized
    } else {
      $script:ForgeType = 'github'
      $script:ForgeHost = 'github.com'
      $script:ForgeOrigin = 'https://github.com'
      $path = $normalized
    }
  }

  $path = $path.TrimEnd('/')
  switch ($script:ForgeType) {
    'github' { Parse-GithubPath $path }
    'gitlab' { Parse-GitlabPath $path }
    { $_ -in @('forgejo', 'gitea') } { Parse-ForgejoPath $path }
    default { Die "Downloads are not implemented for forge '$($script:ForgeType)'" }
  }
}

# ── HTTP and default ref resolution ───────────────────────────────────────────

function Invoke-HttpText {
  param([string]$Url)
  $curl = Get-CurlCommand
  if ($null -ne $curl) {
    $content = @(& $curl.Source -fsSL $Url 2>$null) -join "`n"
    if ($LASTEXITCODE -ne 0) { throw "curl request failed: $Url" }
    return $content
  }
  $wget = Get-WgetCommand
  if ($null -ne $wget) {
    $content = @(& $wget.Source -qO- $Url 2>$null) -join "`n"
    if ($LASTEXITCODE -ne 0) { throw "wget request failed: $Url" }
    return $content
  }
  throw 'No HTTP client found. Install curl or wget.'
}

function Invoke-GithubApiJson {
  param([string]$Endpoint)
  try {
    if (Get-HasGh) {
      $raw = @(& gh api $Endpoint) -join "`n"
      if ($LASTEXITCODE -ne 0) { throw "gh api failed for $Endpoint" }
      return ConvertFrom-Json $raw
    }
    return Invoke-RestMethod -Uri "$GithubApi/$Endpoint" -Headers (Get-GithubHeaders) -ErrorAction Stop
  } catch {
    Die "GitHub API request failed: $_"
  }
}

function Get-DefaultRef {
  if ($script:ForgeType -eq 'github') {
    $data = Invoke-GithubApiJson "repos/$($script:RepositoryPath)"
    if (-not $data.default_branch) { Die "Could not determine default branch for $($script:RepositoryPath)" }
    $script:SourceRefKind = 'branch'
    return [string]$data.default_branch
  }

  $lines = @(& git ls-remote --symref $script:RemoteUrl HEAD 2>$null)
  if ($LASTEXITCODE -ne 0) { $lines = @() }
  $branch = ''
  $oid = ''
  foreach ($line in $lines) {
    if ($line -match '^ref:\s+refs/heads/(?<branch>.+)\s+HEAD$') { $branch = $Matches.branch }
    elseif ($line -match '^(?<oid>[0-9a-fA-F]+)\s+HEAD$') { $oid = $Matches.oid }
  }
  if (-not $branch) { Die "Could not determine default branch for $($script:ForgeHost)/$($script:RepositoryPath)" }
  $script:SourceRefKind = 'branch'
  $script:SourceOid = $oid
  return $branch
}

function Ensure-SourceOid {
  if ($script:SourceOid) { return }
  if ($script:SourceRefKind -eq 'commit' -and $script:SourceRef -match '^[0-9a-fA-F]{7,40}$') {
    $script:SourceOid = $script:SourceRef
    return
  }
  foreach ($record in @(Get-MatchingRefRecords ($script:SourceRef -split '/')[0] $script:SourceRefKind)) {
    if ($record.Name -ceq $script:SourceRef -and (-not $script:SourceOid -or $record.Peeled)) {
      $script:SourceOid = $record.Oid
    }
  }
}

# ── Output path resolution ────────────────────────────────────────────────────

function Resolve-FileOutput {
  param([string]$Dest, [string]$Filename)
  if (-not $Dest) { return Join-Path '.' $Filename }
  if ($Dest -match '[\\/]$') { return Join-Path $Dest $Filename }
  if (Test-Path -LiteralPath $Dest -PathType Container) { return Join-Path $Dest $Filename }
  return $Dest
}

function Resolve-DirOutput {
  param([string]$Dest, [string]$DirName)
  if (-not $Dest) { return Join-Path '.' $DirName }
  if ($Dest -match '[\\/]$') { return Join-Path $Dest $DirName }
  if (Test-Path -LiteralPath $Dest -PathType Container) { return Join-Path $Dest $DirName }
  return $Dest
}

# ── Download and tree adapters ────────────────────────────────────────────────

function Get-ResolvedFileUrl {
  param([string]$Path)
  try {
    return Get-GitForgeRawFileUrl `
      $script:ForgeType $script:ForgeOrigin $script:RepositoryPath $script:SourceRef $Path
  } catch {
    Die "Could not construct a raw URL for $($script:ForgeType): $_"
  }
}

function Add-DownloadPlan {
  param([string]$Path, [string]$Output)
  $script:DryRunUrls.Add((Get-ResolvedFileUrl $Path))
  $script:DryRunDestinations.Add($Output)
  if (Test-Path -LiteralPath $Output) {
    $script:DryRunWarningPaths.Add($Output)
  }
}

function ConvertTo-MarkdownCodeSpan {
  param([AllowEmptyString()][string]$Value)
  $fence = '`'
  while ($Value.Contains($fence)) { $fence += '`' }
  return "$fence $Value $fence"
}

function ConvertTo-MarkdownTableCodeSpan {
  param([AllowEmptyString()][string]$Value)
  $escaped = $Value.Replace('\', '\\').Replace('|', '\|')
  return ConvertTo-MarkdownCodeSpan $escaped
}

function Get-GumCommand {
  foreach ($commandName in @('gum', 'gum.exe')) {
    $command = Get-Command $commandName -CommandType Application -ErrorAction SilentlyContinue |
      Select-Object -First 1
    if ($null -ne $command) { return $command }
  }
  return $null
}

function Get-FoldCommand {
  foreach ($commandName in @('fold', 'fold.exe')) {
    $command = Get-Command $commandName -CommandType Application -ErrorAction SilentlyContinue |
      Select-Object -First 1
    if ($null -ne $command) { return $command }
  }
  return $null
}

function Get-DryRunOutputWidth {
  $width = 0
  if (-not [Console]::IsOutputRedirected) {
    try { $width = [Console]::WindowWidth } catch { $width = 0 }
  }
  if ($width -lt 20 -and $env:COLUMNS -match '^\d+$') { $width = [int]$env:COLUMNS }
  if ($width -lt 20) { $width = 120 }
  return $width
}

function Split-PrettyValue {
  param(
    [AllowEmptyString()][string]$Value,
    [int]$Width,
    [AllowNull()][object]$FoldCommand
  )
  if ($null -eq $FoldCommand) { return ,$Value }

  $prepared = $Value
  $useSeparatorBreaks = $Value.Contains('/') -or $Value.Contains('\')
  if ($useSeparatorBreaks) {
    if ($Value -match '^(?<prefix>[A-Za-z][A-Za-z0-9+.-]*://)(?<remaining>.*)$') {
      # Preserve :// as a unit while still offering a preferred break before
      # the hostname when the output column is especially narrow.
      $prepared = $Matches.prefix + ' ' + $Matches.remaining.Replace('/', '/ ').Replace('\', '\ ')
    } else {
      $prepared = $Value.Replace('/', '/ ').Replace('\', '\ ')
    }
  }

  if ($useSeparatorBreaks) {
    $lines = @($prepared | & $FoldCommand.Source -s -w $Width)
  } else {
    $lines = @($prepared | & $FoldCommand.Source -w $Width)
  }
  if ($LASTEXITCODE -ne 0) { return ,$Value }
  if ($lines.Count -eq 0) { return ,'' }
  foreach ($line in $lines) { ([string]$line).Replace('/ ', '/').Replace('\ ', '\') }
}

function Write-TsvDownloadPlan {
  [Console]::Out.WriteLine("Download files`tDestination")
  for ($index = 0; $index -lt $script:DryRunUrls.Count; $index++) {
    $url = $script:DryRunUrls[$index]
    $destination = $script:DryRunDestinations[$index]
    [Console]::Out.WriteLine("$url`t$destination")
  }
  foreach ($warningPath in $script:DryRunWarningPaths) {
    Write-Info "Warning: $warningPath already exists and would be overwritten"
  }
}

function Get-MarkdownDownloadPlan {
  param([AllowNull()][object]$FoldCommand)
  $width = Get-DryRunOutputWidth
  $columnWidth = [Math]::Max(20, [Math]::Floor(($width - 16) / 2))
  $lines = [System.Collections.Generic.List[string]]::new()
  $lines.Add('| Download files | Destination |')
  $lines.Add('| -------------- | ----------- |')

  for ($index = 0; $index -lt $script:DryRunUrls.Count; $index++) {
    # Keep the resolved URL contiguous so terminal URL detection can recognize
    # it as one clickable link. Destination paths may still be folded.
    $urlChunks = @($script:DryRunUrls[$index])
    $destinationChunks = @(Split-PrettyValue $script:DryRunDestinations[$index] $columnWidth $FoldCommand)
    $rowCount = [Math]::Max($urlChunks.Count, $destinationChunks.Count)
    for ($row = 0; $row -lt $rowCount; $row++) {
      $urlCell = if ($row -lt $urlChunks.Count) { ConvertTo-MarkdownTableCodeSpan $urlChunks[$row] } else { '' }
      $destinationCell = if ($row -lt $destinationChunks.Count) {
        ConvertTo-MarkdownTableCodeSpan $destinationChunks[$row]
      } else { '' }
      $lines.Add("| $urlCell | $destinationCell |")
    }
  }

  foreach ($warningPath in $script:DryRunWarningPaths) {
    $lines.Add('')
    $lines.Add('> **Warning:** Destination already exists and would be overwritten.')
    foreach ($chunk in @(Split-PrettyValue $warningPath $columnWidth $FoldCommand)) {
      $lines.Add('')
      $lines.Add("> $(ConvertTo-MarkdownCodeSpan $chunk)")
    }
  }
  return $lines
}

function Write-PrettyDownloadPlan {
  param([object]$GumCommand)
  $foldCommand = Get-FoldCommand
  $markdown = @(Get-MarkdownDownloadPlan $foldCommand)
  $previousColorForce = $env:CLICOLOR_FORCE
  try {
    $env:CLICOLOR_FORCE = '1'
    $formatted = @($markdown | & $GumCommand.Source format --language markdown)
    $exitCode = $LASTEXITCODE
  } finally {
    if ($null -eq $previousColorForce) {
      Remove-Item Env:CLICOLOR_FORCE -ErrorAction SilentlyContinue
    } else {
      $env:CLICOLOR_FORCE = $previousColorForce
    }
  }
  if ($exitCode -ne 0) { return $false }
  foreach ($line in $formatted) { [Console]::Out.WriteLine($line) }
  return $true
}

function Write-DownloadPlan {
  if ($script:DryRunUrls.Count -eq 0) { return }
  $gumCommand = $null
  if ($script:ColorMode -eq 'always' -or (
    $script:ColorMode -eq 'auto' -and -not [Console]::IsOutputRedirected
  )) {
    $gumCommand = Get-GumCommand
  }

  if ($null -ne $gumCommand) {
    $rendered = Write-PrettyDownloadPlan $gumCommand
    if ($rendered) { return }
  }
  Write-TsvDownloadPlan
}

function Invoke-GhApiToFile {
  param([string]$Endpoint, [string]$Output)
  $ghCommand = Get-Command gh -CommandType Application -ErrorAction SilentlyContinue
  if (-not $ghCommand) { Die 'gh CLI is not available' }

  $startInfo = [Diagnostics.ProcessStartInfo]::new()
  $startInfo.FileName = $ghCommand.Source
  $startInfo.UseShellExecute = $false
  $startInfo.RedirectStandardOutput = $true
  foreach ($argument in @('api', $Endpoint, '-H', 'Accept: application/vnd.github.raw+json')) {
    $startInfo.ArgumentList.Add($argument)
  }

  $process = [Diagnostics.Process]::new()
  $process.StartInfo = $startInfo
  $stream = $null
  $failure = ''
  $exitCode = -1
  try {
    $stream = [IO.File]::Create($Output)
    if (-not $process.Start()) { throw 'Could not start gh CLI' }
    $process.StandardOutput.BaseStream.CopyTo($stream)
    $process.WaitForExit()
    $exitCode = $process.ExitCode
  } catch {
    $failure = $_.Exception.Message
  } finally {
    if ($stream) { $stream.Dispose() }
    $process.Dispose()
  }
  if ($failure) { Die "gh download failed: $failure" }
  if ($exitCode -ne 0) { Die "gh download failed with exit code $exitCode" }
}

function Download-File {
  param([string]$Path, [string]$Output)

  if (Get-HasGh) {
    $parts = @($script:RepositoryPath -split '/')
    $encodedPath = ConvertTo-GitForgeUrlPath $Path
    $encodedRef = ConvertTo-GitForgeUrlComponent $script:SourceRef
    Invoke-GhApiToFile "repos/$($parts[0])/$($parts[1])/contents/$encodedPath`?ref=$encodedRef" $Output
    return
  }

  $url = Get-ResolvedFileUrl $Path
  $curl = Get-CurlCommand
  if ($null -ne $curl) {
    $curlArgs = @('-fsSL', $url, '-o', $Output)
    if ($script:ForgeType -eq 'github' -and $env:GITHUB_TOKEN) {
      $curlArgs += @('-H', "Authorization: Bearer $env:GITHUB_TOKEN")
    }
    & $curl.Source @curlArgs
    if ($LASTEXITCODE -ne 0) { Die "curl download failed for: $Path" }
    return
  }

  $wget = Get-WgetCommand
  if ($null -ne $wget) {
    $wgetArgs = @('-qO', $Output, $url)
    if ($script:ForgeType -eq 'github' -and $env:GITHUB_TOKEN) {
      $wgetArgs += @("--header=Authorization: Bearer $env:GITHUB_TOKEN")
    }
    & $wget.Source @wgetArgs
    if ($LASTEXITCODE -ne 0) { Die "wget download failed for: $Path" }
    return
  }

  if ($script:ForgeType -ne 'github') { Die 'No HTTP client found. Install curl or wget.' }
  try {
    Invoke-WebRequest -Uri $url -Headers (Get-GithubHeaders) -OutFile $Output -ErrorAction Stop
  } catch {
    Die "Download failed for ${Path}: $_"
  }
}

function Get-GithubContainerPaths {
  param([string]$Path)
  $encodedRef = ConvertTo-GitForgeUrlComponent $script:SourceRef
  $tree = Invoke-GithubApiJson "repos/$($script:RepositoryPath)/git/trees/$encodedRef`?recursive=1"
  if ($tree.truncated) { Write-Info 'Warning: tree is truncated; some files may be missing' }
  foreach ($item in @($tree.tree)) {
    if ($item.type -eq 'blob' -and (-not $Path -or $item.path -ceq $Path -or $item.path.StartsWith("$Path/"))) {
      [string]$item.path
    }
  }
}

function Get-GitlabContainerPaths {
  param([string]$Path)
  $repository = ConvertTo-GitForgeUrlComponent $script:RepositoryPath
  $ref = ConvertTo-GitForgeUrlComponent $script:SourceRef
  $base = "$($script:ForgeOrigin)/api/v4/projects/$repository/repository/tree?recursive=true&per_page=100&ref=$ref"
  if ($Path) { $base += "&path=$(ConvertTo-GitForgeUrlComponent $Path)" }

  $page = 1
  do {
    try { $items = @(ConvertFrom-Json (Invoke-HttpText "$base&page=$page")) }
    catch { Die "Could not list GitLab tree at '$Path': $_" }
    foreach ($item in $items) {
      if ($item.type -eq 'blob') { [string]$item.path }
    }
    $page++
  } while ($items.Count -ge 100)
}

function Get-ForgejoContainerPaths {
  param([string]$Path)
  Ensure-SourceOid
  $treeish = if ($script:SourceOid) { $script:SourceOid } else { $script:SourceRef }
  $encodedTreeish = ConvertTo-GitForgeUrlComponent $treeish
  $encodedRepository = ConvertTo-GitForgeUrlPath $script:RepositoryPath
  $base = "$($script:ForgeOrigin)/api/v1/repos/$encodedRepository/git/trees/$encodedTreeish`?recursive=true&per_page=1000"
  $page = 1
  do {
    try { $tree = ConvertFrom-Json (Invoke-HttpText "$base&page=$page") }
    catch { Die "Could not list $($script:ForgeType) tree at '$Path': $_" }
    foreach ($item in @($tree.tree)) {
      if ($item.type -eq 'blob' -and (-not $Path -or $item.path -ceq $Path -or $item.path.StartsWith("$Path/"))) {
        [string]$item.path
      }
    }
    $page++
    if ($page -gt 1000) { Die 'Forgejo/Gitea tree pagination exceeded 1000 pages' }
  } while ($tree.truncated)
}

function Get-ContainerPaths {
  param([string]$Path)
  switch ($script:ForgeType) {
    'github' { Get-GithubContainerPaths $Path }
    'gitlab' { Get-GitlabContainerPaths $Path }
    { $_ -in @('forgejo', 'gitea') } { Get-ForgejoContainerPaths $Path }
    default { Die "Directory downloads are not implemented for forge '$($script:ForgeType)'" }
  }
}

function Download-Container {
  param([string]$OutputDir)
  $path = $script:SourcePath.TrimEnd('/')
  Write-Info "Fetching repository tree ($($script:ForgeHost)/$($script:RepositoryPath) @ $($script:SourceRef))..."
  $blobs = @(Get-ContainerPaths $path)
  if ($blobs.Count -eq 0) { Die "No files found at '$path'; check the source URL" }

  $count = 0
  foreach ($blobPath in $blobs) {
    if ($path -and $blobPath.StartsWith("$path/", [StringComparison]::Ordinal)) {
      $relative = $blobPath.Substring($path.Length + 1)
    } elseif ($path -and $blobPath -ceq $path) {
      $relative = Split-Path $blobPath -Leaf
    } else {
      $relative = $blobPath
    }
    if (-not $relative) { $relative = Split-Path $blobPath -Leaf }
    $output = Join-Path $OutputDir $relative

    if ($script:DryRun) {
      Add-DownloadPlan $blobPath $output
    } else {
      $parent = Split-Path $output -Parent
      if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
      Write-Info "downloading $relative"
      Download-File $blobPath $output
    }
    $count++
  }

  if ($script:DryRun) {
    Write-DownloadPlan
    Write-Info "Dry run: $count file(s) would be downloaded to $OutputDir"
  } else {
    Write-Info "Downloaded $count file(s) to $OutputDir"
  }
}

# ── Main ──────────────────────────────────────────────────────────────────────

Parse-Source $SourceArg
if (-not $script:RepositoryPath) { Die "Could not parse repository from: $SourceArg" }

if (-not $script:SourceRef) {
  Write-Info 'Resolving default branch...'
  $script:SourceRef = Get-DefaultRef
}

if ($Container) {
  $repositoryName = @($script:RepositoryPath -split '/')[-1]
  $dirName = if ($script:SourcePath) { Split-Path $script:SourcePath.TrimEnd('/') -Leaf } else { $repositoryName }
  if (-not $dirName -or $dirName -eq '.') { $dirName = $repositoryName }
  $outputDir = Resolve-DirOutput $DestArg $dirName
  if (-not $script:DryRun) { New-Item -ItemType Directory -Force -Path $outputDir | Out-Null }
  Download-Container $outputDir
} else {
  if (-not $script:SourcePath) { Die 'No file path in source; use -Container to download a directory' }
  $filename = Split-Path $script:SourcePath -Leaf
  if (-not $filename -or $filename -eq '.') { Die "Could not determine filename from: $($script:SourcePath)" }
  $output = Resolve-FileOutput $DestArg $filename
  if ($script:DryRun) {
    Add-DownloadPlan $script:SourcePath $output
    Write-DownloadPlan
  } else {
    $parent = Split-Path $output -Parent
    if ($parent -and $parent -ne '.') { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
    Download-File $script:SourcePath $output
    Write-Info "Downloaded to $output"
  }
}
