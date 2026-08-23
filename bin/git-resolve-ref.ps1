#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Resolve a Git repository reference to its forge URL.
.DESCRIPTION
  Prints the resolved URL by default. Pass --open to launch it instead.
  The GNU-style arguments intentionally match the Bash implementation so the
  command can be called consistently from fzf actions.
#>

$ProgramName = 'git-resolve-ref'

# Custom resolver configuration ------------------------------------------------
#
# Entries are ordered. Host supports PowerShell wildcard syntax. Keep matches
# exact unless a wildcard is intentional. Forge must be github, gitlab,
# forgejo, gitea, or bitbucket-cloud. WebOrigin is optional when the HTTPS
# origin is the same as the Git SSH hostname.
#
# Examples:
#   [pscustomobject]@{ Host = 'github-personal'; Forge = 'github'; WebOrigin = 'https://github.com' }
#   [pscustomobject]@{ Host = 'git.example.com'; Forge = 'forgejo'; WebOrigin = 'https://git.example.com' }
$CustomResolvers = @(
  [pscustomobject]@{ Host = 'github-personal'; Forge = 'github'; WebOrigin = 'https://github.com' }
  [pscustomobject]@{ Host = 'github-work';     Forge = 'github'; WebOrigin = 'https://github.com' }
)

# Built-in public forge mappings. Custom entries always take precedence.
$BuiltinResolvers = @(
  [pscustomobject]@{ Host = 'github.com';    Forge = 'github';          WebOrigin = 'https://github.com' }
  [pscustomobject]@{ Host = 'gitlab.com';    Forge = 'gitlab';          WebOrigin = 'https://gitlab.com' }
  [pscustomobject]@{ Host = 'codeberg.org';  Forge = 'forgejo';         WebOrigin = 'https://codeberg.org' }
  [pscustomobject]@{ Host = 'gitea.com';     Forge = 'gitea';           WebOrigin = 'https://gitea.com' }
  [pscustomobject]@{ Host = 'bitbucket.org'; Forge = 'bitbucket-cloud'; WebOrigin = 'https://bitbucket.org' }
)

function Fail {
  param([string]$Message)
  [Console]::Error.WriteLine("${ProgramName}: $Message")
  exit 1
}

function Test-Truthy {
  param([AllowEmptyString()][string]$Value)
  return $Value -in @('1', 'true', 'TRUE', 'yes', 'YES', 'on', 'ON')
}

function Write-DebugMessage {
  param([string]$Message)
  if ($script:DebugEnabled) {
    [Console]::Error.WriteLine("${ProgramName}: $Message")
  }
}

function Show-Help {
  @'
Usage: git-resolve-ref.ps1 [options] <kind> [value]

Resolve a Git repository reference to a forge URL. The URL is printed to
stdout unless --open is supplied.

Kinds:
  repository              Repository root (alias: repo)
  remote <name>            Root of a specific remote repository
  branch <name>            Local branch
  remote-branch <name>     Remote-tracking branch, e.g. origin/topic
  tag <name>               Tag source tree
  commit <revision>        Commit page
  ref <revision>           Best-effort generic ref, resolved as a commit
  stash <revision>         Stash commit page
  file <path>              File at HEAD, or at the revision passed to --at

Options:
  --open                   Open the URL instead of printing it
  -C, --repository <path>  Run Git relative to another repository
  --remote <name>          Override automatic remote selection
  --remote-url <url>       Resolve using an explicit Git remote URL
  --forge <name>           Force a forge URL builder
  --web-url <url>          Override the repository browser root URL
  --at <revision>          Revision used by the file kind
  --opener <path>          Program that receives the URL with --open
  --ssh <path-or-command>  SSH command used to expand aliases with -G
  --no-ssh-alias           Do not expand SSH Host aliases
  --debug                  Print resolution decisions to stderr
  -h, --help               Show this help
  --                       Stop option parsing

Forge names:
  github, gitlab, forgejo, gitea, bitbucket-cloud

Environment:
  GIT_RESOLVE_REF_REMOTE
  GIT_RESOLVE_REF_REMOTE_URL
  GIT_RESOLVE_REF_FORGE
  GIT_RESOLVE_REF_WEB_URL
  GIT_RESOLVE_REF_OPENER
  GIT_RESOLVE_REF_SSH
  GIT_RESOLVE_REF_NO_SSH_ALIAS
  GIT_RESOLVE_REF_DEBUG

Examples:
  git-resolve-ref.ps1 branch main
  git-resolve-ref.ps1 --open remote-branch origin/feature/example
  git-resolve-ref.ps1 --at v1.0.0 file docs/guide.md
  git-resolve-ref.ps1 --remote upstream commit HEAD
'@
}

$OpenUrl           = $false
$RepositoryPath    = ''
$RemoteName        = [string]$env:GIT_RESOLVE_REF_REMOTE
$RemoteUrl         = [string]$env:GIT_RESOLVE_REF_REMOTE_URL
$ForgeOverride     = [string]$env:GIT_RESOLVE_REF_FORGE
$WebUrlOverride    = [string]$env:GIT_RESOLVE_REF_WEB_URL
$Opener            = [string]$env:GIT_RESOLVE_REF_OPENER
$SshOverride       = [string]$env:GIT_RESOLVE_REF_SSH
$AtRef             = ''
$NoSshAlias        = Test-Truthy ([string]$env:GIT_RESOLVE_REF_NO_SSH_ALIAS)
$script:DebugEnabled = Test-Truthy ([string]$env:GIT_RESOLVE_REF_DEBUG)
$RemoteOptionSet   = $false
$Positionals       = [System.Collections.Generic.List[string]]::new()
$InputArguments    = @($args)

for ($index = 0; $index -lt $InputArguments.Count; $index++) {
  $argument = [string]$InputArguments[$index]
  switch -Regex ($argument) {
    '^--open$' {
      $OpenUrl = $true
      break
    }
    '^(-C|--repository)$' {
      $index++
      if ($index -ge $InputArguments.Count) { Fail "missing value for $argument" }
      $RepositoryPath = [string]$InputArguments[$index]
      break
    }
    '^--repository=(.*)$' { $RepositoryPath = $Matches[1]; break }
    '^--remote$' {
      $index++
      if ($index -ge $InputArguments.Count) { Fail 'missing value for --remote' }
      $RemoteName = [string]$InputArguments[$index]
      $RemoteOptionSet = $true
      break
    }
    '^--remote=(.*)$' {
      $RemoteName = $Matches[1]
      $RemoteOptionSet = $true
      break
    }
    '^--remote-url$' {
      $index++
      if ($index -ge $InputArguments.Count) { Fail 'missing value for --remote-url' }
      $RemoteUrl = [string]$InputArguments[$index]
      break
    }
    '^--remote-url=(.*)$' { $RemoteUrl = $Matches[1]; break }
    '^--forge$' {
      $index++
      if ($index -ge $InputArguments.Count) { Fail 'missing value for --forge' }
      $ForgeOverride = [string]$InputArguments[$index]
      break
    }
    '^--forge=(.*)$' { $ForgeOverride = $Matches[1]; break }
    '^--web-url$' {
      $index++
      if ($index -ge $InputArguments.Count) { Fail 'missing value for --web-url' }
      $WebUrlOverride = [string]$InputArguments[$index]
      break
    }
    '^--web-url=(.*)$' { $WebUrlOverride = $Matches[1]; break }
    '^--at$' {
      $index++
      if ($index -ge $InputArguments.Count) { Fail 'missing value for --at' }
      $AtRef = [string]$InputArguments[$index]
      break
    }
    '^--at=(.*)$' { $AtRef = $Matches[1]; break }
    '^--opener$' {
      $index++
      if ($index -ge $InputArguments.Count) { Fail 'missing value for --opener' }
      $Opener = [string]$InputArguments[$index]
      break
    }
    '^--opener=(.*)$' { $Opener = $Matches[1]; break }
    '^--ssh$' {
      $index++
      if ($index -ge $InputArguments.Count) { Fail 'missing value for --ssh' }
      $SshOverride = [string]$InputArguments[$index]
      break
    }
    '^--ssh=(.*)$' { $SshOverride = $Matches[1]; break }
    '^--no-ssh-alias$' { $NoSshAlias = $true; break }
    '^--debug$' { $script:DebugEnabled = $true; break }
    '^(-h|--help)$' { Show-Help; exit 0 }
    '^--$' {
      for ($rest = $index + 1; $rest -lt $InputArguments.Count; $rest++) {
        $Positionals.Add([string]$InputArguments[$rest])
      }
      $index = $InputArguments.Count
      break
    }
    '^-' { Fail "unknown option: $argument" }
    default { $Positionals.Add($argument) }
  }
}

if ($Positionals.Count -eq 0) {
  Show-Help | ForEach-Object { [Console]::Error.WriteLine($_) }
  exit 1
}
if ($Positionals.Count -gt 2) { Fail 'too many positional arguments' }

$Kind  = $Positionals[0]
$Value = if ($Positionals.Count -gt 1) { $Positionals[1] } else { '' }
if ($Kind -eq 'repo') { $Kind = 'repository' }
if ($Kind -eq 'remote_branch') { $Kind = 'remote-branch' }
if ($Kind -like 'refs/*') { $Kind = 'ref' }

if ($Kind -eq 'repository') {
  if ($Value) { Fail 'repository does not accept a value' }
} elseif ($Kind -in @('remote', 'branch', 'remote-branch', 'tag', 'commit', 'ref', 'stash', 'file')) {
  if (-not $Value) { Fail "$Kind requires a value" }
} else {
  Fail "unsupported kind: $Kind"
}

$script:GitPrefix = @()
if ($RepositoryPath) { $script:GitPrefix = @('-C', $RepositoryPath) }
$script:LastGitExitCode = 0

function Invoke-GitLines {
  param([string[]]$GitArguments)
  try {
    $result = @(& git @script:GitPrefix @GitArguments 2>$null)
    $script:LastGitExitCode = $LASTEXITCODE
    return $result
  } catch {
    $script:LastGitExitCode = 1
    return @()
  }
}

function Invoke-GitText {
  param([string[]]$GitArguments)
  $lines = @(Invoke-GitLines $GitArguments)
  if ($script:LastGitExitCode -ne 0) { return $null }
  return (($lines | ForEach-Object { [string]$_ }) -join "`n").TrimEnd()
}

function Test-GitCommand {
  param([string[]]$GitArguments)
  $null = Invoke-GitLines $GitArguments
  return $script:LastGitExitCode -eq 0
}

$HaveRepository = Test-GitCommand @('rev-parse', '--git-dir')
if (-not $HaveRepository -and -not $RemoteUrl -and -not $WebUrlOverride) {
  Fail 'not in a Git repository; use -C, --remote-url, or --web-url'
}

function Get-RemoteNames {
  if (-not $script:HaveRepository) { return @() }
  return @(Invoke-GitLines @('remote') | ForEach-Object { [string]$_ })
}

function Test-RemoteExists {
  param([string]$Name)
  foreach ($remote in @(Get-RemoteNames)) {
    if ($remote -ceq $Name) { return $true }
  }
  return $false
}

function Get-RemoteFromTrackingRef {
  param([string]$Ref)
  $normalized = $Ref -replace '^refs/remotes/', ''
  $best = ''
  foreach ($remote in @(Get-RemoteNames)) {
    if (
      $normalized.StartsWith("$remote/", [System.StringComparison]::Ordinal) -and
      $remote.Length -gt $best.Length
    ) {
      $best = $remote
    }
  }
  return $best
}

function Get-UpstreamRemoteForBranch {
  param([string]$Branch)
  $normalized = $Branch -replace '^refs/heads/', ''
  $remote = Invoke-GitText @(
    'for-each-ref',
    '--format=%(upstream:remotename)',
    "refs/heads/$normalized"
  )
  if ($remote -eq '.') { return '' }
  return [string]$remote
}

function Get-CurrentBranch {
  if (-not $script:HaveRepository) { return '' }
  $branch = Invoke-GitText @('symbolic-ref', '--quiet', '--short', 'HEAD')
  return [string]$branch
}

function Get-DefaultRemote {
  $branch = Get-CurrentBranch
  if ($branch) {
    $upstreamRemote = Get-UpstreamRemoteForBranch $branch
    if ($upstreamRemote) { return $upstreamRemote }
  }

  if (Test-RemoteExists 'origin') { return 'origin' }
  $remotes = @(Get-RemoteNames)
  if ($remotes.Count -eq 1) { return [string]$remotes[0] }
  return ''
}

$TargetKind  = $Kind
$TargetValue = $Value

switch ($Kind) {
  'remote' {
    if (-not $RemoteOptionSet) { $RemoteName = $Value }
    $TargetKind = 'repository'
    $TargetValue = ''
  }
  'remote-branch' {
    $TargetValue = $Value -replace '^refs/remotes/', ''
    if (-not $RemoteName) { $RemoteName = Get-RemoteFromTrackingRef $TargetValue }
    if ($RemoteName -and $TargetValue.StartsWith("$RemoteName/", [System.StringComparison]::Ordinal)) {
      $TargetValue = $TargetValue.Substring($RemoteName.Length + 1)
    } elseif (-not $RemoteName -and -not $TargetValue.Contains('/')) {
      Fail "remote-branch must include a remote name: $Value"
    } elseif (-not $RemoteName) {
      # Outside a repository there is no configured remote list to consult.
      $TargetValue = $TargetValue.Substring($TargetValue.IndexOf('/') + 1)
    }
  }
  'branch' {
    $TargetValue = $Value -replace '^refs/heads/', ''
    if (-not $RemoteName -and $HaveRepository) {
      $RemoteName = Get-UpstreamRemoteForBranch $TargetValue
    }
  }
  'tag' {
    $TargetValue = $Value -replace '^refs/tags/', ''
  }
}

# When a file is explicitly resolved at a local or remote-tracking branch,
# prefer that branch's remote over the current checkout's upstream.
if ($Kind -eq 'file' -and -not $RemoteName -and $AtRef -and $HaveRepository) {
  if ($AtRef -like 'refs/remotes/*') {
    $RemoteName = Get-RemoteFromTrackingRef $AtRef
  } else {
    $candidateBranch = $AtRef -replace '^refs/heads/', ''
    if (Test-GitCommand @('show-ref', '--verify', '--quiet', "refs/heads/$candidateBranch")) {
      $RemoteName = Get-UpstreamRemoteForBranch $candidateBranch
    }
  }
}

if (-not $RemoteUrl -and -not $WebUrlOverride) {
  if (-not $RemoteName) { $RemoteName = Get-DefaultRemote }
  if (-not $RemoteName) { Fail 'could not select a remote; use --remote or --remote-url' }
  if (-not (Test-RemoteExists $RemoteName)) { Fail "unknown remote: $RemoteName" }
  $RemoteUrl = Invoke-GitText @('remote', 'get-url', $RemoteName)
  if (-not $RemoteUrl) { Fail "could not read URL for remote: $RemoteName" }
}

Write-DebugMessage "remote=$(if ($RemoteName) { $RemoteName } else { '<explicit-url>' })"

function Split-CommandWords {
  param([AllowEmptyString()][string]$Value)
  if ([string]::IsNullOrEmpty($Value)) { return @() }

  $parsed = [System.Collections.Generic.List[string]]::new()
  $current = [System.Text.StringBuilder]::new()
  [char]$quote = [char]0
  $started = $false
  $singleQuote = [char]39
  $doubleQuote = [char]34
  $backslash = [char]92

  for ($index = 0; $index -lt $Value.Length; $index++) {
    [char]$character = $Value[$index]
    if ($quote -ne [char]0) {
      if ($character -eq $quote) {
        $quote = [char]0
        $started = $true
      } elseif ($quote -eq $doubleQuote -and $character -eq $backslash) {
        if ($index + 1 -lt $Value.Length) {
          [char]$next = $Value[$index + 1]
          if (
            [char]::IsWhiteSpace($next) -or
            $next -eq $singleQuote -or
            $next -eq $doubleQuote -or
            $next -eq $backslash
          ) {
            $null = $current.Append($next)
            $index++
          } else {
            $null = $current.Append($character)
          }
        } else {
          $null = $current.Append($character)
        }
        $started = $true
      } else {
        $null = $current.Append($character)
        $started = $true
      }
    } elseif ($character -eq $singleQuote -or $character -eq $doubleQuote) {
      $quote = $character
      $started = $true
    } elseif ($character -eq $backslash) {
      if ($index + 1 -lt $Value.Length) {
        [char]$next = $Value[$index + 1]
        if (
          [char]::IsWhiteSpace($next) -or
          $next -eq $singleQuote -or
          $next -eq $doubleQuote -or
          $next -eq $backslash
        ) {
          $null = $current.Append($next)
          $index++
        } else {
          $null = $current.Append($character)
        }
      } else {
        $null = $current.Append($character)
      }
      $started = $true
    } elseif ([char]::IsWhiteSpace($character)) {
      if ($started) {
        $parsed.Add($current.ToString())
        $null = $current.Clear()
        $started = $false
      }
    } else {
      $null = $current.Append($character)
      $started = $true
    }
  }

  if ($quote -ne [char]0) { return @() }
  if ($started) { $parsed.Add($current.ToString()) }
  return $parsed.ToArray()
}

function Get-EffectiveSshCommand {
  if ($SshOverride) { return $SshOverride }
  if ($env:GIT_SSH_COMMAND) { return [string]$env:GIT_SSH_COMMAND }
  if ($HaveRepository) {
    $configured = Invoke-GitText @('config', '--get', 'core.sshCommand')
    if ($configured) { return $configured }
  }
  if ($env:GIT_SSH) { return [string]$env:GIT_SSH }
  return 'ssh'
}

function Resolve-SshHostnameWith {
  param([string]$Command, [string]$Alias)
  $words = @(Split-CommandWords $Command)
  if ($words.Count -eq 0) { return '' }
  $executable = $words[0]
  $commandArguments = @()
  if ($words.Count -gt 1) { $commandArguments = @($words[1..($words.Count - 1)]) }

  try {
    $output = @(& $executable @commandArguments '-G' $Alias 2>$null)
    if ($LASTEXITCODE -ne 0) { return '' }
  } catch {
    return ''
  }

  foreach ($line in $output) {
    if ([string]$line -match '^\s*hostname\s+(\S+)') {
      return $Matches[1].ToLowerInvariant()
    }
  }
  return ''
}

function Resolve-SshHostname {
  param([string]$Alias)
  $configured = Get-EffectiveSshCommand
  $resolved = Resolve-SshHostnameWith $configured $Alias
  if (-not $resolved -and $configured -ne 'ssh') {
    $resolved = Resolve-SshHostnameWith 'ssh' $Alias
  }
  return $resolved
}

function Find-Resolver {
  param([string]$HostName, [object[]]$Resolvers)
  $candidate = $HostName.ToLowerInvariant()
  foreach ($resolver in @($Resolvers)) {
    if ($candidate -like ([string]$resolver.Host).ToLowerInvariant()) {
      return $resolver
    }
  }
  return $null
}

function Parse-RemoteUrl {
  param([string]$Url)
  $uri = $null
  if (
    [Uri]::TryCreate($Url, [UriKind]::Absolute, [ref]$uri) -and
    $uri.Scheme -in @('http', 'https', 'git', 'ssh')
  ) {
    $transport = $uri.Scheme.ToLowerInvariant()
    $hostName = $uri.Host.ToLowerInvariant()
    $path = $uri.AbsolutePath.TrimStart('/').TrimEnd('/') -replace '\.git$', ''
    $origin = if ($transport -in @('http', 'https')) {
      $uri.GetLeftPart([UriPartial]::Authority)
    } else {
      "https://$hostName"
    }
    if (-not $hostName -or -not $path) { return $null }
    return [pscustomobject]@{
      Transport = $transport
      Host = $hostName
      Path = $path
      Origin = $origin.TrimEnd('/')
    }
  }

  if ($Url -notmatch '^[A-Za-z]:[\\/]' -and $Url -match '^(?:[^@/:]+@)?(?<host>[^/:]+):(?<path>.+)$') {
    $hostName = $Matches['host'].ToLowerInvariant()
    $path = $Matches['path'].TrimStart('/').TrimEnd('/') -replace '\.git$', ''
    if (-not $hostName -or -not $path) { return $null }
    return [pscustomobject]@{
      Transport = 'ssh'
      Host = $hostName
      Path = $path
      Origin = "https://$hostName"
    }
  }
  return $null
}

$MatchedForge  = ''
$MatchedOrigin = ''
$RemoteHost    = ''

if ($WebUrlOverride) {
  $RepositoryWebUrl = $WebUrlOverride.TrimEnd('/')
  $webUri = $null
  if ([Uri]::TryCreate($RepositoryWebUrl, [UriKind]::Absolute, [ref]$webUri)) {
    $RemoteHost = $webUri.Host.ToLowerInvariant()
  }
} else {
  $parsedRemote = Parse-RemoteUrl $RemoteUrl
  if ($null -eq $parsedRemote) {
    Fail 'unsupported remote URL; use --web-url for local or unusual remotes'
  }

  $RemoteHost = $parsedRemote.Host
  $derivedOrigin = $parsedRemote.Origin
  $resolver = Find-Resolver $RemoteHost $CustomResolvers
  if ($null -eq $resolver) {
    if ($parsedRemote.Transport -eq 'ssh' -and -not $NoSshAlias) {
      $resolvedHost = Resolve-SshHostname $RemoteHost
      if ($resolvedHost) {
        Write-DebugMessage "ssh-host=$RemoteHost -> $resolvedHost"
        $RemoteHost = $resolvedHost
        $derivedOrigin = "https://$RemoteHost"
      }
    }
    $resolver = Find-Resolver $RemoteHost $CustomResolvers
    if ($null -eq $resolver) { $resolver = Find-Resolver $RemoteHost $BuiltinResolvers }
  }

  if ($null -ne $resolver) {
    $MatchedForge = ([string]$resolver.Forge).ToLowerInvariant()
    $MatchedOrigin = [string]$resolver.WebOrigin
  }
  if ($MatchedOrigin) { $derivedOrigin = $MatchedOrigin.TrimEnd('/') }
  $RepositoryWebUrl = "$($derivedOrigin.TrimEnd('/'))/$($parsedRemote.Path)"
}

if ($ForgeOverride) {
  $Forge = $ForgeOverride.ToLowerInvariant()
} else {
  $Forge = $MatchedForge
  if (-not $Forge -and $RemoteHost) {
    $resolver = Find-Resolver $RemoteHost $CustomResolvers
    if ($null -eq $resolver) { $resolver = Find-Resolver $RemoteHost $BuiltinResolvers }
    if ($null -ne $resolver) { $Forge = ([string]$resolver.Forge).ToLowerInvariant() }
  }
}

$RepositoryWebUrl = ($RepositoryWebUrl -replace '\.git$', '').TrimEnd('/')
Write-DebugMessage "forge=$(if ($Forge) { $Forge } else { 'unknown' })"
Write-DebugMessage "repository=$RepositoryWebUrl"

function Encode-UrlComponent {
  param([AllowEmptyString()][string]$Value)
  return [Uri]::EscapeDataString($Value)
}

function Encode-UrlPath {
  param([AllowEmptyString()][string]$Value)
  $normalized = $Value.Replace('\', '/')
  return (($normalized -split '/') | ForEach-Object { Encode-UrlComponent $_ }) -join '/'
}

function Get-CommitForRef {
  param([string]$Ref)
  if ($HaveRepository) {
    $commit = Invoke-GitText @('rev-parse', '--verify', "${Ref}^{commit}")
    if ($commit) { return $commit }
  }
  return $Ref
}

function Get-RefCategory {
  param([string]$Ref)
  if ($Ref -like 'refs/heads/*') { return 'branch' }
  if ($Ref -like 'refs/tags/*') { return 'tag' }
  if ($Ref -like 'refs/remotes/*') { return 'branch' }

  if ($HaveRepository) {
    if ($Ref -eq 'HEAD' -and (Get-CurrentBranch)) { return 'branch' }
    if (Test-GitCommand @('show-ref', '--verify', '--quiet', "refs/heads/$Ref")) { return 'branch' }
    if (Test-GitCommand @('show-ref', '--verify', '--quiet', "refs/tags/$Ref")) { return 'tag' }
  }
  return 'commit'
}

$FileRef = if ($AtRef) { $AtRef } else { 'HEAD' }
$FileRefKind = ''
if ($TargetKind -eq 'file') {
  $FileRefKind = Get-RefCategory $FileRef
  if ($FileRef -like 'refs/heads/*') {
    $FileRef = $FileRef -replace '^refs/heads/', ''
  } elseif ($FileRef -like 'refs/tags/*') {
    $FileRef = $FileRef -replace '^refs/tags/', ''
  } elseif ($FileRef -like 'refs/remotes/*') {
    $trackingRemote = Get-RemoteFromTrackingRef $FileRef
    $FileRef = $FileRef -replace '^refs/remotes/', ''
    if ($trackingRemote -and $FileRef.StartsWith("$trackingRemote/", [System.StringComparison]::Ordinal)) {
      $FileRef = $FileRef.Substring($trackingRemote.Length + 1)
    }
  } elseif ($FileRef -eq 'HEAD' -and $FileRefKind -eq 'branch') {
    $FileRef = Get-CurrentBranch
  }

  if ($FileRefKind -eq 'commit') { $FileRef = Get-CommitForRef $FileRef }
}

if ($TargetKind -in @('commit', 'ref', 'stash')) {
  $TargetValue = Get-CommitForRef $TargetValue
}

$EncodedTarget  = if ($TargetKind -in @('commit', 'ref', 'stash')) {
  Encode-UrlComponent $TargetValue
} else {
  Encode-UrlPath $TargetValue
}
$EncodedFileRef = Encode-UrlPath $FileRef
$EncodedFile    = Encode-UrlPath $TargetValue

function Build-WebUrl {
  if ($TargetKind -eq 'repository') { return $RepositoryWebUrl }
  if (-not $Forge) {
    Write-DebugMessage 'unknown forge; falling back to the repository root'
    return $RepositoryWebUrl
  }

  switch ($Forge) {
    'github' {
      if ($TargetKind -in @('branch', 'remote-branch', 'tag')) {
        return "$RepositoryWebUrl/tree/$EncodedTarget"
      }
      if ($TargetKind -in @('commit', 'ref', 'stash')) {
        return "$RepositoryWebUrl/commit/$EncodedTarget"
      }
      if ($TargetKind -eq 'file') {
        return "$RepositoryWebUrl/blob/$EncodedFileRef/$EncodedFile"
      }
    }
    'gitlab' {
      if ($TargetKind -in @('branch', 'remote-branch', 'tag')) {
        return "$RepositoryWebUrl/-/tree/$EncodedTarget"
      }
      if ($TargetKind -in @('commit', 'ref', 'stash')) {
        return "$RepositoryWebUrl/-/commit/$EncodedTarget"
      }
      if ($TargetKind -eq 'file') {
        return "$RepositoryWebUrl/-/blob/$EncodedFileRef/$EncodedFile"
      }
    }
    { $_ -in @('forgejo', 'gitea') } {
      if ($TargetKind -in @('branch', 'remote-branch')) {
        return "$RepositoryWebUrl/src/branch/$EncodedTarget"
      }
      if ($TargetKind -eq 'tag') {
        return "$RepositoryWebUrl/src/tag/$EncodedTarget"
      }
      if ($TargetKind -in @('commit', 'ref', 'stash')) {
        return "$RepositoryWebUrl/commit/$EncodedTarget"
      }
      if ($TargetKind -eq 'file') {
        switch ($FileRefKind) {
          'branch' { return "$RepositoryWebUrl/src/branch/$EncodedFileRef/$EncodedFile" }
          'tag'    { return "$RepositoryWebUrl/src/tag/$EncodedFileRef/$EncodedFile" }
          default  { return "$RepositoryWebUrl/src/commit/$EncodedFileRef/$EncodedFile" }
        }
      }
    }
    'bitbucket-cloud' {
      if ($TargetKind -in @('branch', 'remote-branch', 'tag')) {
        return "$RepositoryWebUrl/src/$EncodedTarget"
      }
      if ($TargetKind -in @('commit', 'ref', 'stash')) {
        return "$RepositoryWebUrl/commits/$EncodedTarget"
      }
      if ($TargetKind -eq 'file') {
        return "$RepositoryWebUrl/src/$EncodedFileRef/$EncodedFile"
      }
    }
  }
  Fail "forge '$Forge' does not support kind '$TargetKind'"
}

$Url = Build-WebUrl
Write-DebugMessage "url=$Url"

function Open-WebUrl {
  param([string]$ResolvedUrl)
  if ($Opener) {
    $global:LASTEXITCODE = 0
    & $Opener $ResolvedUrl
    if ($LASTEXITCODE -is [int] -and $LASTEXITCODE -ne 0) {
      Fail "opener failed with exit code $LASTEXITCODE"
    }
    return
  }

  if ($env:OS -eq 'Windows_NT') {
    Start-Process $ResolvedUrl
    return
  }

  $isMacOS = $false
  try {
    $isMacOS = [Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
      [Runtime.InteropServices.OSPlatform]::OSX
    )
  } catch {}

  if ($isMacOS) {
    Start-Process -FilePath 'open' -ArgumentList @($ResolvedUrl)
  } else {
    # Linux and WSL intentionally use xdg-open. The WSL configuration can
    # forward URLs to the Windows default browser.
    if (-not (Get-Command xdg-open -ErrorAction SilentlyContinue)) {
      Fail 'xdg-open is not available; set GIT_RESOLVE_REF_OPENER'
    }
    Start-Process -FilePath 'xdg-open' -ArgumentList @($ResolvedUrl)
  }
}

if ($OpenUrl) {
  Open-WebUrl $Url
} else {
  [Console]::Out.WriteLine($Url)
}
