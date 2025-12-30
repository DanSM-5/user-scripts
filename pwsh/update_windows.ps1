# Download youtube videos
function youtube () {
  $driveLetter = "D"
  $isInternal = $false

  # Check if the drive letter exists as a fixed volume (maybe internal disk)
  $volume = Get-Volume -DriveLetter $driveLetter -ErrorAction SilentlyContinue
  if ($volume) {
    $isInternal = ($volume.FileSystemType -eq "NTFS") -and ($volume.DriveType -eq "fixed")
  }

  $videoOutput = if ($isInternal) { "D:/youtube" } else { "$HOME/youtube" }
  New-Item -Path $videoOutput -ItemType Directory -ea 0 | Out-Null

  Push-Location $videoOutput
  $clipboard = (Get-ClipBoard).Trim()
  yt-dlp --recode mp4 --remote-components ejs:github --windows-filenames @args "$clipboard"
  Pop-Location
}

# Packages update helper
function update () {
  # scoop update "*"
  scoop update ffmpeg
  scoop update deno
  pipx upgrade yt-dlp --include-injected
  gsudo choco upgrade mpv --yes 
  curl -sSL https://raw.githubusercontent.com/DanSM-5/user-scripts/refs/heads/master/pwsh/update_windows.ps1 > $PROFILE
}

# Shell utilities
function l () { eza @args }
function la () { eza -a @args }
function ll () { eza -al @args }

# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

# Shell completion
if ((Get-Module PsReadLine).Version -ge '2.2') {
  #Set-PSReadLineOption -PredictionSource History
  Set-PSReadLineOption -Colors @{ InlinePrediction = '#B3E5FF' }
}

# Shell shortcuts
Set-PSReadLineKeyHandler -Chord "Ctrl+RightArrow" -Function ForwardWord
Set-PSReadLineKeyHandler -Chord "Ctrl+LeftArrow" -Function BackwardWord

# Often needed environment variables
$env:COLORTERM = "truecolor"
$env:TERM = if ($env:TERM) { $env:TERM } else { "xterm-256color" }
