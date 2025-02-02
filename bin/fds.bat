@echo off

REM @For /f "delims=" %%a in ('Type "File.txt"') do ( echo command_name argument --option %%a)
REM pause

setlocal EnableDelayedExpansion

REM Exclude arguments
set "fd_exclude="
set "fd_show="

if DEFINED "%user_scripts_path%" (set "base_path=%user_scripts_path%\fd") else (set "base_path=%USERPROFILE%\user-scripts\fd")

set "fd_exclude_file=%base_path%\fd_exclude"

for /f "tokens=*" %%a in (%fd_exclude_file%) do (
  set "fd_exclude=!fd_exclude! %%a"
)

REM echo Arguments read from fd_exclude_file: %fd_exclude%

set "fd_show_file=%base_path%\fd_show"

for /f "tokens=*" %%a in (%fd_show_file%) do (
  set "fd_show=!fd_show! %%a"
)

REM echo Arguments read from fd_show_file: %fd_show%

call fd %fd_show% %fd_exclude% %*

endlocal

