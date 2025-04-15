#!/usr/bin/env pwsh

if (!(git rev-parse HEAD)) {
  exit 1
}

$branch = git branch --show-current
$origin = git remote -v | Select-Object -skip 1 | ForEach-Object { ($_ -split "`t")[0] }

git log "$origin/$branch..$branch" @args
