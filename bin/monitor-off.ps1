#!/usr/bin/env pwsh

[CmdletBinding()]
Param(
  [Switch] $Lock = $false
)

# Ref: https://superuser.com/questions/1397941/how-to-turn-off-screen-with-powershell
if ($env:IS_WINDOWS -eq 'true' -or $IsWindows) {
  # NOTE: PC is also locked
  $null = (Add-Type "[DllImport(""user32.dll"")] public static extern int PostMessage(int hWnd, int hMsg, int wParam, int lParam);" -Name "Win32PostMessage" -Namespace Win32Functions -PassThru)::PostMessage(0xffff, 0x0112, 0xF170, 2)
  # Also PSModule: https://www.powershellgallery.com/packages/DisplayConfig/1.1.1

  # Other command
  # (Add-Type -MemberDefinition "[DllImport(""user32.dll"")]`npublic static extern int SendMessage(int hWnd, int hMsg, int wParam, int lParam);" -Name "Win32SendMessage" -Namespace Win32Functions -PassThru)::SendMessage(0xffff, 0x0112, 0xF170, 2)


  if ($Lock) {
    $LockWorkStation = Add-Type -Name "Win32LockWorkStation" -PassThru -MemberDefinition @"
[DllImport("user32.dll")]
public static extern int LockWorkStation();
"@
  # Write-Information -MessageData "Locking workstation" -InformationAction Continue
  # if (0 -eq $LockWorkStation::LockWorkStation()) {
  #     throw 'Failed to lock workstation'
  # }   

    $LockWorkStation::LockWorkStation()
  }
} else {
  Write-Output 'TBI'
}

