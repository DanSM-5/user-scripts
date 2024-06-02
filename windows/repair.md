Repair windows
=========

Attempt to repair the windows image. Run the commands like administrator.

# Commands

Download latest updated files:

```powershell
dism /online /cleanup-image /restorehealth
```

Scan and repair:

```powershell
sfc /scannow
```
