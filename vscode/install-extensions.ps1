
Get-Content .\extensions.sh | ? {
  "$_" -And (-Not $_.StartsWith('#'))
} | % {
  code --install-extension "$_"
}

