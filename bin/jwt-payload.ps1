#!/usr/bin/env pwsh

Param(
  [Parameter(ValueFromPipeline = $true)]
  [String] $RawJWT
)

# Get token from jwt
[string] $token = ($RawJWT -Split '\.')[1]
if (!$token) {
  exit 1
}
# Calculate padding amount
$pad = [System.Math]::Truncate(($token.Length + 3) / 4) * 4
# Make it valid for dotnet
$token = $token.Replace('-', '+').Replace('_', '/').PadRight($pad, '=')
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($token))

