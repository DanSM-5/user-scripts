$modulesList = @(
  PsFzf,
  DirColors,
  PowerShellRun
)

foreach ($module in $modulesList) {
  Install-Module -Name $module -Scope CurrentUser
}

