#!/usr/bin/env pwsh

# Show diff against previous commits
# With no arguments, it will always show the previous commit contents
# > gprev
# With a single argument, it will show the changes until the number of commits back
# > gprev 5
# With two argument, it will show the changes from first to second commit
# > gprev 2 5
# You can use branch names or hashes instead of numbers but you should prefer
# using `git diff` directly in such a case

$base = ''
$ref = ''
$expr = ''

if ($args.Length -eq 0) {
  $base = 'HEAD^'
  $ref = 'HEAD'
} elseif ($args.Length -eq 1) {
  if ($args[0] -match '^[^.]+\.\.{1,2}[^.]+$') {
    $expr = "$args"
  } else {
    $base = $args[0]
    $ref = 'HEAD'
  }
} elseif ($args.Length -gt 1) {
  $ref = $args[0]
  $base = $args[1]
}


if ((-not $expr) -and (-not $base) -and (-not $ref)) {
  Write-Error "Invalid arguments: $args"
  return
}

if ($base -match '^[0-9]+$') {
  $base = "HEAD~$base"
}
if ($ref -match '^[0-9]+$') {
  $ref = "HEAD~$ref"
}

$expr = if ($expr) { $expr } else { "$base...$ref" }

if (Get-Command delta -All -ErrorAction SilentlyContinue) {
  git diff "$expr" | delta
} else {
  git diff "$expr"
}
