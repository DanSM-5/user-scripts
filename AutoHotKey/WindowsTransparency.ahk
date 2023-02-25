
#SingleInstance Force
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

TLevel = 220

#^Esc:: ; Win + Ctrl + Esc
  WinGet, CurrentTLevel, Transparent, A
  If (CurrentTLevel = OFF) {
    WinSet, Transparent, %TLevel%, A
  } Else {
    WinSet, Transparent, OFF, A
  }
return

SetTransparency:
  WinGet, CurrentTLevel, Transparent, A
  WinSet, Transparent, %TLevel%, A
return

#^=:: ; Win + Ctrl + =
  TLevel += 10
  If TLevel >= 255
  {
     TLevel = 255
  }

  Gosub, SetTransparency
return

#^-:: ; Win + Ctrl + -
  TLevel -= 10
  If TLevel <= 0
  {
    TLevel = 0
  }

  Gosub, SetTransparency
return
