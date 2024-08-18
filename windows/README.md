
## Show system information

Show system information in powershell

```powershell
Get-CimInstance Win32_OperatingSystem | Select-Object  Caption, InstallDate, ServicePackMajorVersion, OSArchitecture, BootDevice,  BuildNumber, CSName | Format-List
```

