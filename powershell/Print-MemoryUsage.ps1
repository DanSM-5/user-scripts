#!/usr/bin/env pwsh

Param (
  [Switch] $Total = $false,
  [ValidateSet('Name', 'Memory', 'name', 'memory')]
  [String] $SortBy = 'Name',
  [ValidateSet('TB', 'Tb', 'tb', 'GB', 'Gb', 'gb', 'MB', 'Mb', 'mb', 'KB', 'Kb', 'kb', 'B', 'b')]
  [String] $Unit = 'KB'
)

$unitValue = switch -regex ($Unit) {
  "^[Tt][Bb]$" { 1TB; break } # 😅
  "^[Gg][Bb]$" { 1GB; break }
  "^[Mm][Bb]$" { 1MB; break }
  "^[Kg][Bb]$" { 1KB; break }
  "^[Bb]$" { 1; break }
  Default { $Unit = 'KB'; 1KB; break }
}

$Unit = $Unit.ToUpper()

$activeProcesses = Get-Process | Group-Object -Property ProcessName | ForEach-Object {
  [PSCustomObject]@{
    Name = $_.Name;
    Size = ($_.Group | Measure-Object WorkingSet -Sum).Sum
  }
}

if ($Total) {
  $memorySum = ($activeProcesses | Measure-Object Size -Sum).Sum / $unitValue

  return "$('{0:N2}' -f $memorySum) $Unit"
}

if ($SortBy -Like '[Mm]emory') {
  $activeProcesses = $activeProcesses | Sort-Object -Property Size -Descending
}

$activeProcesses |
  Format-Table Name, @{
    n = "Mem ($Unit)";
    e = {
      if ($unitValue -lt 1Mb) { '{0:N0}' -f ($_.Size / $unitValue) }
      else { '{0:N3}' -f ($_.Size / $unitValue) }
    };
    a = 'right'
  }

