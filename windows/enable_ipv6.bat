REM Reenable ipv6 in windows
REM Restart afterwards
REM Ref: https://techysnoop.com/disable-ipv6-on-windows-11/

reg delete "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" /v DisabledComponents /f

