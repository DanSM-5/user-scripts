@ECHO off
setlocal

REM Store console codepage
REM Ref: https://superuser.com/a/1523968/1918286
for /f "usebackq tokens=4" %%i in (`chcp`) do (
  set _codepage=%%i
)

REM Alternative version
REM for /F "tokens=2 delims=:" %%G in ('chcp') do set "_chcp=%%G" && IF "%_chcp:~-1%"=="." set "_chcp=%_chcp:~0,-1%"

REM Set UTF8 encoding to handle names with weird characters
chcp 65001 > NUL 2>&1

REM Set exported data variables
set "PREVIEW_WIDTH=%2"
set "PREVIEW_HEIGHT=%3"
set "PREVIEW_CORDX=%4"
set "PREVIEW_CORDY=%5"
set "PREVIEW_IMAGE_SIZE=%2x%3"

REM Need to use -File instead of -Command or parsing of multple spaced names is unreliable
pwsh -NoLogo -NonInteractive -NoProfile -File %user_scripts_path%\bin\lf_preview.ps1 %1 || echo "Powershell parsing failure"

REM Restore console codepage
chcp %_codepage% > NUL 2>&1

endlocal

