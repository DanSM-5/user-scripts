Powershell
===========


## Trics

### Send binary files

```powershell
# Encode binary files
Get-Content "*path*" -Encoding byte | Out-File .\byte.txt

# Decode binary file
$Bytes1 = Get-Content .\byte.txt
[System.IO.File]::WriteAllBytes("*full path*", $Bytes1)
```

