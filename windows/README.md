
## Show system information

Show system information in powershell

```powershell
Get-CimInstance Win32_OperatingSystem | Select-Object  Caption, InstallDate, ServicePackMajorVersion, OSArchitecture, BootDevice,  BuildNumber, CSName | Format-List
```

## Important paths

- `shell:AppsFolder`: List applications from windows store.
- `%AppData%\Microsoft\Windows\Start Menu`: Applications to be listed in start menu.
- `%AppData%\Microsoft\Windows\Start Menu\Programs\Startup`: Applications that should run on startup.

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
