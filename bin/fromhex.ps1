#!/usr/bin/env pwsh

# Script that converts hexadecimal colors to the closest
# terminal color (256 color)

[String]$rgb = "$args"

# Remove optional starting #
if ($rgb.StartsWith('#')) {
  $rgb = $rgb.Substring(1)
}

# Format color when in short form of hex
if ($rgb.Length -eq 3) {
  $red = $rgb.Substring(0, 1)
  $gree = $rgb.Substring(1, 1)
  $blue = $rgb.Substring(2, 1)
  $rgb = "$red$red$gree$gree$blue$blue"
}

# Invalid color
if ($rgb.Length -ne 6) {
  Write-Error 'Invalid hexadecimal color'
  exit
}

function Get-ColorWeight([String] $color) {
  $number = [Int32]"0x$color"
  if ($number -lt 75) {
    return 0
  } else {
    return [Math]::Truncate(($number - 35) / 40)
  }
}

$r = Get-ColorWeight ($rgb.Substring(0, 2))
$g = Get-ColorWeight ($rgb.Substring(2, 2))
$b = Get-ColorWeight ($rgb.Substring(4, 2))

[int]$transformed = ($r * 36) + ($g * 6) + $b + 16

'{0:d3}' -f $transformed

