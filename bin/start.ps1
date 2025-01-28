#!/usr/bin/env pwsh

Start-Process @args

# if ($PSVersionTable.PSVersion.Major -gt 5) {
#   pwsh -NoLogo -NonInteractive -NoProfile -Command Start-Process @args
# } else {
#   powershell -NoLogo -NonInteractive -NoProfile -Command Start-Process @args
# }

