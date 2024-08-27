REM Disable ipv6 in windows
REM Restart afterwards
REM Ref: https://techysnoop.com/disable-ipv6-on-windows-11/

reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" /v DisabledComponents /t REG_DWORD /d 255 /f

