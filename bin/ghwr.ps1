#!/usr/bin/env pwsh

<#
.SYNOPSIS
  Run a GitHub Actions workflow, then watch the resulting run.

.DESCRIPTION
  Forwards all arguments to `gh workflow run` and parses the dispatched
  run's ID out of its own output (the `.../actions/runs/<id>` URL gh
  prints), then hands off to `gh run watch`. If no run ID is found there
  -- e.g. -Help, or an older gh/GHES build that doesn't print the run URL
  -- the captured output is printed as-is, matching plain
  `gh workflow run` behavior.
#>

if ($args.Count -eq 0) {
  # No args means gh's interactive workflow/input prompt, which needs a
  # real TTY -- run it directly rather than capturing its output.
  & gh workflow run
  exit $LASTEXITCODE
}

$output_lines = & gh workflow run @args 2>&1 | ForEach-Object { $_.ToString() }
$status = $LASTEXITCODE

Write-Output $output_lines

if ($status -ne 0) {
  exit $status
}

$run_match = [Regex]::Match(($output_lines -join "`n"), 'https://\S+/actions/runs/(\d+)')
if (-not $run_match.Success) {
  exit 0
}

$run_id = $run_match.Groups[1].Value
$repo_slug = $run_match.Value -replace '^https://', '' -replace '/actions/runs/\d+$', ''

& gh run watch $run_id --repo $repo_slug
exit $LASTEXITCODE
