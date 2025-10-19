
## Show system information

Show system information in powershell

```powershell
Get-CimInstance Win32_OperatingSystem | Select-Object  Caption, InstallDate, ServicePackMajorVersion, OSArchitecture, BootDevice,  BuildNumber, CSName | Format-List
```

## Install without online account

1. Do not conenct to the internet (unplug ethernet)
2. Use `shift-f10` during installation

3. Run one of the options

```batch
# Option 1
start ms-cxh:localonly

# Option 2
netplwiz

# Option 3
OOBE\BYPASSNRO
REM https://www.tomshardware.com/how-to/install-windows-11-without-microsoft-account
```
