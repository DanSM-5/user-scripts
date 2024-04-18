@ECHO OFF
SETLOCAL ENABLEEXTENSIONS
COLOR 0A

CLS

ECHO Select an option: & ECHO=
ECHO [1] Add "Copy MinGW Path" to the context menu
ECHO [2] Remove "Copy MinGW Path" from the context menu & ECHO=

CHOICE /C 12 /N /M "Your choices are (1 or 2): " & CLS

IF "%ERRORLEVEL%" EQU "1" GOTO addReg
IF "%ERRORLEVEL%" EQU "2" GOTO removeReg

ECHO Invalid option selected. & ECHO=
PAUSE
GOTO :EOF

:addReg
REG ADD "HKCR\Directory\shell\CopyMinGWPath" /ve /d "Copy MinGW Path" /f
REG ADD "HKCR\Directory\shell\CopyMinGWPath" /v "Extended" /d "" /f
REG ADD "HKCR\Directory\shell\CopyMinGWPath" /v "Icon" /d "%PROGRAMFILES%\Git\mingw64\share\git\git-for-windows.ico" /f
REG ADD "HKCR\Directory\shell\CopyMinGWPath\command" /d "%windir%\System32\cmd.exe /d /c \"cygpath -u '%%V' ^| %windir%\System32\clip.exe\"" /f
REG ADD "HKCR\*\shell\CopyMinGWPath" /ve /d "Copy MinGW Path" /f
REG ADD "HKCR\*\shell\CopyMinGWPath" /v "Extended" /d "" /f
REG ADD "HKCR\*\shell\CopyMinGWPath" /v "Icon" /d "%PROGRAMFILES%\Git\mingw64\share\git\git-for-windows.ico" /f
REG ADD "HKCR\*\shell\CopyMinGWPath\command" /d "%windir%\System32\cmd.exe /d /c \"cygpath -u '%%1' ^| %windir%\System32\clip.exe\"" /f
GOTO :EOF

:removeReg
REG DELETE "HKCR\*\shell\CopyMinGWPath" /f
REG DELETE "HKCR\Directory\shell\CopyMinGWPath" /f

