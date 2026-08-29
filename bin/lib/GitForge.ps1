# Shared forge metadata and URL helpers for the PowerShell Git utilities.

$GitForgeBuiltinResolvers = @(
  [pscustomobject]@{ Host = 'github.com';    Forge = 'github';          WebOrigin = 'https://github.com' }
  [pscustomobject]@{ Host = 'gitlab.com';    Forge = 'gitlab';          WebOrigin = 'https://gitlab.com' }
  [pscustomobject]@{ Host = 'codeberg.org';  Forge = 'forgejo';         WebOrigin = 'https://codeberg.org' }
  [pscustomobject]@{ Host = 'gitea.com';     Forge = 'gitea';           WebOrigin = 'https://gitea.com' }
  [pscustomobject]@{ Host = 'bitbucket.org'; Forge = 'bitbucket-cloud'; WebOrigin = 'https://bitbucket.org' }
)

function Find-GitForgeResolver {
  param(
    [string]$HostName,
    [object[]]$CustomResolvers = @(),
    [bool]$IncludeBuiltins = $true
  )

  $candidate = $HostName.ToLowerInvariant()
  $resolvers = @($CustomResolvers)
  if ($IncludeBuiltins) { $resolvers += @($GitForgeBuiltinResolvers) }
  foreach ($resolver in $resolvers) {
    if ($candidate -like ([string]$resolver.Host).ToLowerInvariant()) {
      return $resolver
    }
  }
  return $null
}

function Find-GitForgeNamedResolver {
  param([string]$Value)
  $candidate = $Value.TrimEnd('/').ToLowerInvariant()
  foreach ($resolver in $GitForgeBuiltinResolvers) {
    if (
      $candidate -eq ([string]$resolver.Host).ToLowerInvariant() -or
      $candidate -eq ([string]$resolver.Forge).ToLowerInvariant() -or
      $candidate -eq ([string]$resolver.WebOrigin).TrimEnd('/').ToLowerInvariant()
    ) {
      return $resolver
    }
  }
  return $null
}

function ConvertTo-GitForgeUrlComponent {
  param([AllowEmptyString()][string]$Value)
  return [Uri]::EscapeDataString($Value)
}

function ConvertTo-GitForgeUrlPath {
  param([AllowEmptyString()][string]$Value)
  $normalized = $Value.Replace('\', '/')
  return (($normalized -split '/') | ForEach-Object {
    ConvertTo-GitForgeUrlComponent $_
  }) -join '/'
}

function ConvertFrom-GitForgeUrlPath {
  param([AllowEmptyString()][string]$Value)
  return [Uri]::UnescapeDataString($Value)
}

function Get-GitForgeRawFileUrl {
  param(
    [string]$Forge,
    [string]$Origin,
    [string]$RepositoryPath,
    [string]$Ref,
    [string]$FilePath
  )

  $originRoot = $Origin.TrimEnd('/')
  $encodedRef = ConvertTo-GitForgeUrlComponent $Ref
  switch ($Forge) {
    'github' {
      $encodedRepository = ConvertTo-GitForgeUrlPath $RepositoryPath
      $encodedRefPath = ConvertTo-GitForgeUrlPath $Ref
      $encodedFilePath = ConvertTo-GitForgeUrlPath $FilePath
      return "https://raw.githubusercontent.com/$encodedRepository/$encodedRefPath/$encodedFilePath"
    }
    'gitlab' {
      $encodedRepository = ConvertTo-GitForgeUrlComponent $RepositoryPath
      $encodedFilePath = ConvertTo-GitForgeUrlComponent $FilePath
      return "$originRoot/api/v4/projects/$encodedRepository/repository/files/$encodedFilePath/raw?ref=$encodedRef"
    }
    { $_ -in @('forgejo', 'gitea') } {
      $parts = @($RepositoryPath -split '/')
      if ($parts.Count -ne 2) { throw "Forgejo/Gitea repository path must be owner/repository: $RepositoryPath" }
      $owner = ConvertTo-GitForgeUrlComponent $parts[0]
      $repository = ConvertTo-GitForgeUrlComponent $parts[1]
      $encodedFilePath = ConvertTo-GitForgeUrlPath $FilePath
      return "$originRoot/api/v1/repos/$owner/$repository/raw/$encodedFilePath`?ref=$encodedRef"
    }
    default { throw "Unsupported forge for raw files: $Forge" }
  }
}
