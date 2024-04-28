@ECHO off

REM Set UTF8 encoding to handle names with weird characters
chcp 65001 > NUL 2>&1

REM Need to use -File instead of -Command or parsing of multple spaced names is unreliable
pwsh -NoLogo -NonInteractive -NoProfile -File %user_scripts_path%\bin\lf_preview.ps1 %1 || echo "Powershell parsing failure"

