#!/usr/bin/env pwsh

# Show diffs using the 1-based positions printed by `git log`, where HEAD is 1.
#
#   git prev                         HEAD^...HEAD (the current commit's patch)
#   git prev 3                       HEAD~2...HEAD
#   git prev 2 4                     HEAD~3...HEAD~1
#   git prev -C ./repo 3 --stat      forwards -C ./repo to git and --stat to diff
#   git prev -C ./repo - --stat      uses - to skip positions and start diff args
#
# The two-position form is normalized from the older selected commit to the
# newer one, regardless of argument order. Positions must be contiguous: after
# the first position, only an immediately following number can be the second.
# A standalone positive integer is always a git-prev position. Attach numeric
# option values to their option (for example, --abbrev=5 or -U5). Use `git diff`
# directly for refs, branches, revision expressions, or non-revision diff modes.

$gitArgs = @()
$diffArgs = @()
$position1Token = $null
$position2Token = $null
$index = 0

# Before the first position, arguments belong to git. Once a position is found,
# any remaining arguments after the optional second position belong to git diff.
# With no positions, a single `-` marks the start of the git diff arguments.
while ($index -lt $args.Length) {
  $argument = [string]$args[$index]

  if ($argument -eq '-') {
    $index++
    if ($index -lt $args.Length) {
      $diffArgs = @($args[$index..($args.Length - 1)])
    }
    break
  }

  if ($argument -match '^[0-9]+$') {
    $position1Token = $argument
    $index++

    if (($index -lt $args.Length) -and ([string]$args[$index] -match '^[0-9]+$')) {
      $position2Token = [string]$args[$index]
      $index++
    }

    if ($index -lt $args.Length) {
      $diffArgs = @($args[$index..($args.Length - 1)])
    }
    break
  }

  $gitArgs += $argument
  $index++
}

function ConvertTo-Position([string]$Token) {
  [long]$position = 0
  if ((-not [long]::TryParse($Token, [ref]$position)) -or ($position -lt 1)) {
    throw 'git-prev: positions must be positive integers'
  }
  return $position
}

try {
  if ($null -eq $position1Token) {
    $base = 'HEAD^'
    $ref = 'HEAD'
  } else {
    $position1 = ConvertTo-Position $position1Token

    if ($null -eq $position2Token) {
      $base = "HEAD~$($position1 - 1)"
      $ref = 'HEAD'
    } else {
      $position2 = ConvertTo-Position $position2Token
      $newerPosition = [Math]::Min($position1, $position2)
      $olderPosition = [Math]::Max($position1, $position2)
      $base = "HEAD~$($olderPosition - 1)"
      $ref = "HEAD~$($newerPosition - 1)"
    }
  }
} catch {
  Write-Error $_
  exit 2
}

# Let Git apply its configured pager (including delta) and preserve Git's status.
& git @gitArgs diff "$base...$ref" @diffArgs
exit $LASTEXITCODE
