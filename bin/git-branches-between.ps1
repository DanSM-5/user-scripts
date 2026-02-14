#!/usr/bin/env pwsh

<#
.SYNOPSIS
  Git search branches between commits

.DESCRIPTION
  List all branches (in alphabetical order) that exists between
  two refs.
  With no arguments it compares between master..HEAD
  With a single argument it compares between master..<newest-ref>

.PARAMETER FirstRef
  Value of the oldest reference (default: HEAD)

.PARAMETER SecondRef
  Value of the newest reference (default: master)

.PARAMETER Help
  Show help message

.INPUTS
  No input from pipeline

.OUTPUTS
  List of branch names

.EXAMPLE
  git-branches-between -h

.EXAMPLE
  git-branches-between -Help

.EXAMPLE
  git-branches-between

.EXAMPLE
  git-branches-between HEAD

.EXAMPLE
  git-branches-between HEAD master

.NOTES
  List of branch names are sorted alphabetical and not  chronologicaly
#>

[CmdletBinding()]
Param(
  # Value of FirstRef
  [string[]] $FirstRef = $null,
  # Value of SecondRef
  [string[]] $SecondRef = $null,
  # Show help
  [Switch] $Help = $false
)

$newestRef = ''
$oldestRef =  ''

if ($null -eq $FirstRef -and $null -eq $SecondRef) {
  $newestRef = 'HEAD'
  $oldestRef = 'master'
} elseif ($null -eq $SecondRef) {
  $newestRef = 'HEAD'
  $oldestRef = $FirstRef
} else {
  $newestRef = $FirstRef
  $oldestRef = $SecondRef
}

[string[]]$commits = git rev-list "${oldestRef}..${newestRef}"

if ($commits.Count -eq 0) {
  exit
}

# TODO: Check if performance can increase using a HashSet
# $SetList = [System.Collections.Generic.HashSet[string]]@()
# foreach ($commit in $commits) {
#   $parsed = ((git branch --contains "$commit") -replace '^[*+ ] ', '')
#   $null = $SetList.Add($parsed)
# }
# $SetList

$commits | ForEach-Object {
  $commit = $_
  (git branch --contains "$commit") -replace '^[*+ ] ', ''
} | Sort-Object -Unique
